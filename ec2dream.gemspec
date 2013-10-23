#--  -*- mode: ruby; encoding: utf-8 -*-
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

Gem::Specification.new do |spec|
  spec.name = 'ec2dream'
  spec.version = '3.6.7'
  spec.authors = ['Neill Turner']
  spec.email = 'neillwturner@gmail.com'
  spec.executables = ["ec2dream"]
  spec.homepage = 'http://ec2dream.blogspot.com'
  spec.summary = 'Build and Manage Cloud Servers'
  spec.require_path = 'lib'
  spec.add_dependency('fxruby')
  spec.add_dependency('rubyzip', '< 1.0.0')
  spec.add_dependency('gchartrb')
  spec.add_dependency('pocketknife_ec2dream', '>= 0.1.10')
  spec.add_dependency('pocketknife_puppet', '>= 0.1.10')
  spec.add_dependency('pocketknife_windows', '>= 0.1.10')
  spec.add_dependency('fog', '= 1.12.1')
  spec.add_dependency('cloudfoundry-client')

  spec.description = <<-EOF
== DESCRIPTION:

Build and Manage Cloud Servers

== FEATURES:

EC2Dream combines Fog, Ruby, into a visual open source devops platform supporting:
      Amazon AWS with full support for VPC, Autoscaling and ability to list most entities.
      Amazon compatible clouds:  Eucalyptus, CloudStack.
      Openstack Clouds:  Rackspace Cloud Servers and HP Cloud.
      Cloud Foundry and even Local Servers.
      Chef and Puppet.

EOF

    candidates = Dir.glob("{lib}/**/*") +  ['History.txt', 'README.txt', 'ec2dream.ico', 'ec2dream.bmp' , 'ec2dream.gemspec']
    candidates = candidates + Dir.glob("{chef}/**/*")
    candidates = candidates + Dir.glob("{puppet}/**/*")
    candidates = candidates +  Dir.glob("{launchrdp}/*")
    candidates = candidates +  Dir.glob("{putty}/*")
    candidates = candidates +  Dir.glob("{rackspace}/*")
    candidates = candidates +  Dir.glob("{tar}/*")
    candidates = candidates +  Dir.glob("{wget}/*")
    candidates = candidates +  Dir.glob("{WinSCP}/*")
  spec.files = candidates.sort
end
