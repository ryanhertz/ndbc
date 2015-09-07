require 'spec_helper'

describe NDBC::Connection do
  
  describe "initialization" do
    it "creates a Faraday connection" do
      expect(Faraday).to receive(:new)
      NDBC::Connection.new
    end
  end

  describe "get" do
    let(:connection) { NDBC::Connection.new }

    it "gets" do
      expect(connection).to respond_to(:get)
    end

    it "handles 404's" do
      VCR.use_cassette("not_found") do
        expect{ connection.get("http://www.ndbc.noaa.gov/not_found") }.to raise_error(NDBC::NotFound)
      end
    end

  end

end
