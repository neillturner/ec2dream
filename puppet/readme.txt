Using EC2Dream with test-kitchen and librarian-puppet
-----------------------------------------------------
To work with puppet repositories with a Puppetfile librarian-puppet needs to be able to run on your workstation. 
To do this on windows you need to: 
1. Download and install puppet from the windows msi file from https://downloads.puppetlabs.com/windows/ (NOT gem install puppet). 
2. You must run everything from the "Start Command Prompt with Puppet" not a normal Windows Command prompt. 
3. Before installing librarian-puppet the the Ruby DevKit is needed :
  a. Select "Start Command Prompt with Puppet" to go to a Command Windows. 
  b. Download and install devkit from http://rubyinstaller.org/downloads/
  c. In the devkit directory run  “ruby dk.rb init”. 
  d. Edit the config.yml generated and add the the path of the ruby install for puppet
     (it wll be <install dir of puppet>/sys/ruby). 
  e. run “ruby dk.rb install” to bind it to the puppet ruby installation.
4. Finally librarian-puppet:  gem install librarian-puppet
5. ec2dream, librarian-puppet or test-kitchen MUST be run from the "Start Command Prompt with Puppet" not a normal Windows Command prompt. 


  




