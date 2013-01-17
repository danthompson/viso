require 'rspec/core/rake_task'
load 'tasks/emoji.rake'

RSpec::Core::RakeTask.new

task :default => :spec

desc 'Move documentation to the docs project root'
task :move_docs do
  sh 'mv docs/viso.html ../viso-docs/index.html && mv docs/* ../viso-docs'
end
