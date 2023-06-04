# frozen_string_literal: true

require_relative "lib/trailblazer/workflow/version"

Gem::Specification.new do |spec|
  spec.name = "trailblazer-workflow"
  spec.version = Trailblazer::Workflow::VERSION
  spec.authors = ["Nick Sutterer"]
  spec.email = ["apotonick@gmail.com"]
  spec.license = "LGPL-3.0"

  spec.summary = "BPMN process engine"
  spec.homepage = "https://trailblazer.to/2.1/docs/workflow"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/trailblazer/trailblazer-workflow"
  spec.metadata["changelog_uri"] = "https://github.com/trailblazer/trailblazer-workflow/blob/master/CHANGES.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem

  spec.add_dependency "trailblazer-developer", ">= 0.0.17"
  spec.add_dependency "representable", "~> 3.1"
  spec.add_dependency "multi_json"
  spec.add_dependency "trailblazer-macro"
  spec.add_development_dependency "minitest-line"
end
