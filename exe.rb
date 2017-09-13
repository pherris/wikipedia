require_relative 'lib/search'

STDOUT.puts 'Enter the page title you want to search:'
title = STDIN.gets.strip
searcher = Search.new
p searcher.find(title)
