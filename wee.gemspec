require_relative 'lib/wee/version'

Gem::Specification.new do |spec|
  spec.name          = "wee"
  spec.version       = Wee::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Michael Neumann"]
  spec.email         = ["mneumann@ntecs.de"]

  spec.summary       = 'Wee is a framework for building highly dynamic web applications.'
  spec.description   = <<~EOF
    Wee is a stateful component-orient web framework which supports
    continuations as well as multiple page-states, aka backtracking.
    It is largely inspired by Smalltalk's Seaside framework.
  EOF
  spec.homepage      = "https://github.com/mneumann/wee"
  spec.license       = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mneumann/wee"
  spec.metadata["changelog_uri"] = "https://raw.githubusercontent.com/mneumann/wee/master/CHANGELOG.rdoc"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_path  = "lib"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "test-unit", '~> 3.0'

  spec.add_dependency('rack', '~> 2.0')
  spec.add_dependency('fast_gettext', '>= 0.4.17')
end
