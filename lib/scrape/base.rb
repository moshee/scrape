# encoding: utf-8

require 'net/http'
require 'json'
require 'jaro'

module Scrape
  # :nodoc:
  SEASONS = [
    nil,
    :winter, # jan
    :winter, # feb
    :spring, # mar
    :spring, # apr
    :spring, # may
    :summer, # jun
    :summer, # jul
    :summer, # aug
    :autumn, # sep
    :autumn, # oct
    :autumn, # nov
    :winter, # dec
  ]

  class Base
    @user_agent = 'scrape/none'
    @base_url = ''

    class << self
      attr_accessor :user_agent, :base_url

      def get_page(url)
        return '' if @base_url.empty?
        resp = Net::HTTP.new(URI.encode(@base_url)).request_get(url, 'User-Agent' => @user_agent)
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
    #
    # @param o [Hash] options
    def initialize(o)
      @url                = o[:url]                || ''
      @img_url            = o[:img_url]            || ''
      @title              = o[:title]              || ''
      @kind               = o[:kind].intern        || nil rescue nil
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

      start_date = o[:start_date]
      @start_date = case
      when start_date.is_a?(String)
        Date.strptime(start_date, '%Y-%m-%d')
      when start_date.is_a?(Date), start_date.nil?
        start_date
      end

      end_date = o[:end_date]
      @end_date = case
      when end_date.is_a?(String)
        Date.strptime(end_date, '%Y-%m-%d')
      when end_date.is_a?(Date), end_date.nil?
        end_date
      end
    end
    attr_reader :title, :kind, :start_date, :end_date, :url, :img_url
    attr_reader :summary, :director, :writer, :music, :character_designer
    attr_reader :studio, :alt_titles, :populated, :website, :original

    # @abstract Populates data fields. Modifies `self`. It is up to the
    #   subclass to implement its own fetch and parse routines and call
    #   `super`.
    #   For rate control, `populate!` sleeps for one second.
    # @yield [self]
    # @return [self]
    def populate!
      yield self if block_given?
      sleep 1
      @populated = true
      self
    end

    # @return [Symbol] the starting season: one of `:summer`, `:autumn`, `:winter`, `:spring`
    # @return [nil] if the season is not specified
    def season
      SEASONS[@start_date.month] rescue nil
    end

    # @return [Boolean] true if the starting season is summer.
    def summer?; season == :summer end
    # @return [Boolean] true if the starting season is autumn.
    def autumn?; season == :autumn end
    # @return [Boolean] true if the starting season is winter.
    def winter?; season == :winter end
    # @return [Boolean] true if the starting season is spring.
    def spring?; season == :spring end

    def id
      @id || @id = @title.gsub(/[^a-zA-Z0-9\-]/, '').slice(0, 12).downcase + (@start_date.nil? ? '' : @start_date.strftime('-%d%m'))
    end

    # Merge fields from other into self.
    # @param other [Anime] other dataset.
    # @yieldparam var [Object] self's instance variable
    # @yieldparam other_var [Object] other's instance variable
    # @yieldparam sym [Symbol] name of instance variable
    # @yieldreturn [Boolean] whether or not to merge the field. default true.
    # @return [self]
    def merge(other)
      if other.is_a? Anime
        instance_variables.each do |sym|
          var = instance_variable_get(sym)
          other_var = other.instance_variable_get(sym)
          # skip this iteration (don't merge) if block returns false
          next if block_given? and not yield var, other_var, sym

          # only merge if self's value is empty and the value offered is not empty
          if is_empty?(var) and not is_empty?(other_var)
            instance_variable_set(sym, other_var)
          end
        end
      end

      self
    end

    # @return [String] JSON serialization
    def to_json
      Hash[instance_variables.map do |sym|
        [sym.to_s.sub(/^@/, ''), instance_variable_get(sym)]
      end].to_json
    end

    # @return [String]
    def inspect
      "#<#{self.class.name}:\"#{@title}\" [#{@kind}]>"
    end

    # @return [self]
    def dump
      instance_variables.each do |var|
        puts "#{var.to_s.sub(/^@/, '')}: #{instance_variable_get(var).inspect}"
      end
      self
    end

    class << self
      # Merge two arrays. Compares the titles of each element using direct
      # string comparison, and if that fails, Jaro-Winkler string distance.
      # @param arr1 [Array<Anime>]
      # @param arr2 [Array<Anime>]
      # @param filter [Proc (lambda)] merge will happen if this returns true.
      # @return [Array<Anime>] merged array
      def merge(arr1, arr2, filter = lambda { |a, b| a.title ^ b.title > 0.78 }, &block)
        arr1.sort_by(&:title).each do |a|
          arr2.sort_by(&:title).each do |b|
            if filter.call(a, b)
              a.merge(b, &block)
              arr2.delete b
              break
            else
              arr1 << b
            end
          end
        end
        arr1 + arr2
      end

      # Parse JSON data into a Ruby data structure. JSON must have the format '{"shows": [ { … }, … ]}'
      # @param str [String] JSON data
      # @return [Array<Anime>]
      def json(str)
        list = JSON.parse(str, :symbolize_names => true)[:shows]
        return nil if list.nil?
        list.map do |opts|
          Anime.new(opts)
        end
      end

      private

      def log(str)
        $stderr.print "\033[2K\033[0G#{str}"
      end
    end

    private

    def is_empty?(val)
      case
      when val.is_a?(String), val.is_a?(Array)
        val.empty?
      when val.is_a?(Numeric)
        val <= 0
      when val.nil?, val == false
        true
      else
        false
      end
    end
  end # class Anime
end
