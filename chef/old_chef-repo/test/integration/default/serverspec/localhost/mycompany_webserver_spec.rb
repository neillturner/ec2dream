require 'spec_helper'

describe 'mycompany webserver' do

  it 'should be running the httpd server' do
    case RSpec.configuration.os
    when "Debian"
      expect(service 'apache2').to be_running
      expect(service 'apache2').to be_enabled
    else
      expect(service 'httpd').to be_running
      expect(service 'httpd').to be_enabled
    end
  end 
 
  describe port(80) do
    it { should be_listening }
  end

end