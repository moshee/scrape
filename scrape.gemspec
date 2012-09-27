# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'scrape/version'

Gem::Specification.new do |gem|
  gem.name          = "scrape"
  gem.version       = Scrape::VERSION
  gem.authors       = ["moshee"]
  gem.email         = ["teh.moshee@gmail.com"]
  gem.description   = 'A set of scrapers for various websites.'
  gem.summary       = 'A set of scrapers for various websites.'
  gem.homepage      = 'http://github.com/moshee/scrape'

  gem.files         = %w(.gitignore README.md lib/scrape.rb lib/scrape/ann.rb lib/scrape/mal.rb lib/scrape/mu.rb lib/scrape/version.rb lib/scrape/base.rb)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'hpricot'
end
