# frozen_string_literal: true

require_relative "lib/pg_aggregates/version"

Gem::Specification.new do |spec|
  spec.name = "pg_aggregates"
  spec.version = PgAggregates::VERSION
  spec.authors = ["mhenrixon"]
  spec.email = ["mikael@mhenrixon.com"]

  spec.summary = "Rails integration for PostgreSQL aggregate functions"
  spec.description = <<~DESC
    Manage PostgreSQL aggregate functions in your Rails application with versioned migrations and schema handling.#{" "}

    This cuts the need for keeping a structure.sql
  DESC
  spec.homepage = "https://github.com/mhenrixon/pg_aggregates"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mhenrixon/pg_aggregates"
  spec.metadata["changelog_uri"] = "https://github.com/mhenrixon/pg_aggregates/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git Rakefile .gitignore .rubocop.yml db/.github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 6.1"
  spec.add_dependency "pg", ">= 1.1"
  spec.add_dependency "railties", ">= 6.1"
end
