require 'spec_helper'

describe NDBC::Connection do
  
  it "creates a Faraday connection" do
    expect(Faraday).to receive(:new).with(url: 'http://www.ndbc.noaa.gov')
    NDBC::Connection.new
  end

end
