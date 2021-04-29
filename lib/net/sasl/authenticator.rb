# frozen_string_literal: true

module Net

  module SASL

    # A base class to use for SASL authenticators.
    class Authenticator

      # Does this mechanism support sending an initial response via SASL-IR?
      def supports_initial_response?
        false
      end

      # Process a +challenge+ string from the server and return the response.
      # This method should be sent an unencoded challenge and return an
      # unencoded response. The client is responsible for receiving and decoding
      # the challenge, according the the specification of the specific protocol,
      # e.g. IMAP4 base64 encodes challenges and responses.
      #
      # A nil +challenge+ will be sent to get the initial responses, when
      # that is supported by the mechanism (#supports_initial_response? returns
      # true) and by the protocol.
      #
      # Calling #process when #done? returns true has undefined behavior: it may
      # raise an excepion, return the previous response again, or raise an
      # exception.
      def process(challenge)
        raise NotImplementedError, "implemented by SASL mechanism subclasses"
      end

      # Has the authenticator finished?  If so, then clients must not call
      # #process again.  This is so clients can know authentication is supposed
      # to have been completed, without needing to call #process and handle an
      # exception there.
      def done?
        false
      end

    end

  end
end
