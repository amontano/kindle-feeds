#!/usr/bin/env ruby
# kindle-feeds

# copyright 2008 Daniel Choi
# dhchoi@gmail.com
# License: MIT
# (The MIT License)
# 
# Copyright (c) 2008 Daniel Choi
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'optparse'
require 'open-uri'
require 'feed-normalizer'
require 'htmlentities'
require 'iconv'
require 'erb'
require 'hpricot'
require 'ruby-debug'

CONFIGFILE = "kindle_feeds.conf"
ERB_TEMPLATE = File.dirname(__FILE__) + "/kindle-feeds.erb.html"
DEFAULT_FEEDS = <<END
# kindle-feeds feed list
#
# Please edit this file so that it contains the section
# titles and feed URLs that you want. Follow the format of
# the example: section titles immediately followed by a list
# of URLs. The URLs should either be URLs of RSS or Atom
# feeds or URLs of web pages that contain links to a RSS or
# Atom feed. The 'http://' at the beginning of the URL is
# optional. Sections should be separated by exactly one
# blank line.

General News
nytimes.com
slate.com

Tech News
techcrunch.com
http://readwriteweb.com
slashdot.org

Apple
macworld.com
macintouch.com

Ebook 
teleread.org/blog
END

class Autodiscovery
  def initialize(page_html)
    # Downcase the html because capitalized stuff might mess up the Hpricot matching
    @doc = Hpricot(page_html)
  end

  # Returns the url of the feed, or nil if none found
  def discover
    # Look for rss link, e.g.
    # <link rel="alternate" type="application/rss+xml" title="RSS"
    #       href="http://feeds.feedburner.com/TheRssBlog">
    # Tricky: Hpricot CSS attribute selectors are written like XPath selectors
    [:atom, :rss].each do |flavor|
      if x=@doc.at("head link[@type=application/#{flavor}+xml]")
        return x[:href]
      end
    end
    if x=@doc.at("head link[@type=text/xml]")
      return x[:href]
    end
    return nil
  end
end

class Feed
  def self.create_feed(xml, feed_url)
    begin
      feed = FeedNormalizer::FeedNormalizer.parse(xml)
      return nil unless feed.is_a?(FeedNormalizer::Feed)
    rescue
      puts "Error trying to parse feed: #{feed_url}"
      puts $!
      puts
      return nil
    end
    # clean up entries:
    ic = Iconv.new('ISO-8859-1//TRANSLIT', 'utf-8') 
    ic2 = Iconv.new('ISO-8859-1//IGNORE', 'utf-8') 
    #ic = Iconv.new('ASCII//TRANSLIT', 'utf-8') 
    coder = HTMLEntities.new
    puts "#{feed.entries.size} entries downloaded."
    puts
    feed.entries.each do |e|
      e.title = coder.decode(e.title)
      e.content = coder.decode(e.content)
      e.description = coder.decode(e.description)

      begin
        e.title = ic.iconv(e.title) 
      rescue
        e.title = ic2.iconv(e.title) 
      end
      begin
        e.content = ic.iconv(e.content) 
      rescue
        e.content = ic2.iconv(e.content) 
      end
      begin
        e.description = ic.iconv(e.description) 
      rescue
        e.description = ic2.iconv(e.description) 
      end
      doc = Hpricot(e.content)
      doc.search('h1, h2, h3') do |h|
        h.swap("<h4>#{h.inner_text}</h4>")
      end
      doc.search('//font') do |font|
        font.swap(font.inner_text)
      end
      doc.search('//img').remove
      doc.search('svg, object, embed').remove
      doc.search('script').remove
      e.content = doc.to_s

      doc = Hpricot(e.description)
      doc.search('h1, h2, h3') do |h|
        h.swap("<h4>#{h.inner_text}</h4>")
      end
      doc.search('//font') do |font|
        font.swap(font.inner_text)
      end
      doc.search('//img').remove
      doc.search('svg, object, embed').remove
      doc.search('script').remove
      e.description = doc.to_s
    end
    return feed
  end

  def self.subscribe(feed_url) # try to repair the URL if possible
    unless feed_url =~ /^http:\/\//
      feed_url = "http://" + feed_url
    end
    puts "Downloading #{feed_url}"
    begin
      xml = fetch(feed_url)
    rescue SocketError
      puts "Error trying to load page at #{feed_url}"
      return
    end
    if xml.nil?
      puts "Can't find any resource at #{feed_url}"
      return
    end
    feed = Feed.create_feed( xml, feed_url.strip )
    if feed.nil?
      puts "#{feed_url}: Attempting autodiscovery..."
      feed_url = auto_discover_and_subscribe(feed_url)
      if feed_url
        xml = fetch(feed_url)
        feed = Feed.create_feed( xml, feed_url.strip )
      end
    end
    feed
  end

  def self.auto_discover_and_subscribe(url)
    uri = URI.parse(url)
    feed_url = Autodiscovery.new(fetch(url)).discover
    if feed_url
      feed_url = uri.merge(feed_url).to_s
      puts "Found feed: #{feed_url}" 
      return feed_url
    else
      puts "Can't find feed for #{url}" 
      return nil
    end
  end

  # a simple wrapper over open-uri call. Easier to mock in testing.
  def self.fetch(url)
    begin
      open(url).read
    rescue Timeout::Error 
      puts "-> attempt to fetch #{url} timed out"
    rescue Exception => e
      puts "-> error trying to fetch #{url}: #{$!}"
    end
  end
