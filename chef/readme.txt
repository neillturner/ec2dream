Using EC2Dream with test-kitchen and berkshelf
----------------------------------------------
To work with chef repositories with a Berks file berkshelf needs to be able to run on your workstation. 
1. To do this on windows first install the Ruby DevKit:
  a. Go to a Command Window. 
  b. Download and install devkit from http://rubyinstaller.org/downloads/
  c. In the devkit directory run  “ruby dk.rb init”. 
  d. Edit the config.yml generated and add the the path of the ruby install if necessary.
  e. run “ruby dk.rb install” to bind it to the puppet ruby installation.
2. Install berkshelf:  gem install berkshelf -v 2.0.17
