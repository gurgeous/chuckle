require 'bundler/gem_helper'
require 'rake/testtask'
require 'rdoc/task'

Bundler::GemHelper.install_tasks

#
# test
#

Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
end
task default: :test

#
# rdoc
#

RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "chuckle #{Chuckle::VERSION}"
  rdoc.rdoc_files.include('lib/**/*.rb')
end
