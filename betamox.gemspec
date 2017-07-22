# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'betamox/version'

Gem::Specification.new do |spec|
  spec.name          = 'betamox'
  spec.version       = Betamox::VERSION
  spec.authors       = ['Alastair Dawson']
  spec.email         = ['alastair.j.dawson@gmail.com']

  spec.summary       = 'Mock APIs by recording and/or generating responses and replaying them.'
  spec.description   = 'Similar to VCR for specs but for realz, like betamax it is less popular but higher quality.'
  spec.homepage      = 'http://github.com/kreek/betamox'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.add_dependency 'faraday', ['>= 0.7.4', '<= 0.12.2']
end
