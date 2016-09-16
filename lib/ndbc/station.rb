require 'active_support/time'
# http://www.ndbc.noaa.gov/rt_data_access.shtml

module NDBC
  class Station
    include NDBC::StationTable

    class << self
      def all
        NDBC::StationTable.station_table_data.map { |data| new(data[:id], data) }
      end
    end

    attr_accessor :id, :connection
    attr_reader :owner, :ttype, :hull, :name, :payload, :location, :timezone, :forecast, :note,
                :active

    alias_method :active?, :active

    def initialize(id, station_data = {})
      @id = id.to_s
      @owner = station_data[:owner]
      @ttype = station_data[:ttype]
      @hull = station_data[:hull]
      @name = station_data[:name]
      @payload = station_data[:payload]
      @location = station_data[:location]
      @timezone = station_data[:timezone]
      @forecast = station_data[:forecast]
      @note = station_data[:note]
      @active = station_data[:active]
      @connection = Connection.new
    end

    def inspect
      "#{id} (lat: #{@location[:latitude]}, lon: #{@location[:longitude]})"
    end

    def standard_meteorological_data
      parse_observation_response get_data(NDBC.config[:urls][:observations] + id + ".txt")
    end

    def latest_standard_meteorological_data
      latest_data(:standard_meteorological_data)
    end

    def continuous_winds_data
      parse_observation_response get_data(NDBC.config[:urls][:observations] + id + ".cwind")
    end

    def latest_continuous_winds_data
      latest_data(:continuous_winds_data)
    end

    def spectral_wave_summaries
      parse_observation_response get_data(NDBC.config[:urls][:observations] + id + ".spec")
    end

    def latest_spectral_wave_summaries
      latest_data(:spectral_wave_summaries)
    end

    def spectral_wave_forecasts
      parse_prediction_response get_data(NDBC.config[:urls][:predictions] + "multi_1.#{id}.bull")
    end

    def latest_spectral_wave_forecasts
      latest_data(:spectral_wave_forecasts)
    end

    def method_missing(method_sym, *arguments, &block)
      upcased_method_name = method_sym.to_s.upcase
      case method_sym
      when :wdir, :wspd, :gst, :wvht, :dpd, :apd, :mwd,
           :pres, :atmp, :wtmp, :dewp, :vis, :ptdy, :tide
        latest_standard_meteorological_data[upcased_method_name]
      when :dir, :spd, :gdr, :gsp, :gtime
        latest_continuous_winds_data[upcased_method_name]
      when :h0, :wwh, :wwp, :wwd, :steepness, :avp
        latest_spectral_wave_summaries[upcased_method_name]
      when :swh
        latest_spectral_wave_summaries['SwH']
      when :swp
        latest_spectral_wave_summaries['SwP']
      when :swd
        latest_spectral_wave_summaries['SwD']
      else
        super
      end
    end

    def respond_to_missing?(method_sym, include_private = false)
      case method_sym
      when :wdir, :wspd, :gst, :wvht, :dpd, :apd, :mwd, :pres, :atmp, :wtmp, :dewp, :vis, :ptdy,
           :tide, :dir, :spd, :gdr, :gsp, :gtime, :h0, :wwh, :wwp, :wwd, :steepness, :avp, :swh,
           :swp, :swd, :swd
        true
      else
        super
      end
    end

    private

    def latest_data(dataset)
      send(dataset)[:values].sort_by do |row|
        "#{row['YY']}#{row['MM']}#{row['DD']}#{row['hh']}#{row['mm']}"
      end.last || {}
    end

    def get_data(path)
      connection.get(path)
    rescue NotFound => error
      puts "Failed to get data for station #{id}"
    end

    def parse_observation_response(response)
      data = {
        units: {},
        values: []
      }

      return data if response.nil?

      response = response.split("\n")

      labels = response[0][1..-1].split(/\s+/)
      units = response[1][1..-1].split(/\s+/)

      data[:units] = Hash[ labels.zip(units) ]

      response[2..-1].each do |line|
        values = line.split(/\s+/).collect { |item| (item == "MM") ? nil : item }
        data[:values] << Hash[ labels.zip(values) ]
      end

      data
    end

    def parse_prediction_response(response)
      return if response.nil?
      lines = response.split("\n")
      first_time = parse_cycle_line(lines[2])

      n = 0

      [].tap do |array|
        lines[7..196].each do |line|
          split_line = line.split('|')
          array << {
            time: first_time + n.hours,
            hst: get_hst(split_line),
            swells: parse_swells(split_line)
          }
          n = n+1
        end
      end
    end

    def parse_cycle_line(line)
      time_string = line[-15..-1] # "20140809  6 UTC"
      year =  time_string[0..3].to_i
      month = time_string[4..5].to_i
      day =   time_string[6..7].to_i
      hour =  time_string[9..10].to_i
      DateTime.new(year, month, day, hour) - 9.hours
    end

    def get_hst(split_line)
      split_line[2].strip.split(/\s+/)[0].to_f
    end


    def parse_swells(split_line)
      swells = []
      split_line.slice(3..8).each do |swell_block|
        swells << parse_swell_block(swell_block)
      end
      return swells
    end

    def parse_swell_block(swell_block)
      pieces = swell_block.gsub('*', '').strip.split(/\s+/)
      {
        hs: pieces[0].to_f,
        tp: pieces[1].to_f,
        dir: pieces[2].to_i
      }
    end

  end

end
