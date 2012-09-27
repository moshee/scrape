# encoding: utf-8

require 'net/http'

module Scrape
  # warning: 0 indexed
  SEASONS = [
    :winter, # jan
    :winter, # feb
    :spring, # mar
    :spring, # apr
    :spring, # may
    :summer, # jun
    :summer, # jul
    :summer, # aug
    :autumn,   # sep
    :autumn,   # oct
    :autumn,   # nov
    :winter, # dec
  ]

  class Base
    @user_agent = 'scrape/none'
    @base_url = ''

    class << self
      attr_accessor :user_agent, :base_url

      def get_page(url)
        return '' if @base_url.empty?
        resp = Net::HTTP.new(@base_url).request_get(url, 'User-Agent' => @user_agent)
        resp.code == '200' ? resp.body : ''
      end
    end
  end

  class Anime
    def initialize(o = {})
      @url                = o[:url]                || ''
      @img_url            = o[:img_url]            || ''
      @title              = o[:title]              || ''
      @kind               = o[:kind]               || nil
      @start_date         = o[:start_date]         || nil
      @end_date           = o[:end_date]           || nil
      @season             = o[:season]             || 0
      @summary            = o[:summary]            || ''
      @director           = o[:director]           || ''
      @writer             = o[:writer]             || ''
      @music              = o[:music]              || ''
      @character_designer = o[:character_designer] || ''
      @original           = o[:original]           || ''
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
      sleep 1
      @populated = true
      self
    end

    def season
      SEASONS[@start_date.month-1] rescue nil
    end

    def summer?; season == :summer end
    def autumn?; season == :autumn end
    def winter?; season == :winter end
    def spring?; season == :spring end

    # merge fields
    # TODO merging rules, for now just taking missing info from other into self
    def <<(other)
      if other.is_a? Anime
        instance_variables.each do |sym|
          var = instance_variable_get(sym)
          instance_variable_set(sym, other.instance_variable_get(sym)) if
          case var.class
          when NilClass then true
          when String then var.empty?
          when Integer then var.zero?
          end
        end
      end

      self
    end

    def inspect
      "#<#{self.class.name}:\"#{@title}\" [#{@kind}]>"
    end

    def dump
      instance_variables.map do |var|
        "#{var.to_s.sub(/^@/, '')}: #{instance_variable_get var}"
      end
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
    $stderr.print "\033[2K\033[0G#{str}"
  end

  module_function :bold, :log
end
