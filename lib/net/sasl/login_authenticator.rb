# frozen_string_literal: true

module Net

  module SASL

    # Authenticator for the "+LOGIN+" SASL mechanism.
    #
    # +LOGIN+ authentication sends the password in cleartext.
    # RFC3501[https://tools.ietf.org/html/rfc3501] encourages servers to disable
    # cleartext authentication until after TLS has been negotiated.
    # RFC8314[https://tools.ietf.org/html/rfc8314] recommends TLS version 1.2 or
    # greater be used for all traffic, and deprecate cleartext access ASAP.  +LOGIN+
    # can be secured by TLS encryption.
    #
    # == Deprecated
    #
    # The {SASL mechanisms registry}[https://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml]
    # marks "LOGIN" as obsoleted in favor of "PLAIN".  It is included here for
    # compatibility with existing servers.  See
    # draft-murchison-sasl-login[https://www.iana.org/go/draft-murchison-sasl-login]
    # for both specification and deprecation.
    class LoginAuthenticator

      attr_reader :username, :password

      # Provide the +username+ and +password+ credentials for authentication.
      #
      # This should generally be instantiated via Net::SASL.authenticator.
      def initialize(username, password)
        @username = username
        @password = password
        @state = STATE_USER
      end

      # returns the SASL response for +LOGIN+
      def process(data)
        case @state
        when STATE_USER
          @state = STATE_PASSWORD
          @username
        when STATE_PASSWORD
          @state = STATE_DONE
          @password
        end
      end

      # Returns true after sending the username and password.
      def done?
        @state == STATE_DONE
      end

      STATE_USER = :USER
      STATE_PASSWORD = :PASSWORD
      STATE_DONE = :DONE

      private_constant :STATE_USER, :STATE_PASSWORD

    end
  end
end
