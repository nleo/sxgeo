require 'spec_helper'

describe SxGeo do
	it 'can find location by ip' do
		SxGeo.new.get('87.250.250.203')['city'].force_encoding('UTF-8').should == 'Москва'
	end
end
