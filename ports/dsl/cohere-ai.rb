# frozen_string_literal: true

require_relative '../../static/gem'
require_relative '../../controllers/client'

module Cohere
  def self.new(...)
    Controllers::Client.new(...)
  end

  def self.version
    Cohere::GEM[:version]
  end
end
