module Databases
  class API
    DEFAULT_API_URL = 'http://data.example.com/databases'
    attr_reader :uri
    def initialize(role, base_path =  DEFAULT_API_URL )
      @uri = URI("#{base_path}/#{role}")
    end

    def fetch_databases(&block)
      response = http_client.request(databases_get_request)
      if response.code == '200'
        block.call(JSON.parse(response.body))
      else
        puts "Error fetching databases, Status code: #{response.code}"
      end
    end

    private

    def databases_get_request
      Net::HTTP::Get.new(uri, {
                         'Content-Type' => 'application/json'
      })
    end

    def http_client
      @http_clinet ||= Net::HTTP.new(uri.host, uri.port)
    end


  end
end
#
