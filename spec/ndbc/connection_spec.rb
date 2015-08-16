require 'spec_helper'

describe NDBC::Connection do
  
  describe "initialization" do
    it "creates a Faraday connection" do
      expect(Faraday).to receive(:new).with(url: 'http://www.ndbc.noaa.gov')
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
        expect{ connection.get("/not_found") }.to raise_error(NDBC::NotFound)
      end
    end

  end

end
