require 'spec_helper'

describe SxGeo do
	it 'can find location by ip' do
		SxGeo.new.get('87.250.250.203')['city'].force_encoding('UTF-8').should == 'Москва'
	end

	it 'works in batch mode' do
		sxgeo = SxGeo.new SxGeo::SXGEO_CITY_FILE, SxGeo::SXGEO_BATCH
		sxgeo.get('87.250.250.203')['city'].force_encoding('UTF-8').should == 'Москва'
	end

	it 'works in memory mode' do
		sxgeo = SxGeo.new SxGeo::SXGEO_CITY_FILE, SxGeo::SXGEO_MEMORY
		sxgeo.get('87.250.250.203')['city'].force_encoding('UTF-8').should == 'Москва'
	end

	it 'works in batch and memory modes' do
		sxgeo = SxGeo.new SxGeo::SXGEO_CITY_FILE, SxGeo::SXGEO_BATCH | SxGeo::SXGEO_MEMORY
		sxgeo.get('87.250.250.203')['city'].force_encoding('UTF-8').should == 'Москва'
	end

	it '.ip2long works well' do
		sxgeo = SxGeo.new
		sxgeo.ip2long('87.250.250.203').should == 1476065995
	end

end