end

class Section
  attr_accessor :title, :uris, :feeds
  def initialize(title, uris)
    @feeds = []
    @title = title
    @uris = uris
    # generate the feeds
    @uris.each do |uri|
      if (feed=Feed.subscribe(uri))
        @feeds << feed
      end
    end
  end
end

class KindleFeeds
  VERSION = "1.0.6"
  attr_accessor :sections
  # config is a text file with a certain format
  def initialize(config)
    @sections = [] 
    raw_sections = config.split(/^\s*$/)
    results = []
    raw_sections.each do |section|
      lines = section.strip.split("\n")
      title = lines.shift.strip 
      urls = lines.map {|line| line.strip}
      results << [title, *urls]
    end
    # an array of arrays. each array is composed of a section title followed by urls of the feeds
    results
    puts "Fetching feeds:"
    results.each do |r|
      puts "- " + r.first
      r[1..-1].each do |x|
        puts "  - " + x
      end
    end
    puts
    # subscribe
    results.each do |r|
      @sections << Section.new(r.shift, r)
    end
  end

  def to_html
    puts "Converting feeds into Kindle-compatible and optimized HTML..."
    puts 
    erb = ERB.new(File.read(ERB_TEMPLATE))
    out = erb.result(binding())
    # TODO put timestamp in filename
    date = Time.now.strftime('%m-%d-%Y')
    outfile = "Kindle Feeds #{date}.html"
    File.open(outfile, "w") do |f|
      f.write out
    end
    puts "Output written to file:"
    puts outfile
    puts
    puts "Email this file as an attachment to YOUR_KINDLE_USERNAME@kindle.com or YOUR_KINDLE_USERNAME@free.kindle.com."
    puts
    puts "Visit http://www.amazon.com/gp/help/customer/display.html?nodeId=200140600 for more help."
    puts "Done."
  end

  def self.run(argv=ARGV)
    opts = OptionParser.new do |opt|
      opt.program_name = File.basename $0
      opt.version = KindleFeeds::VERSION
      opt.banner = <<-EOT
Usage: #{opt.program_name} 

kindle-feeds reads a feed list from #{CONFIGFILE}.conf, downloads the feeds, and
generates a Kindle-compatiable and optimized HTML file that can be sent to 
YOUR_KINDLE_USERNAME@kindle.com or YOUR_KINDLE_USERNAME@free.kindle.com for conversion 
into an .azw file for reading on the Kindle. 

The first time kindle-feeds is run, it will generate a stub #{CONFIGFILE}.conf file
in the same directory. Please edit this file to specify the feeds you want to
download and convert for Kindle reading. Further instructions can be found at the
top of kindle-feeds.conf once it is generated.

Project homepage: 
http://danielchoi.com/software/kindle-feeds.html
      EOT
    end
    opts.parse! argv

    if ! File.exist?(CONFIGFILE)
      puts "Can't find #{CONFIGFILE}. Generating..."
      File.open(CONFIGFILE, "w") do |f|
        f.write DEFAULT_FEEDS
      end
      puts "Please edit #{CONFIGFILE} before running kindle-feeds again."
      exit
    end
    puts "Reading #{CONFIGFILE} for feed URLs."
    puts 
    configfile = File.open(CONFIGFILE).readlines
    configfile = configfile.select {|line| line !~ /^#/}.join.strip
    kf = KindleFeeds.new(configfile)
    kf.to_html
  end
end

if __FILE__ == $0
  KindleFeeds.run ARGV
end
