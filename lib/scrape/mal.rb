# encoding: utf-8

require 'net/http'
require 'hpricot'
require 'date'

module Scrape
  class MAL < Base
    @base_url = 'myanimelist.net'
    @user_agent = 'scrape/mal'

    class Result < Anime
      # @return [self]
      # @see Scrape::Anime#populate!
      def populate!
        return self if @url.empty?
        page = Net::HTTP.get(URI(@url))
        return self if page.empty?
        doc = Hpricot(page)

        # sidebar information
        table = doc.at('#content table')
        sidebar = table.at('td.borderClass').search('h2[. = "Information"] ~ div') rescue nil
        if sidebar
          sidebar.each do |div|
            key = div.at('span.dark_text').inner_text.sub(/:$/, '')
            val = div.children.select { |elem| elem.text? or elem.pathname == 'a' }.map(&:inner_text).join('').strip
            case key
            when 'Type'
              @kind = val.downcase.intern
            when 'Episodes'
              @episodes = val.to_i
            when 'Aired'
              start_date, _, end_date = val.partition(' to ')
              @start_date = date start_date
              @end_date = date end_date if @end_date.nil?
            when 'Producers'
              @studio = val.split(', ') unless val =~ /Not found/
            end
          end
        end # if sidebar

        # staff
        # <a name=staff> is supposed to be (and is interpreted by webkit as)
        # inside div#content, but for some reason (did not try to wade
        # through the markup) hpricot cannot find it there. Probably extra
        # </table> and </div> tags.
        table = doc.at('a[@name="staff"] ~ table')
        table.search('tr').each do |tr|
          td = tr.search('td')[1] rescue next
          roles = td.at('small').inner_text.split(', ')
          # TODO canonicalize name order if needed
          name = td.at('a').inner_text.delete(',')

          # TODO find and implement all variations of roles listed on MAL
          role :@director, name, roles, 'Director'
          role :@original, name, roles, 'Creator', 'Original Creator'
          role :@character_designer, name, roles, 'Character Design'
          role :@writer, name, roles, 'Script'
          role :@music, name, roles, 'Theme Song Performance'
        end

        # summary
        @summary = doc.at('#content #horiznav_nav ~ div td').children.select(&:text?).map { |s| s.inner_text.strip }.reject(&:empty?).join("\n") rescue ''

        super
      end # def populate!

      private

      def date(str)
        return nil if str.empty? or str == '?'

        date = nil
        ['%b %d, %Y', '%b %Y', '%Y'].each do |fmt|
          begin
            date = Date.strptime(str, fmt)
            break
          rescue ArgumentError
            next
          end
        end

        date
      end

      def role(sym, name, roles, *strs)
        val = instance_variable_get sym
        if (roles & strs).size > 0
          # if it's an empty string (or array) or nil, just set it.
          # if there's already a name there and it's a string, convert it to an
          # array and append to it.
          # if it's an array, just append to it.
          if val.nil? or val.empty?
            val = name
          elsif val.class == String
            val = [val, name]
          elsif val.class == Array
            val << name
          end
        end
        instance_variable_set(sym, val)
      end
    end # class Result

    class << self
      # @return [Array<Anime>] all shows in the database that have not yet aired
      def latest_shows
        n = 0
        base_path = '/anime.php?q=&type=0&score=0&status=3&tag=&p=0&r=0&sm=0&sd=0&sy=0&em=0&ed=0&ey=0&c[0]=a&c[1]=b&c[2]=d&c[3]=e&gx=0'
        results = []

        loop do
          path = base_path + "&show=#{n}"
          page = get_page(path)
          next if page.empty?

          doc = Hpricot(page)
          table = doc.at('#content form[@method="GET"] ~ table')
          next if table.nil?

          # TODO I just discovered that there is a (hidden by default, shown
          # via css if hovered) popup div on every table entry's pic. Maybe
          # latency will be a bit lower if I omit all of those "show x column"
          # params in the url and pull it straight from that. All data fields
          # show up in this hidden div; the summary is truncated, with a link.
          # The layout is different.
          table.search('tr').each do |tr|
            tds = tr.search('td.borderClass')
            next if tds.size != 6

            img_url = tds[0].at('img').attributes['src'].sub(/t\.jpg$/, 'l.jpg')

            a = tds[1].at('a')
            title = a.inner_text
            url = a.attributes['href']

            kind = tds[2].inner_text.downcase.intern
            episodes = tds[3].inner_text.to_i
            start_date = date tds[4].inner_text
            end_date = date tds[5].inner_text

            results << Result.new(:img_url => img_url, :title => title, :url => url, :kind =>  kind, :episodes => episodes, :start_date => start_date, :end_date => end_date)
          end

          # if last element in div is not a link, we have reached the end. break.
          links = doc.at('#content form[@method="GET"] ~ div.borderClass').search('a')
          break if links.size == 0 or not links[-1].inner_text =~ /Next/

          n += 20
        end

        results
      end

      private

      def date(str)
        # it helps that it's always the same format, just replaced with ?
        Date.strptime(str.gsub('?', '01'), '%m-%d-%y') unless str == '-'
      end
    end
  end
end
