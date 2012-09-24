require "scrape/version"

module Scrape
  class Anime
    def initialize(o = {})
      @url                = o[:url]                || ''
      @img_url            = o[:img_url]            || ''
      @title              = o[:title]              || ''
      @kind               = o[:kind]               || nil
      @start_date         = o[:start_date]         || ''
      @end_date           = o[:end_date]           || ''
      @season             = o[:season]             || 0
      @summary            = o[:summary]            || ''
      @director           = o[:director]           || ''
      @writer             = o[:writer]             || ''
      @music              = o[:music]              || ''
      @character_designer = o[:character_designer] || ''
      @studio             = o[:studio]             || ''
      @website            = o[:website]            || ''
      @episodes           = o[:episodes]           || -1

      @alt_titles         = []
      @populated          = false
    end
    attr_reader :title, :kind, :start_date, :end_date, :url, :img_url
    attr_reader :summary, :director, :writer, :music, :character_designer
    attr_reader :studio, :alt_titles, :populated, :website, :original

    def populate!
      self
    end
  end

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
    print "\033[2K\033[0G#{str}"
  end

  module_function :bold, :log
end
