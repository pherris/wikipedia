require 'open-uri'
require 'json'
require 'concurrent'

class Search
  SEARCHING_FOR = 'Kevin Bacon'.freeze
  MAX_DEPTH = 10

  def initialize
    @found_kevin = Concurrent::AtomicFixnum.new
  end

  def find(title)
    find_links(title)

    logged_at = Time.now
    while true
      break if @found_kevin.value > 0
      pool.post do
        begin
          title, depth = queue.shift
          next if title.nil?
          find_links(title, depth)
        rescue => e
          p e
          raise e
        end
      end
      # log some info about progress
      if Time.now - 2 > logged_at
        logged_at = Time.now
        log
        # poor mans check to see if no results were returned, could use some extra validation about the initial search
        break if queue.size == 0
      end
    end

    # tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
    pool.shutdown
    # now wait for all work to complete, wait as long as it takes
    pool.wait_for_termination

    return @found_kevin.value
  end

  def find_links(title, depth = 1)
    limit = 500
    url = "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=#{limit}&titles=#{title}"
    continue = '&continue='
    return if not_linked_from.include? title

    while true
      break if @found_kevin.value > 0
      break if not_linked_from.include? title
      url_with_continue = URI.encode("#{url}#{continue}")
      response = JSON.load(wikipedia_api_call(URI.parse(url_with_continue)))
      # include? is not quite as elegant as parsing out each title and checking
      # it, but this gets it done as soon as possible
      if (response.to_s.include? "\"title\"=>\"#{SEARCHING_FOR}\"") && (@found_kevin.value == 0)
        p "Found a reference to Kevin on page titled: '#{title}', it can take a second to shut down"
        @found_kevin.update { depth }
        queue.clear
        break
      end
      http_counter.increment

      # reset continue params
      continue = ''

      #handle errors
      raise response['error'] unless response['error'].nil?
      p response['warnings'] unless response['warnings'].nil?
      break if response['query'].nil?
      break if depth > MAX_DEPTH

      # create the next continue url params
      response['continue'].each { |key, value| continue += "&#{key}=#{value}" } unless response['continue'].nil?

      # we've retrieved all the results for this page, and didn't find Kevin
      if continue == ''
        not_linked_from.push(title)
      end

      # parse the response
      # making an assumption here about the structure of the wikipedia resp.
      pages = response['query']['pages']
      page_key = pages.keys.first

      # enqueue the titles to check
      new_depth = depth + 1
      titles_to_search = (pages[page_key]['links'] || []).collect { |link| [link['title'], new_depth] }
      title_counter.increment titles_to_search.length
      # concat is much more efficient than pushing them one at a time
      queue.concat titles_to_search
    end
  end

  def found_kevin
    @found_kevin
  end

  def wikipedia_api_call(uri)
    open(uri)
  end

  def pool
    @pool ||= Concurrent::FixedThreadPool.new(20)
  end

  def queue
    @queue ||= Concurrent::Array.new
  end

  def not_linked_from
    @not_linked_from ||= Concurrent::Array.new
  end

  def title_counter
    @title_counter ||= Concurrent::AtomicFixnum.new
  end

  def http_counter
    @http_counter ||= Concurrent::AtomicFixnum.new
  end

  def log
    puts "Queue Length: #{queue.length}"
    http_counter.update do |val|
      puts "http requests made: #{val}"
      0
    end
    title_counter.update do |val|
      puts "titles examined: #{val}"
      0
    end
  end
end
