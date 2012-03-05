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
  spec.rubyforge_project = 'ec2dream'
  spec.version = '3.1.0'
  spec.authors = ['Neill Turner']
  spec.email = 'neillwturner@gmail.com'
  spec.executables = ["ec2dream"]
  spec.homepage = 'http://ec2dream.blogspot.com'
  spec.summary = 'EC2Dream is an graphic system admin tool to build and manage cloud servers.'
  spec.has_rdoc = true
  spec.rdoc_options = ['--main', 'README.txt', '--title', '']
  spec.extra_rdoc_files = ['README.txt']
  spec.require_path = 'lib'
  spec.add_dependency('fxruby')
  spec.add_dependency('right_aws_ec2dream')
  spec.add_dependency('tzinfo')
  spec.add_dependency('rubyzip')
  spec.add_dependency('gchartrb')
  spec.add_dependency('pocketknife_ec2dream')

  spec.description = <<-EOF
== DESCRIPTION:

ec2dream

== FEATURES:

ec2dream

EOF

    candidates = Dir.glob("{lib}/**/*") +  ['History.txt', 'README.txt', 'ec2dream.ico', 'ec2dream.bmp' , 'ec2dream.gemspec']
    candidates = candidates + Dir.glob("{chef}/**/*")
    candidates = candidates +  Dir.glob("{launchrdp}/*")
    candidates = candidates +  Dir.glob("{putty}/*")
    candidates = candidates +  Dir.glob("{tar}/*")
    candidates = candidates +  Dir.glob("{WinSCP}/*")
  spec.files = candidates.sort
  spec.test_files = Dir.glob('test/**/*')
end
