require 'spec_helper'

describe NDBC::Station do

  subject(:station) { NDBC::Station.new(41009) }

  it do
    methods = %i(wdir wspd gst wvht dpd apd mwd pres atmp wtmp dewp vis ptdy tide dir spd gdr gsp
                 gtime h0 wwh wwp wwd steepness avp swh swp swd swd)
    methods.each do |method_sym|
      is_expected.to respond_to(method_sym)
    end
  end

  describe "initialization" do

    it "assigns the id" do
      expect(station.id).to eq("41009")
    end

    it "has a connection" do
      expect(station).to respond_to(:connection)
    end

  end

  shared_examples_for "station" do

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

  describe "standard_meteorological_data" do

    let(:result) do
      VCR.use_cassette("standard_meteorological_data") do
        station.standard_meteorological_data
      end
    end

    it_behaves_like "station"

    context 'when the station is not found' do

      let(:not_found_station) { NDBC::Station.new(00000) }

      let(:not_found_result) do
        VCR.use_cassette("standard_meteorological_data_not_found") do
          not_found_station.standard_meteorological_data
        end
      end

      it "returns a hash with units and values" do
        expect(not_found_result[:units]).to be_a(Hash)
        expect(not_found_result[:values]).to be_a(Array)
      end

    end

  end

  describe "meteorological data from drifting buoys" do
  end

  describe "continuous winds data" do
    let(:result) do
      VCR.use_cassette("continuous_winds_data") do
        station.continuous_winds_data
      end
    end

    it_behaves_like "station"
  end

  describe "spectral wave summaries" do
    let(:result) do
      VCR.use_cassette("spectral_wave_summaries") do
        station.spectral_wave_summaries
      end
    end

    it_behaves_like "station"
  end

  describe "error handling" do

    let(:not_found) do
      NDBC::Station.new(00000)
    end

    it "catches 404's" do
      VCR.use_cassette("station_not_found") do
        expect{not_found.standard_meteorological_data}.not_to raise_error
      end

    end
  end

  describe "spectral wave forecasts" do

    let(:buoy) { NDBC::Station.new(41009) }

    let(:response) do
      VCR.use_cassette("spectral_wave_forecasts") do
        buoy.spectral_wave_forecasts
      end
    end

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
