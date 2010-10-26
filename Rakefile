# -*- ruby -*-

require 'rubygems'
require 'hoe'
$: << 'lib/'
require './lib/kindle-feeds.rb'
require './lib/htmlentities.rb'

Hoe.new('kindle-feeds', KindleFeeds::VERSION) do |p|
  # p.rubyforge_name = 'kindle-feedsx' # if different than lowercase project name
  p.author = 'Daniel Choi'
  p.email = 'dhchoi@gmail.com'
  p.description = "Format Atom and RSS feeds for the Kindle."
  p.summary = "Format Atom and RSS feeds for the Kindle."
  p.url = "http://danielchoi.com/software/kindle-feeds.html"
  p.extra_deps << ['feed-normalizer', '>= 1.5.1'] 
  p.extra_deps << ['hpricot', '>= 0.6'] 
  p.post_install_message = 'Type kindle-feeds -h for instructions.'
end

# vim: syntax=Ruby
