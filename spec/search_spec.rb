require 'search'

describe Search do
  it 'works the queue while we haven\'t found Kevin B, then shuts down' do
    instance = Search.new
    expect(instance).to receive(:find_links).at_least :once
    thread_pool_double = double
    expect(thread_pool_double).to receive(:post).and_yield.at_least :once
    expect(thread_pool_double).to receive(:shutdown)
    expect(thread_pool_double).to receive(:wait_for_termination)
    allow(instance).to receive(:pool).and_return thread_pool_double

    instance.find('')
  end

  it 'logs so you know what is going on while it\'s running' do
    instance = Search.new

    array_double = double
    http_double = double
    title_double = double
    expect(array_double).to receive(:length)
    expect(http_double).to receive(:update)
    expect(title_double).to receive(:update)
    expect(instance).to receive(:queue).and_return array_double
    expect(instance).to receive(:title_counter).and_return title_double
    expect(instance).to receive(:http_counter).and_return http_double

    instance.log
  end

  context '#find_links' do
    let(:instance) { Search.new }
    it 'makes an HTTP call with to the API with the title' do
      title = 'Kevin Bacon'
      instance.not_linked_from.push(title)
      allow(instance).to receive(:wikipedia_api_call) do |arg|
        expect(arg.to_s).to eq "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=#{title}&continue="
      end.and_return "\"title\"=>\"#{title}\""
      instance.find_links(title)
    end

    it 'makes an HTTP call with to the API with the title' do
      title = 'Kevin Bacon'
      instance.not_linked_from.push(title)
      allow(instance).to receive(:wikipedia_api_call) do |arg|
        expect(arg.to_s).to eq "https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=#{title}&continue="
      end.and_return "\"title\"=>\"#{title}\""
      instance.find_links(title)
    end

    it 'continues to make HTTP calls when the response contains the continue attribute' do
      search_for = 'Kyra Sedgwick'
      response = { query: { pages: { '123': { links: [] } } } }

      allow(instance).to receive(:wikipedia_api_call) do |arg|
        expect(arg.to_s).to eq URI.encode("https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=#{search_for}&continue=")
      end
      expect(instance).to receive(:wikipedia_api_call).and_return(response.merge({ continue: { one: true, two: true }}).to_json, response.merge({ title: search_for }).to_json)
      instance.find_links(search_for)
    end

    it 'raises an error when the API raises an error' do
      search_for = 'Kyra Sedgwick'
      response = { error: 'SomeError' }

      allow(instance).to receive(:wikipedia_api_call) do |arg|
        expect(arg.to_s).to eq URI.encode("https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=#{search_for}&continue=")
      end
      expect(instance).to receive(:wikipedia_api_call).and_return(response.to_json)
      expect { instance.find_links(search_for) }.to raise_exception('SomeError')
    end

    it 'returns immediately if you search for the target search term' do
      expect(instance).not_to receive(:wikipedia_api_call)
      response = instance.find('Kevin Bacon')
      expect(response).to eq 0
    end
  end

  context '#find' do
    it 'writes found titles to the queue and consumes them' do
      instance = Search.new
      search_for = 'Kyra Sedgwick'
      response = { query: { pages: { '123': { links: [{ title: 'one' }, { title: 'two' }] } } } }

      pool = Concurrent::FixedThreadPool.new(1)
      allow(instance).to receive(:pool).and_return(pool)
      allow(instance).to receive(:wikipedia_api_call) do |arg|
        uri = URI.encode("https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=#{search_for}&continue=")
        expect(uri).to eq(arg.to_s)
      end
      allow(instance).to receive(:wikipedia_api_call) do |arg|
        uris = [URI.encode("https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=two&continue="),
                URI.encode("https://en.wikipedia.org/w/api.php?format=json&action=query&prop=links&pllimit=500&titles=one&continue=")]
        expect(uris.include? arg.to_s).to eq(true)
      end

      expect(instance).to receive(:wikipedia_api_call).and_return(response.to_json, {}.to_json, {}.to_json)
      expect(instance).to receive(:find_links).and_call_original.at_least(3).times
      instance.find(search_for)
    end
  end
end
