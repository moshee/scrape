#/usr/bin/env ruby
# encoding: utf-8

require 'net/http'
require 'hpricot'

module Scrape
  class MAL
    class Result < Scrape::Anime
      def populate
        self
      end
    end

    class << self
      def latest_shows
        url = 'http://myanimelist.net/anime.php?q=&type=0&score=0&status=3&tag=&p=0&r=0&sm=0&sd=0&sy=0&em=0&ed=0&ey=0&c[0]=a&c[1]=b&c[2]=d&c[3]=e&gx=0&show=0'
        #
      end
    end
  end
end
