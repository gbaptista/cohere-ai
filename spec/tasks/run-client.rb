# frozen_string_literal: true

require 'dotenv/load'

require_relative '../../ports/dsl/cohere-ai'

begin
  client = Cohere.new(
    credentials: { api_key: nil },
    options: { server_sent_events: true }
  )

  client.chat(
    { model: 'command-light', message: 'Hi!' }
  )
rescue StandardError => e
  raise "Unexpected error: #{e.class}" unless e.instance_of?(Cohere::Errors::MissingAPIKeyError)
end

client = Cohere.new(
  credentials: { api_key: ENV.fetch('COHERE_API_KEY', nil) },
  options: { server_sent_events: true }
)

result = client.chat(
  { model: 'command', stream: true, message: 'Hi!' }
) do |event, _raw|
  print event['text']
end

puts "\n#{'-' * 20}"

puts result.map { |event| event['text'] }.join
