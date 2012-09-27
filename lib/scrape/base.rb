# encoding: utf-8

require 'net/http'

module Scrape
  # :nodoc:
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
    # @!attribute [r] url
    #   @return [String] URL from which information was fetched. May not be complete.
    # @!attribute [r] img_url
    #   @return [String] URL of associated cover art
    # @!attribute [r] title
    #   @return [String] the title
    # @!attribute [r] kind
    #   @return [Symbol] the type of series. Can be one of `:tv`, `:ova`, `:movie`, `:special`, `:ona`, `:oav`, and maybe others.
    # @!attribute [r] start_date
    #   @return [Date] the date on which the first episode was/will be aired
    # @!attribute [r] end_date
    #   @return [Date] the date on which the last episode was/will be aired. `nil` for movies and other such one-shots.
    # @!attribute [r] season
    #   @return [Integer] the season number
    # @!attribute [r] summary
    #   @return [String] the plot synopsis
    # @!attribute [r] director
    #   @return [String] the director
    #   @return [Array<String>] the directors
    # @!attribute [r] writer
    #   @return [String] the script writer
    #   @return [Array<String>] the script writers
    # @!attribute [r] music
    #   @return [String] the music performer/composer
    #   @return [Array<String>] the music performers/composers
    # @!attribute [r] character_designer
    #   @return [String] the character designer
    #   @return [Array<String>] the character designers
    # @!attribute [r] original
    #   @return [String] the original creator
    #   @return [Array<String>] the original creators
    # @!attribute [r] studio
    #   @return [String] the animation studio involved in production
    #   @return [Array<String>] the animation studios involved in production
    # @!attribute [r] website
    #   @return [String] the official website
    # @!attribute [r] episodes
    #   @return [Integer] the number of episodes
    # @!attribute [r] alt_titles
    #   @return [Array<String>] alternative titles
    # @!attribute [r] populated
    #   @return [Boolean] true if #populate! has been called
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

    # @abstract Populates data fields. Modifies `self`. It is up to the
    #   subclass to implement its own fetch and parse routines and call
    #   `super`.
    #   For rate control, `populate!` sleeps for one second. If one wanted to
    #   override this while retaining otherwise predictable behavior, simply
    #   set `@populated` to `true` on successful operation and return `self`.
    #
    # @return [self]
    def populate!
      sleep 1
      @populated = true
      self
    end

    # @return [Symbol] the starting season: one of `:summer`, `:autumn`, `:winter`, `:spring`
    # @return [nil] if the season is not specified
    def season
      SEASONS[@start_date.month-1] rescue nil
    end

    # @return [Boolean] true if the starting season is summer.
    def summer?; season == :summer end
    # @return [Boolean] true if the starting season is autumn.
    def autumn?; season == :autumn end
    # @return [Boolean] true if the starting season is winter.
    def winter?; season == :winter end
    # @return [Boolean] true if the starting season is spring.
    def spring?; season == :spring end

    # Merge fields from other into self.
    # @param other [Anime] other dataset.
    # @return [self]
    # @todo merging rules, for now just taking missing info from other into self
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

    # @return [String]
    def inspect
      "#<#{self.class.name}:\"#{@title}\" [#{@kind}]>"
    end

    # @return [Array<String>] string representations of each key and value.
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
