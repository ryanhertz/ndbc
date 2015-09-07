require "ndbc/version"
require "ndbc/connection"
require "ndbc/station"

module NDBC
  
  @config = {
    urls: {
      observations: "http://www.ndbc.noaa.gov/data/realtime2/",
      predictions: "http://polar.ncep.noaa.gov/waves/WEB/multi_1.latest_run/plots/"
    }
  }

  def self.config
    @config
  end
end
