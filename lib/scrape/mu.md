# Scrape::MU
## MangaUpdates scraper

### What?

Give it a tag name and it'll spit out an `EntrySet` of `Entry`s. An `Entry` contains the simple metadata (title, url, year, rating, and a truncated list of tags) given in the search-by-category listings on MU.

### How?

Take a look at the example in the code:

```ruby
def example
  # just a random tag lol
  tag = ARGV.size > 0 ? ARGV[0] : 'Existential'

  results = EntrySet.new(tag,
                         :min_year => 2005,
                         :min_rating => 7.2,
                         :reject_tags => ['Yaoi', 'Josei', 'Shoujo', 'Doujinshi', 'Hentai', 'Shotacon', 'Shounen Ai', 'Shoujo Ai', 'Yuri'])

  results.sort_by!(&:rating).reverse!

  puts results.to_s
end
```

Outputs to the terminal:

```
Getting tag: Existential
[page 1/1, 20 results] done
filtered 20 to 17 (15% reduction)
Mushishi                      | Adventure, Drama, Fantasy, Historical, My...   | 1999 | 8.89 | http://www.mangaupdates.com/series.html?id=452
Pluto                         | Action, Drama, Mecha, Mystery, Psycholo...     | 2004 | 8.81 | http://www.mangaupdates.com/series.html?id=226
Yokohama Kaidashi Kikou       | Sci-fi, Seinen, Slice of Life                  | 1994 | 8.78 | http://www.mangaupdates.com/series.html?id=586
Solanin                       | Drama, Mature, Romance, Seinen, Slice o...     | 2005 | 8.51 | http://www.mangaupdates.com/series.html?id=2833
Taiyou no Ijiwaru             | Drama, Psychological, Seinen, Slice of Lif...  | 2002 | 8.17 | http://www.mangaupdates.com/series.html?id=4462
Hikari no Machi (ASANO Inio)  | Drama, Mature, Seinen, Slice of Life, Trag...  | 2005 | 8.09 | http://www.mangaupdates.com/series.html?id=23071
Kabu no Isaki                 | Adventure, Sci-fi, Seinen, Slice of Life       | 2007 | 8.09 | http://www.mangaupdates.com/series.html?id=12092
Ultra Heaven                  | Drama, Mystery, Psychological, Sci-fi, Sein... | 2002 | 8.04 | http://www.mangaupdates.com/series.html?id=8051
Kono Sekai no Owari e no Tabi | Adventure, Drama, Fantasy, Horror, Matu...     | 2003 | 7.88 | http://www.mangaupdates.com/series.html?id=309
Shi ni Itaru Yamai            | Drama, Psychological, Romance, Seinen,...      | 2009 | 7.88 | http://www.mangaupdates.com/series.html?id=41637
Aruku Hito                    | Seinen, Slice of Life                          | 1990 | 7.76 | http://www.mangaupdates.com/series.html?id=5470
Death Sweeper                 | Drama, Horror, Mature, Psychological, Se...    | 2007 | 7.71 | http://www.mangaupdates.com/series.html?id=16780
Filament                      | Drama, Seinen, Slice of Life, Supernatural     | 2004 | 7.65 | http://www.mangaupdates.com/series.html?id=35219
Kokoro no Kanashimi           | Mature, Psychological, Slice of Life, Trage... | 2002 | 7.61 | http://www.mangaupdates.com/series.html?id=29916
Little Forest                 | Seinen, Slice of Life                          | 2002 | 7.57 | http://www.mangaupdates.com/series.html?id=19505
Buja's Diary                  | Drama, Historical, Mature, Seinen, Slice of... | 1995 | 7.49 | http://www.mangaupdates.com/series.html?id=28173
Kinderbook                    | Drama, Mature, Psychological, Seinen, Slic...  | 2002 | 7.04 | http://www.mangaupdates.com/series.html?id=3544
```

### Why?

Got pissed off at MU's ugly layouts and the fact that about 70% of the content is yaoi or shotacon.

`Scrape::MU` was meant as a prettyprinting and filtering thing, but I realized soon it could also be used for scraping. Just hope they don't notice or something.

### Features

- Neatly formatted output for terminals
- Highlight entries with certain criteria (min and max year and rating, included tags)
- Reject entries containing tags from a specified list

### TODO

These will probably never happen.

- Boring performance enhancements
- Use the min_* and max_* things to actually reject entries instead of highlight compliant entries in the output
- Usability, consistency, and idiomatic enhancements
