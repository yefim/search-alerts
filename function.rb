require 'algoliasearch'
require 'httparty'

def handler(event:, context:)
  client = Algolia.init(
    application_id: ENV['APP_ID'],
    api_key: ENV['API_KEY']
  )

  index = client.init_index('Listing_production');

  yesterday = Time.now.to_i - 60 * 60 * 24

  results = index.search('', {
    filters: "created_at_i >= #{yesterday} AND (strata:grailed OR strata:hype OR strata:basic OR strata:sartorial) AND (designers.id:28) AND (category:tops OR category:outerwear OR category:bottoms OR category:tailoring OR category:accessories OR category_path_root_size:footwear.12 OR category_path_root_size:footwear.13) AND price_i>=0 AND (marketplace: grailed)",
    hitsPerPage: 50,
    page: 0,
  })

  puts "Fetched #{results['hits'].count} result(s)."

  return if results['hits'].count == 0

  email = results['hits'].map do |res|
    photo = res['retina_cover_photo']['url']

    %Q(<div><img src="#{photo}" /><p><a href="https://www.grailed.com/listings/#{res['id']}">#{res['title']}</a> for #{res['price_i']}</p></div>)
  end.join('')

  puts email

  response = HTTParty.post(ENV['IFTTT_URL'], {
    body: {
      value1: email
    }.to_json,
    headers: {
      'Content-Type' => 'application/json'
    },
  })

  puts response
end
