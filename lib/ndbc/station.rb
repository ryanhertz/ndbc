
# http://www.ndbc.noaa.gov/rt_data_access.shtml

module NDBC
  class Station

    attr_accessor :id, :connection

    def initialize(id)
      @id = id.to_s
      @connection = Connection.new
    end

    def standard_meteorological_data
      get_data "txt"
    end

    def continuous_winds_data
      get_data "cwind"
    end

    def spectral_wave_summaries
      get_data "spec"
    end

    private

    def get_data(type)
      parse_response connection.get("/data/realtime2/#{id}.#{type}")
    end

    def parse_response(response)
      response = response.body.split("\n")

      labels = response[0].split(/\s+/)
      units = response[1].split(/\s+/)

      data = {
        units: Hash[ labels.zip(units) ],
        values: []
      }

      response.slice(2..26).each do |line|
        data[:values] << Hash[ labels.zip(line.split(/\s+/)) ]
      end

      data
    end

  end
end
