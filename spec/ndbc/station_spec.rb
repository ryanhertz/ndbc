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

  describe "standard_meteorological_data" do

    let(:smd) do 
      VCR.use_cassette("standard_meteorological_data") do
        station.standard_meteorological_data
      end
    end

    it "returns a hash with units and values" do
      expect(smd[:units]).to be_a(Hash)
      expect(smd[:values]).to be_a(Array)
    end

    it "returns and array of values that are hashes" do
      expect(smd[:values].first).to be_a(Hash)
    end

  end

end

