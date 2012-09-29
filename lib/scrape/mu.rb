#!/usr/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'hpricot'

module Scrape
  # Deprecated class structure but still works.
  class MU
    class Entry
      attr_accessor :url, :title, :tags, :year, :rating
    end

    class EntrySet < Array
      include Scrape

      # @param tag [String] A single tag to search for
      # @option options [Float] :min_rating (0.0) In #to_s, make entries rated above this value bold
      # @option options [Float] :max_rating (10.0) In #to_s, make entries rated below this value bold
      # @option options [Integer] :min_year (0) In #to-s, make entries dated after this year bold
      # @option options [Integer] :max_year (0) In #to-s, make entries dated before this year bold
      # @option options [Array] :highlight_tags ([]) In #to_s, make any tags that appear in this list bold
      # @option options [Array] :reject_tags ([]) Reject entries whose tags include any tag from this list
      # @example
      #   results = EntrySet.new(tag,
      #   					:min_year => 2005,
      #   					:min_rating => 7.2,
      #   					:reject_tags => ['Yaoi', 'Josei', 'Shoujo', 'Doujinshi', 'Hentai', 'Shotacon', 'Shounen Ai', 'Shoujo Ai', 'Yuri'])
      #   results.sort_by!(&:rating).reverse!
      #   puts results.to_s
      def initialize(tag, options)
        @min_rating     = options[:min_rating]     || 0.0
        @max_rating     = options[:max_rating]     || 10.0
        @min_year       = options[:min_year]       || 0
        @max_year       = options[:max_year]       || 0
        @highlight_tags = options[:highlight_tags] || []
        @reject_tags    = options[:reject_tags]    || []

        super get_tag(tag)
      end

      def to_s
        title_width = map(&:title).max_by(&:size).size
        tags = map { |entry| entry.tags.join(', ') }
        tags_width = tags.max_by(&:size).size

        i = 0
        map do |entry|
          "#{entry.title.ljust(title_width)}" +
            " | #{s = (bold entry.tags, *@highlight_tags).join(', '); l = s.size - tags[i].size; i += 1; s.ljust(tags_width + l)}" +
            " | #{bold entry.year, entry.year >= @min_year, @max_year == 0 || entry.year <= @max_year}" + 
            " | #{bold '%.2f' % entry.rating, entry.rating >= @min_rating, entry.rating <= @max_rating}" +
            " | #{entry.url}"
        end.join("\n")
      end
      
      private

      def get_tag(tag)
        puts "Getting tag: #{tag}"
        tag = URI.escape(tag)
        url = "/series.html?category=#{tag}"
        page = Net::HTTP.get('www.mangaupdates.com', url)
        if page == nil or page.size == 0
          puts 'didn\'t get anything'
          return nil
        end

        doc = Hpricot(page)

        num = 1
        doc.search('td.specialtext').each do |text|
          if text.inner_text =~ /^Pages \((\d+)\)/
            num = $1.to_i
            break
          end
        end

        results = []

        # reuse the document we downloaded and parsed already for the first page,
        # acquire fresh pages for any after the first
        n = 1
        log "[page #{n}/#{num}, #{results.size} results] acquiring listing"
        results += get_tag_page(doc)

        if num > 1
          (2..num).each do |i|
            n = i
            log "[page #{n}/#{num}, #{results.size} results] sleeping for a sec"
            sleep 1
            log "[page #{n}/#{num}, #{results.size} results] acquiring listing"

            s = Net::HTTP.get('www.mangaupdates.com', "#{url}&page=#{n}")
            e = Encoding::Converter.new('iso-8859-1', 'utf-8').convert(s)

            results += get_tag_page(Hpricot(e))
          end
        end
        log "[page #{n}/#{num}, #{results.size} results] done"
        puts

        if not @reject_tags.empty?
          unfiltered_len = results.size

          results.reject! do |entry|
            entry.tags.any? do |tag|
              @reject_tags.any? { |r| tag =~ /^#{r}/ }
            end
          end

          puts "filtered #{unfiltered_len} to #{results.size} (#{(100-(results.size.to_f/unfiltered_len.to_f)*100).to_i}% reduction)"
        end
        results
      end

      def get_tag_page(doc)
        doc.search('table.text.series_rows_table > tr').select do |tr|
          tr.at('td.text.col1')
        end.map do |tr|
          m = Entry.new
          tr.search('td').map do |row|
            c = row.attributes['class']
            case
            when c =~ /1$/ # title
              a        = row.at('a')
              m.url    = a.attributes['href']
              m.title  = a.inner_text
            when c =~ /2$/ # tags
              m.tags   = row.inner_text.split(', ')
            when c =~ /3$/ # year
              m.year   = row.inner_text.to_i
            when c =~ /4$/ # rating
              m.rating = row.inner_text.to_f
            end
          end
          m
        end
      end
    end

    class << self
      private

      def bold(val, *args)
        if val.is_a?(Array)
          if args.empty?
            val
          else
            val.map do |str|
              args.any? { |a| str =~ /^#{a}/ } ? "\033[1m#{str}\033[0m" : str
            end
          end
        else
          args.all? ? "\033[1m#{val}\033[0m" : val
        end
      end

      def log(str)
        $stderr.print "\033[2K\033[0G#{str}"
      end
    end
  end # class MU
end
