module NDBC
  module StationTable
    class << self
      def station_table_data
        response = Connection.new.get(NDBC.config[:urls][:station_table])
        rows = response.split("\n").drop(2)
        rows.map do |station|
          station_parts = cleanup_parts!(station.split('|'))

          {
            id:         station_parts[0],
            owner:      station_parts[1],
            type:       station_parts[2],
            hull:       station_parts[3],
            name:       station_parts[4],
            payload:    station_parts[5],
            location:   extract_location(station_parts[6]),
            time_zone:  station_parts[7],
            forecast:   station_parts[8],
            note:       station_parts[9],
            active:     active?(station_parts),
            tide_station_id: tide_station_id(station_parts[4])
          }
        end
      end

      private

      def tide_station_id(name)
        return '' unless name
        name.match(/\d{7}/).to_s
      end

      def cleanup_parts!(station_parts)
        station_parts.map! do |part|
          part = part.gsub('&nbsp;', ' ')
          part = part.strip unless part.nil?
          part = (part == '' || part == '?') ? nil : part
          part
        end
      end

      def active?(parts)
        note = parts[9]
        return true unless note
        !note.match(/disestablished|discontinued|inoperative|decommissioned/)
      end

      def extract_location(raw_location)
        lat_lon = { latitude: nil, longitude: nil }
        match = raw_location.match(/(\d+\.\d+)\s(N|S)\s(\d+.\d+)\s(E|W)/)
        return lat_lon unless match
        parts = match.captures

        unsigned_lat = parts[0].to_f
        lat_hemisphere = parts[1]
        unsigned_lon = parts[2].to_f
        lon_hemisphere = parts[3]
        lat_lon[:latitude] = lat_hemisphere == 'N' ? unsigned_lat : -unsigned_lat
        lat_lon[:longitude] = lon_hemisphere == 'E' ? unsigned_lon : -unsigned_lon

        lat_lon
      end
    end
  end
end
