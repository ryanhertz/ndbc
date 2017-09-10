require "ndbc/version"
require "ndbc/connection"
require "ndbc/station_table"
require "ndbc/station"
require "ndbc/exceptions"

module NDBC

  @config = {
    urls: {
      station_table: "http://www.ndbc.noaa.gov/data/stations/station_table.txt",
      observations: "http://www.ndbc.noaa.gov/data/realtime2/",
      predictions: "http://polar.ncep.noaa.gov/waves/WEB/multi_1.latest_run/plots/"
    }
  }

  def self.config
    @config
  end
end
