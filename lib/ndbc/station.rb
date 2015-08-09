module NDBC
  class Station

    attr_accessor :id, :connection

    def initialize(id)
      @id = id.to_s
      @connection = Connection.new
    end

    def standard_meteorological_data
      response = connection.get("/data/realtime2/#{id}.txt").body.split("\n")

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
