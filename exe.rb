require_relative 'lib/search'

STDOUT.puts 'Enter the page title you want to search (e.g. https://en.wikipedia.org/wiki/Tom_Cruise would be "Tom Cruise"):'
title = STDIN.gets.strip
searcher = Search.new
separation = searcher.find(title)
p "Found #{separation} degrees of separation between pages"