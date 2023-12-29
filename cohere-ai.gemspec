# frozen_string_literal: true

require_relative 'static/gem'

Gem::Specification.new do |spec|
  spec.name    = Cohere::GEM[:name]
  spec.version = Cohere::GEM[:version]
  spec.authors = [Cohere::GEM[:author]]

  spec.summary = Cohere::GEM[:summary]
  spec.description = Cohere::GEM[:description]

  spec.homepage = Cohere::GEM[:github]

  spec.license = Cohere::GEM[:license]

  spec.required_ruby_version = Gem::Requirement.new(">= #{Cohere::GEM[:ruby]}")

  spec.metadata['allowed_push_host'] = Cohere::GEM[:gem_server]

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = Cohere::GEM[:github]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{\A(?:test|spec|features)/})
    end
  end

  spec.require_paths = ['ports/dsl']

  spec.add_dependency 'faraday', '~> 2.8', '>= 2.8.1'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
