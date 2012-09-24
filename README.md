# Scrape

This is a collection of various website scrapers that I write eventually when I want to automate data acquisition. It will grow very slowly, perhaps not at all. I hope none of the websites targeted will mind. If they do, I will take that particular module/package offline.

Most of the scrapers will be written in Ruby. If I find that I need performance, I will rewrite them in Go. These rewritten ones may go in a different repo. This will be unlikely as the pauses between requests usually outweigh computation time by a large factor. If I find necessary, I may one day replace hpricot with nokogiri.

I am experimenting with packaging gems as well.

There is no license. I don't care what you do with this.

## Reference

All public APIs are subject to drastic change at any time.

### Scrape::MU

MangaUpdates.

### Scrape::MU::EntrySet

#### Class Methods

`new(tag, options = {})` → `Scrape::MU::EntrySet`

Queries for all manga tagged with the specified tag, using any of the options:

```ruby
:min_rating => (0.0 .. 10.0)
# In #to_s, make entries rated above this value bold [0.0]
:max_rating => (0.0 .. 10.0)
# In #to_s, make entries rated below this value bold [10.0]
:min_year => (0 .. ∞)
# In #to_s, make entries dated after this year bold [0]
:max_year => (0 .. ∞)
# In #to_s, make entries dated before this year bold [0]
:highlight_tags => [ … ]
# In #to_s, make any tags that appear in this list bold [empty]
:reject_tags => [ … ]
# Reject entries whose tags include any tag from this list [empty]
```

#### Example

```ruby
results = EntrySet.new(tag,
					:min_year => 2005,
					:min_rating => 7.2,
					:reject_tags => ['Yaoi', 'Josei', 'Shoujo', 'Doujinshi', 'Hentai', 'Shotacon', 'Shounen Ai', 'Shoujo Ai', 'Yuri'])
results.sort_by!(&:rating).reverse!

puts results.to_s
```

### Scrape::ANN

AnimeNewsNetwork.

#### Class Methods

`latest_shows(options = {})` → `Array[Scrape::ANN::Result]`

Query the latest shows, using any of the options:

```ruby
:limit => (0 .. ∞)
# Limit results to this many [100]
:show => [ :tv | :movie | :oav | :ona ]
# Only show selected entry types (array of symbols) [[:tv]]
```

`upcoming_shows` → `Array[Scrape::ANN::Result]`

Get all shows from the canned "upcoming" list - this includes anything that will air next season.

### Scrape::ANN::Result &lt; Scrape::Anime

#### Instance Methods

`populate!` → `Scrape::ANN::Result`

Fetch more detailed data from the result's individual page.

Use caution when doing this in batch, as it hits the server with a lot of requests. I've added a 1 second delay before each operation to help ensure that this does not become a problem.

#### Example

```ruby
require 'erubis'

s = Scrape::ANN.upcoming_shows.map(&:populate!) # this will block for around 30s to a minute
erb = File.open('index.html.erb').read
eruby = Erubis::Eruby.new(erb)
puts eruby.result(:shows => s)
```
