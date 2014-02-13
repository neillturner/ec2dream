require 'spec_helper'

describe "mycompany-webserver" do
  let(:facts) { 
     {:osfamily => 'RedHat',
     :operatingsystem => 'CentOS',
     :operatingsystemrelease => '6',
	 :concat_basedir         => '/foo',
     }
  }
  it { should create_class('apache')}
end


