# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchProgramTests < Test::Unit::TestCase

  # test ":not hash criteria modifies a nested search key" do
  #   assert_search_args(
  #     ["FLAGGED", "SINCE", "1-Feb-1994", "NOT", %w[FROM Smith]],
  #     {flagged: true, since: "1-Feb-1994", not: {from: "Smith"}}
  #   )
  # end

  # test ":or hash criteria joins an array of search keys" do
  #   assert_search_args(
  #     ["OR", %w[foo bar], "baz"],
  #     {or: [%w[foo bar], "baz"]}
  #   )
  #   assert_search_args(
  #     ["OR", "foo", ["OR", "bar", %w[OR baz quux]]],
  #     {or: %w[foo bar baz quux]}
  #   )
  # end

end
