# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchTests < Test::Unit::TestCase
  Search     = Net::IMAP::Search

  AndKey      = Net::IMAP::Search::AndKey
  AstringKey  = Net::IMAP::Search::AstringKey
  DateKey     = Net::IMAP::Search::DateKey
  FilterKey   = Net::IMAP::Search::FilterKey
  FlagKey     = Net::IMAP::Search::FlagKey
  KeyList     = Net::IMAP::Search::KeyList
  KeywordKey  = Net::IMAP::Search::KeywordKey
  Number64Key = Net::IMAP::Search::Number64Key
  NzNumberKey = Net::IMAP::Search::NzNumberKey
  ObjectIDKey = Net::IMAP::Search::ObjectIDKey
  OrKey       = Net::IMAP::Search::OrKey
  SeqSetKey   = Net::IMAP::Search::SeqSetKey
  UIDKey      = Net::IMAP::Search::UIDKey

  SequenceSet     = Net::IMAP::SequenceSet
  DataFormatError = Net::IMAP::DataFormatError

  test "#keys for sequence-set search keys" do
    Search.new(1..).keys => KeyList[SeqSetKey(SequenceSet("1:*"))]
    Search.new({seq: [1, -1]}).keys => KeyList[SeqSetKey(SequenceSet("1,*"))]
    Search.new(seq: [1, -1]).keys => KeyList[SeqSetKey(SequenceSet("1,*"))]
  end

  test "#keys for nullary search keys, input as strings or symbols" do
    Search.new("all").keys => KeyList[FlagKey["all"]]
    Search.new(:Flagged).keys => KeyList[FlagKey["FLAGGED"]]
  end

  test "#keys for various unary search keys" do
    Search.new({keyword: "$MDNSent", unkeyword: "foobar"}).keys => KeyList[
      KeywordKey["KEYWORD", "$MDNSent"], KeywordKey["UNKEYWORD", "foobar"],
    ]
    Search.new({emailid: "foobar"}).keys => KeyList[
      ObjectIDKey["EMAILID", "foobar"]
    ]
    Search.new({text: "отпуск"}).keys => KeyList[
      AstringKey["TEXT", "отпуск"]
    ]
    Search.new({filter: "on-the-road"}).keys => KeyList[
      FilterKey["FILTER", "on-the-road"]
    ]
    Search.new({on: "17-Feb-2024"}).keys => KeyList[
      DateKey["ON", ^(Date.parse("2024-02-17"))]
    ]
  end

  test "#keys for unary seqset-based search keys" do
    Search.new({uid: [4, -1, "123:456"]}).keys => KeyList[
      UIDKey[SequenceSet["4,123:456,*"]]
    ]
  end

  test "invalid - no criteria" do
    assert_raise DataFormatError do Search.new     end
    assert_raise DataFormatError do Search.new([]) end
    assert_raise DataFormatError do Search.new({}) end
  end

  test "#keys for multiple nullary search keys, input as strings" do
    Search.new("ALL", "Flagged", "seen").keys => KeyList[
      FlagKey["ALL"], FlagKey["Flagged"], FlagKey["seen"],
    ]
  end

  test "hash nil value passes nothing" do
    Search.new({flagged: true, seq: nil, answered: nil, text: nil}).keys => [
      FlagKey["FLAGGED"],
    ]
  end

  test "array args convert to parenthesized list (AndKey)" do
    Search.new(:flagged, [{seq: 123}, :seen], {subject: ""}).keys => [
      FlagKey, AndKey[SeqSetKey, FlagKey], AstringKey,
    ]
  end

  test "creating parenthesized list (AndKey)" do
    Search.new(:flagged, [{seq: 123}, :seen], {subject: ""}).keys => [
      FlagKey, AndKey[SeqSetKey, FlagKey], AstringKey,
    ]
    Search.new(flagged: true, and: [{seq: 123}, :seen], subject: "").keys => [
      FlagKey, AndKey[SeqSetKey, FlagKey], AstringKey,
    ]
    Search.new(flagged: true, and: {seq: 123, seen: true}).keys => [
      FlagKey, AndKey[SeqSetKey, FlagKey],
    ]
  end

  class KeyListTests < Test::Unit::TestCase
    test "for sequence-set search keys" do
      KeyList[1..].keys     => [SeqSetKey(SequenceSet("1:*"))]
      KeyList[Set[5, 6, 7]] => KeyList[SeqSetKey(SequenceSet("5:7"))]
      KeyList[seq: [1, -1]] => KeyList[SeqSetKey(SequenceSet("1,*"))]
    end

    test "for nullary search keys, input as strings or symbols" do
      KeyList["all"].keys => [FlagKey["all"]]
      KeyList["FLAGGED"]  => KeyList[FlagKey["FLAGGED"]]
      KeyList["Seen"]     => KeyList[FlagKey["Seen"]]
      KeyList[:Answered]  => KeyList[FlagKey["ANSWERED"]]
    end

    test "hash entries with true value passes only the key" do
      KeyList[{flagged: true, answered: true, seen: true}] => KeyList[
        FlagKey["FLAGGED"], FlagKey["ANSWERED"], FlagKey["SEEN"],
      ]
    end

    test "hash entries with false value passes only the UN-key" do
      KeyList[{flagged: false, answered: false, seen: false}] => KeyList[
        FlagKey["UNFLAGGED"], FlagKey["UNANSWERED"], FlagKey["UNSEEN"],
      ]
    end

    test "hash nil value passes nothing" do
      KeyList[{flagged: true, seq: nil, answered: nil, text: nil}] => [
        FlagKey["FLAGGED"],
      ]
    end

    test "hash entries for unary search keys" do
      KeyList[{text: "отпуск"}] => KeyList[AstringKey["TEXT", "отпуск"]]
      KeyList[{on: "17-Feb-2024"}] => KeyList[
        DateKey["ON", ^(Date.parse("2024-02-17"))]
      ]
    end

    test "for multiple search keys, input as strings" do
      KeyList["ALL", "56:78,*", "seen"] => KeyList[
        FlagKey["ALL"], SeqSetKey[SequenceSet["56:78,*"]], FlagKey["seen"],
      ]
    end

    test "invalid - no criteria" do
      assert_raise ArgumentError   do KeyList.new     end
      assert_raise DataFormatError do KeyList[]       end
      assert_raise DataFormatError do KeyList[nil]    end
      assert_raise DataFormatError do KeyList.new([]) end
      assert_raise DataFormatError do KeyList.new({}) end
    end

    test "invalid - bad criteria" do
      assert_raise TypeError do KeyList[{123 => false}] end
    end
  end

  class AndKeyTests < Test::Unit::TestCase
    test "#keys for one or more search keys" do
      AndKey[123, 555] => AndKey[SeqSetKey[SequenceSet["123,555"]]]
      AndKey["ALL", "56:78,*", "seen"] => AndKey[
        FlagKey["ALL"], SeqSetKey[SequenceSet["56:78,*"]], FlagKey["seen"],
      ]
    end

    test "invalid - no criteria" do
      assert_raise ArgumentError   do AndKey.new     end
      assert_raise DataFormatError do AndKey[]       end
      assert_raise DataFormatError do AndKey[nil]    end
      assert_raise DataFormatError do AndKey.new([]) end
      assert_raise DataFormatError do AndKey.new({}) end
    end
  end

  class OrKeyTests < Test::Unit::TestCase
    test "#keys for one or more search keys" do
      OrKey[123, 555] => OrKey[SeqSetKey[SequenceSet["123,555"]]]
      OrKey["ALL", "56:78,*", "seen"] => OrKey[
        FlagKey["ALL"], SeqSetKey[SequenceSet["56:78,*"]], FlagKey["seen"],
      ]
    end

    test "invalid - no criteria" do
      assert_raise ArgumentError   do OrKey.new     end
      assert_raise DataFormatError do OrKey[]       end
      assert_raise DataFormatError do OrKey[nil]    end
      assert_raise DataFormatError do OrKey.new([]) end
      assert_raise DataFormatError do OrKey.new({}) end
    end
  end

  class SeqSetKeyTests < Test::Unit::TestCase
    test "#seqset" do
      assert_equal SequenceSet["123:456,55,9"], SeqSetKey["123:456,55,9"].seqset
      assert_equal SequenceSet["123456"],       SeqSetKey[123_456].seqset
      SeqSetKey[123_456]    => SeqSetKey[seqset: SequenceSet["123456"]]
      SeqSetKey[[1..3, 45]] => SeqSetKey[SequenceSet["1:3,45"]]
      SeqSetKey[:*]         => SeqSetKey[SequenceSet["*"]]
      SeqSetKey[?*]         => SeqSetKey[SequenceSet["*"]]
      SeqSetKey[-1]         => SeqSetKey[SequenceSet["*"]]
      SeqSetKey[987..]      => SeqSetKey[SequenceSet["987:*"]]
    end

    test "#seqset must be valid" do
      assert_raise ArgumentError   do SeqSetKey[] end
      assert_raise ArgumentError   do SeqSetKey[1, 2, 3] end
      assert_raise DataFormatError do SeqSetKey[0] end
      assert_raise DataFormatError do SeqSetKey[nil] end
      assert_raise DataFormatError do SeqSetKey[[]] end
      assert_raise DataFormatError do SeqSetKey[2**32] end
      assert_raise DataFormatError do SeqSetKey[-2] end
      assert_raise DataFormatError do SeqSetKey["invalid"] end
    end
  end

  class UIDKeyTests < Test::Unit::TestCase
    test "#seqset" do
      assert_equal SequenceSet["123:456,55,9"], UIDKey["123:456,55,9"].seqset
      assert_equal SequenceSet["123456"],       UIDKey[123_456].seqset
      UIDKey[123_456]    => UIDKey[seqset: SequenceSet["123456"]]
      UIDKey[[1..3, 45]] => UIDKey[SequenceSet["1:3,45"]]
      UIDKey[:*]         => UIDKey[SequenceSet["*"]]
      UIDKey[?*]         => UIDKey[SequenceSet["*"]]
      UIDKey[-1]         => UIDKey[SequenceSet["*"]]
      UIDKey[987..]      => UIDKey[SequenceSet["987:*"]]
    end

    test "#seqset must be valid" do
      assert_raise ArgumentError   do UIDKey[] end
      assert_raise ArgumentError   do UIDKey[1, 2, 3] end
      assert_raise DataFormatError do UIDKey[0] end
      assert_raise DataFormatError do UIDKey[nil] end
      assert_raise DataFormatError do UIDKey[[]] end
      assert_raise DataFormatError do UIDKey[2**32] end
      assert_raise DataFormatError do UIDKey[-2] end
      assert_raise DataFormatError do UIDKey["invalid"] end
    end
  end

  class FlagKeyTests < Test::Unit::TestCase
    test "#name string is case-preserved" do
      assert_equal "ALL", FlagKey["ALL"].name
      FlagKey["seen"]   => FlagKey["seen"]
      FlagKey["unseen"] => FlagKey[name: "unseen"]
    end

    test "#name symbol is upcased" do
      assert_equal "ALL", FlagKey[:All].name
      FlagKey[:seen]   => FlagKey["SEEN"]
    end

    test "#name must be a string or symbol" do
      assert_raise(ArgumentError) do FlagKey[] end
      assert_raise(TypeError) do FlagKey[nil] end
      assert_raise(TypeError) do FlagKey[1234] end
      assert_raise(TypeError) do FlagKey[["all"]] end
    end

    test "#name must be a valid label" do
      assert_raise(DataFormatError) do FlagKey[""] end
      assert_raise(DataFormatError) do FlagKey["1234"] end
      assert_raise(DataFormatError) do FlagKey["*"] end
      assert_raise(DataFormatError) do FlagKey['["all"]'] end
      assert_raise(DataFormatError) do FlagKey["all flagged"] end
    end

    data do FlagKey.known_names.to_h { [_1, _1] } end
    test "known keys have no warning" do |name|
      assert_warning("") do FlagKey[name.upcase] end
      assert_warning("") do FlagKey[name.downcase] end
      mixcase = name.gsub(/./) { _1.public_send(%i[upcase downcase].sample) }
      assert_warning("") do FlagKey[mixcase] end
    end

    test "unknown keys print a warning" do
      warning = /possibly invalid search key: unknown/i
      assert_warning(warning) do FlagKey["unknown"] end
    end
  end

  class KeywordKeyTests < Test::Unit::TestCase
    test "#value string" do
      KeywordKey[:keyword, "$MDNSent"] => KeywordKey["KEYWORD", "$MDNSent"]
      KeywordKey[:unkeyword, "foobar"] => KeywordKey["UNKEYWORD", "foobar"]
    end

    test "value must be a valid flag-keyword" do
      assert_raise(DataFormatError) do KeywordKey["Keyword", ""] end
      assert_raise(DataFormatError) do KeywordKey["Keyword", "no spaces"] end
      assert_raise(DataFormatError) do KeywordKey["Keyword", "(no-parens)"] end
      assert_raise(DataFormatError) do KeywordKey["Keyword", "[no-rbra]"] end
    end
  end

  class ObjectIDKeyTests < Test::Unit::TestCase
    test "#value string" do
      ObjectIDKey[:emailid,  "1234-5678"] => ObjectIDKey["EMAILID",  "1234-5678"]
      ObjectIDKey[:threadid, "1234-5678"] => ObjectIDKey["THREADID", "1234-5678"]
    end
    test "value must be a valid objectid" do
      assert_raise(DataFormatError) do ObjectIDKey[:emailid, ""] end
      assert_raise(DataFormatError) do ObjectIDKey[:emailid, "+==+"] end
    end
  end

  class FilterKeyTests < Test::Unit::TestCase
    test "#value string" do
      FilterKey[:filter,  "filter-name"] => FilterKey["FILTER",  "filter-name"]
    end
    test "value must be a valid filter-name" do
      assert_raise(DataFormatError) do FilterKey[:filter, ""] end
      assert_raise(DataFormatError) do FilterKey[:filter, "filter/name"] end
    end
  end

  class AstringKeyTests < Test::Unit::TestCase
    test "#name string is case-preserved" do
      assert_equal "Text", AstringKey["Text", ""].name
      assert_equal "bODy", AstringKey["bODy", ""].name
    end

    test "#name symbol is upcased" do
      assert_equal "TEXT", AstringKey[:text, ""].name
      assert_equal "BODY", AstringKey[:body, ""].name
    end

    data do AstringKey.known_names.to_h { [_1, _1] } end
    test "known keys have no warning" do |name|
      assert_warning("") do AstringKey[name, ""] end
    end

    test "unknown keys print a warning" do
      warning = /possibly invalid search key: unknown/i
      assert_warning(warning) do AstringKey["unknown", ""] end
    end

    test "NULL character in string raises an error" do
      assert_raise DataFormatError do AstringKey["body", "null -> \0"] end
    end
  end

  class DateKeyTests < Test::Unit::TestCase
    test "#value data" do
      DateKey[:since, "1-Feb-1994"] => DateKey[
        "SINCE", ^(Date.parse("1994-02-01"))
      ]
      DateKey[:since, Net::IMAP.decode_date("11-Apr-2009")] => DateKey[
        "SINCE", ^(Date.parse("2009-04-11"))
      ]
    end
    test "value must be a valid filter-name" do
      assert_raise(Date::Error) do DateKey[:before, ""] end
      assert_raise(Date::Error) do DateKey[:before, "2222-10-10"] end
    end

    data do DateKey.known_names.to_h { [_1, _1] } end
    test "known keys have no warning" do |name|
      assert_warning("") do DateKey[name, "11-Nov-2000"] end
    end

    test "unknown keys print a warning" do
      warning = /possibly invalid search key: unknown/i
      assert_warning(warning) do DateKey["unknown", "11-Nov-2000"] end
    end
  end

  class NumberKeyTests < Test::Unit::TestCase
    test "#value data" do
      Number64Key[:smaller,  1337] => Number64Key["SMALLER", 1337]
      Number64Key[:larger, "1994"] => Number64Key["LARGER",  1994]
      NzNumberKey[:older,    3660] => NzNumberKey["OLDER",   3660]
      NzNumberKey[:younger, "600"] => NzNumberKey["YOUNGER",  600]
    end
    test "value must be a valid number" do
      assert_raise(ArgumentError) do Number64Key[:before, ""] end
      assert_raise(ArgumentError) do NzNumberKey[:before, "2222-10-10"] end
    end

    data do NzNumberKey.known_names.to_h { [_1, _1] } end
    test "nz-number known keys have no warning" do |name|
      assert_warning("") do NzNumberKey[name, "11"] end
    end

    data do Number64Key.known_names.to_h { [_1, _1] } end
    test "number64 known keys have no warning" do |name|
      assert_warning("") do Number64Key[name, "11"] end
    end

    test "unknown keys print a warning" do
      warning = /possibly invalid search key: unknown/i
      assert_warning(warning) do Number64Key["unknown", 9999] end
      assert_warning(warning) do NzNumberKey["unknown", 9999] end
    end
  end

end
