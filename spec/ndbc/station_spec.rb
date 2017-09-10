require 'spec_helper'

describe NDBC::Station do

  subject(:station) { NDBC::Station.new(41009) }
  
  let(:not_found_station) { NDBC::Station.new('00000') }

  methods = %i(wdir wspd gst wvht dpd apd mwd pres atmp wtmp dewp vis ptdy tide dir spd gdr gsp
               gtime h0 wwh wwp wwd steepness avp swh swp swd swd owner ttype hull name payload
               location timezone forecast note active)
  methods.each do |method_sym|
    it { is_expected.to respond_to(method_sym) }
  end

  describe "initialization" do

    it "assigns the id" do
      expect(station.id).to eq("41009")
    end

    it "has a connection" do
      expect(station).to respond_to(:connection)
    end

  end

  describe '.all' do
    let(:result) do
      VCR.use_cassette("station_table") do
        NDBC::Station.all
      end
    end

    it 'returns an array of stations' do
      expect(result).to be_a(Array)
      expect(result).to all(be_a(NDBC::Station))
    end

    describe 'the stations' do
      it 'have the data from the station_table filled in' do
        expect(result).to all(satisfy do |station|
          location = station.location
          location.class == Hash &&
          location.key?(:latitude) &&
          location.key?(:longitude)
        end)
        expect(result).to all(satisfy do |station|
          inactive_regex = /disestablished|discontinued|inoperative|decommissioned/
          station.note.nil? ||
          station.active == !station.note.match(inactive_regex)
        end)
      end
    end
  end

  shared_examples_for :results_format do |meth|

    let(:result) do
      VCR.use_cassette(meth) do
        station.public_send(meth)
      end
    end
    
    it "returns a hash with units and values" do
      expect(result[:units]).to be_a(Hash)
      expect(result[:values]).to be_a(Array)
    end

    it "returns and array of values that are hashes" do
      expect(result[:values].first).to be_a(Hash)
    end

    describe "units" do
      it "removes the # from the first two lines of raw text" do
        expect(result[:units]["YY"]).to eq("yr")
      end
    end

    describe "values" do
      it "replaces 'MM' with nil" do
        mm_found = false
        result[:values].each do |row|
          if row.values.include?("MM")
            mm_found = true
            break
          end
        end
        expect(mm_found).to be false
      end

      it "skips the first two rows of raw data" do
        expect(result[:values].first["YY"]).to eq("2015")
      end
    end

  end

  shared_examples_for :station_not_found do |meth|
    it "raises NDBC::StationNotFound when the station url can't be found" do
      VCR.use_cassette("#{meth}_station_not_found") do
        expect{not_found_station.public_send(meth)}.to raise_error(
          NDBC::StationNotFound, "Could not find station #{not_found_station.id}")
      end
    end
  end

  describe "#standard_meteorological_data" do
    it_behaves_like :results_format, 'standard_meteorological_data'
    it_behaves_like :station_not_found, 'standard_meteorological_data'
  end

  describe "#continuous_winds_data" do
    it_behaves_like :results_format, 'continuous_winds_data'
    it_behaves_like :station_not_found, 'continuous_winds_data'
  end

  describe "#spectral_wave_summaries" do
    it_behaves_like :results_format, 'spectral_wave_summaries'
    it_behaves_like :station_not_found, 'spectral_wave_summaries'
  end


  describe "#spectral_wave_forecasts" do

    let(:buoy) { NDBC::Station.new(41009) }

    let(:response) do
      VCR.use_cassette("spectral_wave_forecasts") do
        buoy.spectral_wave_forecasts
      end
    end

    it_behaves_like :station_not_found, 'spectral_wave_forecasts'

    it "makes a request" do
      expect(buoy.connection).to receive(:get).with("http://polar.ncep.noaa.gov/waves/WEB/multi_1.latest_run/plots/multi_1.41009.bull")
      buoy.spectral_wave_forecasts
    end

    it "parses the cycle line and uses it to set up the first date" do
      expect(response.first[:time]).to eq( DateTime.new(2015, 9, 7, 3) )
    end

    it "returns an array of hashes with a height key" do
      expect(response.first[:hst]).to be_a Float
    end

    it "returns an array of hashes with a swells array" do
      expect(response.first[:swells]).to be_a Array
    end

    it "returns an array of hashes with a swells array, that contains hashes with hs, tp, and dir" do
      swell = response.first[:swells].first
      expect(swell[:hs]).to be_a Float
      expect(swell[:tp]).to be_a Float
      expect(swell[:dir]).to be_a Fixnum
    end

    describe "times" do

      it "calculates the right time" do
        expect(response[1][:time]).to eq( response.first[:time] + 1.hour )
      end

    end

  end

end
