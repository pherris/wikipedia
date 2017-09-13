require 'search'

describe Search do
  it 'initalizes an AtomicFixnum when the class is newed up' do
    expect(Concurrent::AtomicFixnum).to receive(:new)
    Search.new
  end

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
  end
end
