# frozen_string_literal: true

require 'faraday'
require 'json'

require_relative '../ports/dsl/cohere-ai/errors'

module Cohere
  module Controllers
    class Client
      DEFAULT_ADDRESS = 'https://api.cohere.ai'

      ALLOWED_REQUEST_OPTIONS = %i[timeout open_timeout read_timeout write_timeout].freeze

      def initialize(config)
        @api_key = config.dig(:credentials, :api_key)
        @server_sent_events = config.dig(:options, :server_sent_events)

        @address = if config[:credentials][:address].nil? || config[:credentials][:address].to_s.strip.empty?
                     "#{DEFAULT_ADDRESS}/"
                   else
                     "#{config[:credentials][:address].to_s.sub(%r{/$}, '')}/"
                   end

        if @api_key.nil? && @address == "#{DEFAULT_ADDRESS}/"
          raise MissingAPIKeyError, 'Missing API Key, which is required.'
        end

        @request_options = config.dig(:options, :connection, :request)

        @request_options = if @request_options.is_a?(Hash)
                             @request_options.select do |key, _|
                               ALLOWED_REQUEST_OPTIONS.include?(key)
                             end
                           else
                             {}
                           end
      end

      def chat(payload, server_sent_events: nil, &callback)
        server_sent_events = false if payload[:stream] != true
        request('v1/chat', payload, server_sent_events:, &callback)
      end

      def generate(payload, server_sent_events: nil, &callback)
        server_sent_events = false if payload[:stream] != true
        request('v1/generate', payload, server_sent_events:, &callback)
      end

      def embed(payload, _server_sent_events: nil, &callback)
        request('v1/embed', payload, server_sent_events: false, &callback)
      end

      def rerank(payload, _server_sent_events: nil, &callback)
        request('v1/rerank', payload, server_sent_events: false, &callback)
      end

      def classify(payload, _server_sent_events: nil, &callback)
        request('v1/classify', payload, server_sent_events: false, &callback)
      end

      def detect_language(payload, _server_sent_events: nil, &callback)
        request('v1/detect-language', payload, server_sent_events: false, &callback)
      end

      def summarize(payload, _server_sent_events: nil, &callback)
        request('v1/summarize', payload, server_sent_events: false, &callback)
      end

      def tokenize(payload, _server_sent_events: nil, &callback)
        request('v1/tokenize', payload, server_sent_events: false, &callback)
      end

      def detokenize(payload, _server_sent_events: nil, &callback)
        request('v1/detokenize', payload, server_sent_events: false, &callback)
      end

      def request(path, payload = nil, server_sent_events: nil, request_method: 'POST', &callback)
        server_sent_events_enabled = server_sent_events.nil? ? @server_sent_events : server_sent_events
        url = "#{@address}#{path}"

        if !callback.nil? && !server_sent_events_enabled
          raise BlockWithoutServerSentEventsError,
                'You are trying to use a block without Server Sent Events (SSE) enabled.'
        end

        results = []

        method_to_call = request_method.to_s.strip.downcase.to_sym

        partial_json = ''

        response = Faraday.new(request: @request_options) do |faraday|
          faraday.response :raise_error
        end.send(method_to_call) do |request|
          request.url url
          request.headers['Content-Type'] = 'application/json'

          request.headers['Authorization'] = "Bearer #{@api_key}" unless @api_key.nil?

          request.body = payload.to_json unless payload.nil?

          if server_sent_events_enabled
            request.options.on_data = proc do |chunk, bytes, env|
              if env && env.status != 200
                raise_error = Faraday::Response::RaiseError.new
                raise_error.on_complete(env.merge(body: chunk))
              end

              partial_json += chunk

              parsed_json = safe_parse_json(partial_json)

              if parsed_json
                result = { event: parsed_json, raw: { chunk:, bytes:, env: } }

                callback.call(result[:event], result[:raw]) unless callback.nil?

                results << result

                partial_json = ''
              end
            end
          end
        end

        return safe_parse_json(response.body) unless server_sent_events_enabled

        raise IncompleteJSONReceivedError, partial_json if partial_json != ''

        results.map { |result| result[:event] }
      rescue Faraday::ServerError => e
        raise RequestError.new(e.message, request: e, payload:)
      end

      def safe_parse_json(raw)
        raw.to_s.lstrip.start_with?('{', '[') ? JSON.parse(raw) : nil
      rescue JSON::ParserError
        nil
      end
    end
  end
end
