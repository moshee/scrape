# encoding: utf-8

require 'net/http'
require 'hpricot'
require 'date'

module Scrape
  class ANN < Base
    @base_url = 'www.animenewsnetwork.com'
    @user_agent = 'scrape/ann'

    class Result < Anime
      # @return [self]
      # @see Scrape::Anime#populate!
      def populate!
        return self if @url.empty?
        page = ANN.get_page(@url)
        return self if page.nil?
        doc = Hpricot(page)

        infos = doc.search('#content-zone div.encyc-info-type')
        return self if infos.size == 0

        # TODO find and add all infotypes
        infos.each do |info|
          begin
            info.attributes['id'] =~ /infotype\-(\d+)$/
            next if $1.nil?
            case $1.to_i
            when 2 # alt titles
              @alt_titles = info.search('div.tab').map(&:inner_text)
            when 3 # number of episodes
              @episodes = info.at('span').inner_text
            when 4 # running time
            when 7 # vintage
              dates = info.at('span').inner_text.split(' to ')
              @start_date = Date.strptime(dates[0], '%Y-%m-%d')
              @end_date = Date.strptime(dates[1], '%Y-%m-%d')
            when 9 # premiere date (for movies)
              @start_date = Date.strptime(info.at('div.tab').inner_text, '%Y-%m-%d')
            when 10 # official website
              @website = info.at('a').attributes['href']
            when 12 # summary
              @summary = info.at('span').inner_text
            when 17 # objectionable content
            when 19 # pic
              @img_url = info.at('a').attributes['href']
            when 25 # episode count/titles
              info.at('a').inner_text =~ /We have (\d+)$/
              if not $1.nil?
                @episodes = $1.to_i
              end
            when 30 # genres
            when 31 # themes
            end
          rescue
            next
          end
        end

        # while I would like to search #content-zone table#credits, ANN's broken markup strikes again.
        # Hpricot cannot parse the HTML when there are one too many </div>s in table#credits.
        # So I have to jump up a level.
        doc.at('#content-zone').search('div.ENTAB').each do |div|
          key = div.at('b').inner_text
          val = div.search('a').map(&:inner_text).join(', ') rescue ''
          case
          when key =~ /^Director$/ then @director = val
          when key =~ /^Series Composition$/ then @writer = val
          when key =~ /^Music$/ then @music = val
          when key =~ /^Original creator$/ then @original = val
          when key =~ /Character Design$/ then @character_designer = val
          when key =~ /Animation Production$/ then @studio = val
          end
        end

        super
      end
    end

    class << self
      # @option options [Integer] :limit (100) Limit results to this many
      # @option options [Array<Symbol>] :show ([:tv]) Limit results to these types (any of `:tv`, `:movie`, `:oav`, or `:ona`)
      # @yield [self]
      # @return [Array<Anime>] the latest shows
      def latest_shows(options = {})
        @limit = options[:limit] || 100
        @show = options[:show] || [:tv]

        url = "/encyclopedia/anime-list.php?showdate=1&sort=date&invertsort=1&limit_to=#{@limit}"
        map = {:tv => 'T', :movie => 'M', :oav => 'O', :ona => 'N'}
        @show.each do |s|
          url << "&show#{map[s]}=1"
        end

        page = get_page(url)
        doc = Hpricot(page)
        table = doc.at '#content-zone form[@name="listform"] ~ table[@border="0"]'
        return nil if table.nil?

        trs = table.search 'tr'
        results = []
        trs.each do |tr|
          tds = tr.search 'td'
          name, type, season = title_type_season tds[0].inner_text
          url = tds[0].at('a').attributes['href'] rescue ''
          start_date, end_date = date tds[1].inner_text

          results << Result.new(:url => url, :title => name, :kind => type, :start_date => start_date, :end_date => end_date, :season => season)
          yield results if block_given?
        end

        results
      end

      # @yield [self]
      # @return [Array<Anime>] canned list of "upcoming" shows in the next season.
      # @example
      #   require 'erubis'
      #   
      #   s = Scrape::ANN.upcoming_shows.map(&:populate!) # this will block for around 30s to a minute
      #   erb = File.open('index.html.erb').read
      #   eruby = Erubis::Eruby.new(erb)
      #   puts eruby.result(:shows => s)
      def upcoming_shows
        results = []

        ['tv', 'movie', 'oav'].each do |section|
          page = get_page('/encyclopedia/anime/upcoming/' + section)
          doc = Hpricot(page)
          table = doc.at '#content-zone table.datalist'
          next if table.nil?


          # the html in this area is flawed; the open tbody tag is a bogus end tag. typo on their part.
          # to Chrome, the tbody exists because webkit inserts a fake tbody when it finds none.
          # to Hpricot, the <tbody> kind of just ends right here. So we have to grab all of the <tr>s inside the <table> to avoid the <th>s.
          table.search('/tr').each do |tr|
            # tr
            #   td: image
            #   td: name & desc
            #   td: premiere date
            tds = tr.search('td')

            img = tds[0].at('img')
            img_url = img.nil? ? '' : img.attributes['src'].sub('thumbnails/fit200x200', 'images')
            
            a = tds[1].at('a')
            url = a.attributes['href']
            title, type, season = title_type_season a.inner_text
            summary = tds[1].children.select(&:text?).join("\n")

            start_date, _ = date tds[2].inner_text

            results << Result.new(:url        => url,
                                  :title      => title,
                                  :kind       => section.intern,
                                  :season     => season,
                                  :img_url    => img_url,
                                  :summary    => summary,
                                  :start_date => start_date)
            yield results if block_given?
          end
        end

        results
      end

      private

      def date(str)
        return nil if str.empty? or str == '-'
        str.split(' to ').map do |part|
          part == '...' ? nil : Date.new(*part.split('-').map(&:to_i))
        end
      end

      def title_type_season(s)
        re = / \((\w+)( \d+)?\)$/
        s.match re
        s.gsub! re, '' if not $1.nil?
        type = $1 ? $1.downcase.intern : nil

        # if not first season (second capture group), it will show up as (TV 2) or something
        [s, type, $2.nil? ? 0 : $2.to_i]
      end
    end
  end
end

