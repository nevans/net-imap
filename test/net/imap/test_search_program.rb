# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchProgramTests < Test::Unit::TestCase
  SearchProgram   = Net::IMAP::SearchProgram

  DataFormatError = Net::IMAP::DataFormatError
  RawData         = Net::IMAP::RawData
  SequenceSet     = Net::IMAP::SequenceSet

  test "invalid - no criteria" do
    assert_raise DataFormatError do SearchProgram.new end
    assert_raise DataFormatError do SearchProgram.new charset: "UTF-8" end
  end

  test "invalid - empty" do
    assert_raise DataFormatError do SearchProgram.new [] end
    assert_raise DataFormatError do SearchProgram.new({}) end
  end

  # TODO
  test ".parse(string) => RawData, with warning" do
    assert_deprecated_warning(/Raw .*string .*deprecated.* Use.*RawData/) do
      assert_parse_args [RawData.new("foo bar")], "foo bar"
    end
  end

  # TODO
  test ".new(parse: string) => RawData, with warning" do
    assert_deprecated_warning(/Raw .*string .*deprecated.* Use.*RawData/) do
      assert_search_args [RawData.new("foo bar")], parse: "foo bar"
    end
    assert_deprecated_warning(/Raw .*string .*deprecated.* Use.*RawData/) do
      assert_search_args [RawData.new("foo bar")], {parse: "foo bar"}
    end
  end

  test "RawData is untranslated, without warning" do
    assert_warning("") do
      assert_search_args [RawData.new("foo bar")], RawData.new("foo bar")
    end
  end

  test "{raw: data] is untranslated, without warning" do
    assert_warning("") do
      assert_search_args [RawData.new("foo bar")], {raw: "foo bar"}
      assert_search_args [RawData.new("foo bar")], raw: "foo bar"
    end
  end

  # SequenceSet#send_data handles the rest
  test "sequence set representations are converted" do
    assert_search_args [SequenceSet["2,5:8,12"]], "2,5:8,12"
    assert_search_args [SequenceSet["2,5:8,12"]], [2, "5:8", 12]
    assert_search_args [SequenceSet["2,5:8,12"]], [2, 5..8, 12]
    assert_search_args [SequenceSet["2,5:8,12"]], seq: [2, 5..8, 12]
  end

  # Literal vs quoted vs atom is handled by send_data
  test "flat array of (most) strings is untranslated" do
    assert_parse_args(
      %w[FLAGGED SINCE 1-Feb-1994 NOT FROM Smith],
      %w[FLAGGED SINCE 1-Feb-1994 NOT FROM Smith]
    )
    assert_parse_args(%w[TEXT отпуск], %w[TEXT отпуск])
  end

  # Dates are formatted by send_data
  test "dates in the criteria array are untranslated" do
    assert_parse_args(
      ["FLAGGED", "SINCE", Date.parse("1994-02-01"), "NOT", "FROM", "Smith"],
      ["FLAGGED", "SINCE", Date.parse("1994-02-01"), "NOT", "FROM", "Smith"]
    )
  end

  test "sequence sets in the criteria array are converted" do
    assert_parse_args ["uid", SequenceSet["1:6"]], ["uid", [1, 2, 3, 4, 5, 6]]
    assert_parse_args ["uid", SequenceSet["1:6"]], ["uid", 1..6]
  end

  test "nested arrays are recursively translated" do
    assert_parse_args(["or", ["uid", SequenceSet["1:6"]], "flagged"],
                      ["or", ["uid", [1, 2, 3, 4, 5, 6]], "flagged"])
    assert_parse_args(["foo", ["bar", [RawData.new('"baz"')]]],
                      ["foo", ["bar", [RawData.new('"baz"')]]])
  end

  test "criteria can be passed in a hash" do
    assert_search_args %w[SINCE 1-Feb-1994], {since: "1-Feb-1994"}
    assert_search_args(%w[TEXT отпуск], {text: "отпуск"})
  end

  test "criteria hash true value passes only the key" do
    assert_search_args(%w[FLAGGED ANSWERED SEEN],
                       {flagged: true, answered: true, seen: true})
  end

  test "criteria hash false value passes only the UN-key" do
    assert_search_args(%w[UNFLAGGED UNANSWERED UNSEEN],
                       {flagged: false, answered: false, seen: false})
  end

  test "criteria hash nil value passes nothing" do
    assert_search_args(%w[FLAGGED],
                       {flagged: true, answered: nil, seen: nil})
  end

  test ":not hash criteria modifies a nested search key" do
    assert_search_args(
      ["FLAGGED", "SINCE", "1-Feb-1994", "NOT", %w[FROM Smith]],
      {flagged: true, since: "1-Feb-1994", not: {from: "Smith"}}
    )
  end

  test ":or hash criteria joins an array of search keys" do
    assert_search_args(
      ["OR", %w[foo bar], "baz"],
      {or: [%w[foo bar], "baz"]}
    )
    assert_search_args(
      ["OR", "foo", ["OR", "bar", %w[OR baz quux]]],
      {or: %w[foo bar baz quux]}
    )
  end

  def assert_parse_args(expected, ...)
    search_program = SearchProgram.parse(...)
    assert_equal expected, search_program.search_arguments
  end

  def assert_search_keys(expected, ...)
    search_program = SearchProgram.new(...)
    assert_equal expected, search_program.search_keys
  end

  def assert_search_args(expected, ...)
    search_program = SearchProgram.new(...)
    assert_equal expected, search_program.search_arguments
  end

end
