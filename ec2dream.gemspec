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
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'EC2_version'

Gem::Specification.new do |spec|
  spec.name = 'ec2dream'
  spec.version = EC2Dream::VERSION
  spec.authors = ['Neill Turner']
  spec.license       = "Apache-2.0"
  spec.email = 'neillwturner@gmail.com'
  spec.executables = ["ec2dream"]
  spec.homepage = 'http://ec2dream.blogspot.com'
  spec.required_ruby_version = '>= 2.0'
  spec.require_path = 'lib'
#  spec.add_dependency('fxruby', '<= 1.6.29')
  spec.add_dependency('fxruby', '= 1.6.33')
  spec.add_dependency('net-ssh', '<= 2.9.2')
  spec.add_dependency('test-kitchen', '~> 1.4')
  spec.add_dependency('rubyzip', '>= 1.0.0')
  spec.add_dependency('zip-zip')
  spec.add_dependency('gchartrb')
  spec.add_dependency('fog', '>= 1.37.0')
  spec.add_dependency('fog-azure')
  
  spec.summary = 'Build and Manage Cloud Servers'
  spec.description = 'Visual devops tool. Supports chef, puppet, ansible, test-kitchen with Hosted Servers and Clouds including Amazon AWS,  Azure, Google Compute Engines, Softlayer, Openstack'
    candidates = Dir.glob("{lib}/**/*") +  ['History.md', 'README.md', 'ec2dream.ico', 'ec2dream.bmp' , 'ca-bundle.crt', 'ec2dream.gemspec']
    candidates = candidates +  Dir.glob("{chef}/**/*")
    candidates = candidates +  Dir.glob("{launchrdp}/*")
    candidates = candidates +  Dir.glob("{putty}/*")
    candidates = candidates +  Dir.glob("{google}/*")
    candidates = candidates +  Dir.glob("{tar}/*")
    candidates = candidates +  Dir.glob("{wget}/*")
    candidates = candidates +  Dir.glob("{WinSCP}/*")
    candidates = candidates +  Dir.glob("{vagrant}/*")
    spec.files = candidates.sort
end
