require 'spec_helper'

describe NDBC::Station do
  
  let(:station) { NDBC::Station.new(41009) }
  
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

end
