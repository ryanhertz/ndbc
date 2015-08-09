require "faraday"

module NDBC
  class Connection

    def self.new
      Faraday.new(url: 'http://www.ndbc.noaa.gov') do |faraday|
        faraday.adapter  Faraday.default_adapter
      end
    end


  end
end
