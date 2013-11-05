Gem::Specification.new do |spec|
  spec.name         = 'flow_cassandra'
  spec.version      = '0.1'
  gem.authors       = 'brainopia'
  gem.email         = 'brainopia@evilmartians.com'
  gem.homepage      = 'https://github.com/brainopia/flow'
  gem.summary       = 'Base Flow'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep %r{^spec/}
  gem.require_paths = %w(lib)

  gem.add_development_dependency 'rspec'
end
