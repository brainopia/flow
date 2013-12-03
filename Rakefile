desc 'Run all tests by default'
task :default => :rspec

desc 'Run rspec for all projects'
task :rspec do
  projects = Dir['*/Gemfile'].map do |gemfile|
    File.basename File.expand_path '..', gemfile
  end

  failed = projects.reject do |project|
    system "cd #{project} && bundle exec rspec"
  end

  raise "Errors in #{failed.join(', ')}" unless failed.empty?
end
