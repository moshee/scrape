#!/usr/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'hpricot'

module Scrape
  class ANN
    class Result < Scrape::Anime
      def populate!
        sleep 1
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

            when 7 # vintage
              @start_date = info.at('span').inner_text

            when 9 # premiere date (for movies)
              @start_date = info.at('div.tab').inner_text

            when 10 # official website
              @website = info.at('a').attributes['href']
              
            when 12 # summary
              @summary = info.at('span').inner_text

            when 19 # pic
              @img_url = info.at('a').attributes['href']

            when 25 # episode count/titles
              info.at('a').inner_text =~ /We have (\d+)$/
              if not $1.nil?
                @episodes = $1.to_i
              end
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

        self
      end

      def inspect
        "#{@title} [#{@kind}, #{@start_date + (@end_date.empty? ? '' : ' - ' + @end_date)}, #{@url[0..20]}..., #{@img_url[0..20]}..., #{@summary[0..20]}...]"
      end
    end

    class << self
      def latest_shows(options = {}) # -> ResultSet
        @limit = options[:limit] || 100
        @show = options[:show] || [:tv]

        url = "/encyclopedia/anime-list.php?showdate=1&sort=date&invertsort=1&limit_to=#{@limit}"
        map = {:tv => 'T', :movie => 'M', :oav => 'O', :ona => 'N'}
        @show.each do |s|
          url << "&show#{map[s]}=1"
        end

        doc = Hpricot(get_page(url))
        table = doc.at '#content-zone form[@name="listform"] ~ table[@border="0"]'
        if table.nil?
          puts 'table not found'
          return nil
        end

        trs = table.search 'tr'
        results = []
        trs.each do |tr|
          tds = tr.search 'td'
          name, type, season = title_type_season tds[0].inner_text
          url = tds[0].at('a').attributes['href'] rescue ''
          start_date, end_date = date tds[1].inner_text

          results << Result.new(:url => url, :title => name, :kind => type, :start_date => start_date, :end_date => end_date, :season => season)
        end

        results
      end

      def upcoming_shows
        results = []

        ['tv', 'movie', 'oav'].each do |section|
          doc = Hpricot(get_page('/encyclopedia/anime/upcoming/' + section))
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

            date = tds[2].inner_text

            results << Result.new(:url => url, :title => title, :kind => section.intern, :season => season, :img_url => img_url, :summary => summary, :start_date => date)
          end
        end

        results
      end

      def get_page(path)
        resp = Net::HTTP.new('www.animenewsnetwork.com').request_get(path, 'User-Agent' => 'lib/scrape/ann.rb')
        resp.body if resp.code == '200'
      end

      private

      def date(date)
        return [nil, nil] if date.to_s.empty?
        start_date = ''
        end_date = ''
        parts = date.split(' ')
        case parts.size
        when 1
          [date, nil]
        when 3
          if parts[2] == '...'
            [parts[0], '']
          else
            [parts[0], parts[2]]
          end
        else
          [nil, nil]
        end
      end

      def title_type_season(s)
        re = / \((\w+)( \d+)?\)$/
        s.match re
        s.gsub! re, '' if not $1.nil?
        type = case $1
               when 'TV' then :tv
               when 'movie' then :movie
               when 'OVA' then :ova
               when 'ONA' then :ona
               when 'OAV' then :oav
               else nil
               end

        # if not first season (second capture group), it will show up as (TV 2) or something
        [s, type, $2.nil? ? 0 : $2.to_i]
      end
    end
  end
end

