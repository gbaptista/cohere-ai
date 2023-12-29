# frozen_string_literal: true

module Cohere
  module Errors
    class CohereError < StandardError
      def initialize(message = nil)
        super(message)
      end
    end

    class MissingAPIKeyError < CohereError; end
    class BlockWithoutServerSentEventsError < CohereError; end

    class RequestError < CohereError
      attr_reader :request, :payload

      def initialize(message = nil, request: nil, payload: nil)
        @request = request
        @payload = payload

        super(message)
      end
    end
  end
end
