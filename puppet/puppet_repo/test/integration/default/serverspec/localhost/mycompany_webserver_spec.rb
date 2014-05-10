require 'spec_helper'

describe 'mycompany_webserver' do

  it 'is listening on port 80' do
    expect(port(80)).to be_listening
  end

end