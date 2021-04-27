# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SASLAuthenticatorsTest < Test::Unit::TestCase

  def plain(*args, **kwargs)
    Net::SASL.authenticator("PLAIN", *args, **kwargs)
  end

  def test_plain
    assert_equal("\0authc\0passwd",
                 plain("authc", "passwd").process(nil))
    assert_equal("authz\0user\0pass",
                 plain("user", "pass", "authz").process(nil))
  end

  def test_plain_no_null_chars
    assert_raise(ArgumentError) { plain("bad\0user", "pass") }
    assert_raise(ArgumentError) { plain("user", "bad\0pass") }
    assert_raise(ArgumentError) { plain("u", "p", "bad\0authz") }
  end

end
