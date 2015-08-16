require "faraday"

module NDBC
  class Connection

    def initialize
      @client = Faraday.new(url: 'http://www.ndbc.noaa.gov') do |faraday|
        faraday.adapter  Faraday.default_adapter
      end
    end

    def get(path)
      response = @client.get(path)
      case response.status
      when 200
        response.body
      when 404
        raise NDBC::NotFound
      end
    end

  end

  class NotFound < StandardError
  end
end
