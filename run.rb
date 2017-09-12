require 'open-uri'
require 'json'
require 'dag'

puts 'Enter the page title you want to search:'
title = gets.chomp

results = {}

def find_links(title)
  limit = 5
  url = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=#{limit}&titles=#{title}"
  continue = '&continue='
  while true
    p "#{url}#{continue}"
    url_with_continue = URI.encode("#{url}#{continue}")
    response = JSON.load(open(URI.parse(url_with_continue)))

    # reset continue params
    continue = ''
    #handle errors
    raise response['error'] unless response['error'].nil?
    p response['warnings'] unless response['warnings'].nil?
    p response['query'] unless response['query'].nil?
    break if response['continue'].nil?

    # create the next continue method
    response['continue'].each { |key, value| continue += "&#{key}=#{value}" }

    # parse the response - making an assumption here about the structure of the wikipedia resp.
    pages = response['query']['pages']
    page_key = pages.keys.first
    p pages[page_key]['links']
    p '---'
  end
end

find_links(title)
