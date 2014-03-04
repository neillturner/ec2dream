require './spec_helper.rb'

# centos package httpd, ubuntu package apache2 
describe 'mycompany_webserver::default' do
  context 'on centos' do
    before{ Fauxhai.mock(platform:'ubuntu',version:'12.04') }
    let(:chef_run){ ChefSpec::Runner.new.converge('mycompany_webserver::default') }
    it 'should install the correct packages' do
      chef_run.should install_package 'apache2'
     end
  end
end
