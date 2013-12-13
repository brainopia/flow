Gem::Specification.new do |gem|
  gem.name          = 'flow-queue'
  gem.version       = '0.1'
  gem.authors       = 'brainopia'
  gem.email         = 'brainopia@evilmartians.com'
  gem.homepage      = 'https://github.com/brainopia/flow'
  gem.summary       = 'Abstract queue action for Flow'
  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep %r{^spec/}
  gem.require_paths = %w(lib)

  gem.add_dependency 'flow_base'
  gem.add_dependency 'floq'
  gem.add_development_dependency 'rspec'
end
