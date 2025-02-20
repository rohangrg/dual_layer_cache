# frozen_string_literal: true

require_relative "lib/dual_layer_cache/version"

Gem::Specification.new do |spec|
  spec.name = "dual_layer_cache"
  spec.version = DualLayerCache::VERSION
  spec.authors = ["Rohan Garg"]
  spec.email = ["rohangarg32767@gmail.com"]

  spec.summary = "A dual-layer caching system for Rails using Redis."
  spec.description = "Provides a dual-layer caching strategy for Ruby on Rails with a primary (R1) and fallback (R2) cache in Redis, ensuring high availability and minimal downtime during cache invalidation."
  spec.homepage = "https://github.com/rohangarg/dual_layer_cache"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org" # Default to RubyGems.org
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/rohangarg/dual_layer_cache" # Update if your GitHub username differs
  spec.metadata["changelog_uri"] = "https://github.com/rohangarg/dual_layer_cache/blob/main/CHANGELOG.md" # Update if your GitHub username differs

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies required for the gem
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "redis", ">= 4.0"
end