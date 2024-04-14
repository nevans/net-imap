# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchTests < Test::Unit::TestCase
  Search     = Net::IMAP::Search

  KeysHash    = Net::IMAP::Search::KeyList::KeysHash
  KeyTypes    = Net::IMAP::Search::KeyTypes

  # TODO: convert to new style (currently under KeyTypes)
  AndKey      = Net::IMAP::Search::AndKey
  KeyList     = Net::IMAP::Search::KeyList

  SequenceSet     = Net::IMAP::SequenceSet
  DataFormatError = Net::IMAP::DataFormatError

  test "#keys for sequence-set search keys" do
    Search.new(1..).keys            => KeyList[KeyTypes::Seq(SequenceSet("1:*"))]
    Search.new({seq: [1, -1]}).keys => KeyList[KeyTypes::Seq(SequenceSet("1,*"))]
    Search.new(seq: [1, -1]).keys   => KeyList[KeyTypes::Seq(SequenceSet("1,*"))]
  end

  test "#keys for nullary search keys, input as strings or symbols" do
    Search.new("all").keys => KeyList[KeyTypes::All[]]
    Search.new(:Flagged).keys => KeyList[KeyTypes::Flagged]
  end

  test "#keys for various unary search keys" do
    Search.new({keyword: "$MDNSent", unkeyword: "foobar"}).keys => KeyList[
      KeyTypes::Keyword["$MDNSent"], KeyTypes::Unkeyword["foobar"],
    ]
    Search.new({emailid: "foobar"}).keys => KeyList[
      KeyTypes::EmailID["foobar"]
    ]
    Search.new({text: "отпуск"}).keys => KeyList[
      KeyTypes::Text["отпуск"]
    ]
    Search.new({filter: "on-the-road"}).keys => KeyList[
      KeyTypes::Filter["on-the-road"]
    ]
    Search.new({on: "17-Feb-2024"}).keys => KeyList[
      KeyTypes::On[^(Date.parse("2024-02-17"))]
    ]
  end

  test "#keys for unary seqset-based search keys" do
    Search.new({uid: [4, -1, "123:456"]}).keys => KeyList[
      KeyTypes::UID[SequenceSet["4,123:456,*"]]
    ]
  end

  test "invalid - no criteria" do
    assert_raise DataFormatError do Search.new     end
    assert_raise DataFormatError do Search.new([]) end
    assert_raise DataFormatError do Search.new({}) end
  end

  test "#keys for multiple nullary search keys, input as strings" do
    Search.new("ALL", "Flagged", "seen").keys => KeyList[
      KeyTypes::All, KeyTypes::Flagged, KeyTypes::Seen,
    ]
  end

  test "hash nil values are dropped" do
    Search.new({flagged: true, seq: nil, answered: nil, text: nil}).keys => [
      KeyTypes::Flagged
    ]
  end

  test "array args convert to parenthesized list (AndKey)" do
    Search.new(:flagged, [{seq: 123}, :seen], {subject: ""}).keys => [
      KeyTypes::Flagged,
      AndKey[KeyTypes::Seq, KeyTypes::Seen],
      KeyTypes::Subject
    ]
  end

  test "creating parenthesized list (AndKey)" do
    Search.new(:flagged, [{seq: 123}, :seen], {subject: ""}).keys => [
      KeyTypes::Flagged, AndKey[KeyTypes::Seq, KeyTypes::Seen],
      KeyTypes::Subject
    ]
    Search.new(flagged: true, and: [{seq: 123}, :seen], subject: "").keys => [
      KeyTypes::Flagged, AndKey[KeyTypes::Seq, KeyTypes::Seen],
      KeyTypes::Subject
    ]
    Search.new(flagged: true, and: {seq: 123, seen: true}).keys => [
      KeyTypes::Flagged, AndKey[KeyTypes::Seq, KeyTypes::Seen]
    ]
  end

  class KeyListTests < Test::Unit::TestCase
    test "for sequence-set search keys" do
      KeyList[1..].keys     => [KeyTypes::Seq(SequenceSet("1:*"))]
      KeyList[Set[5, 6, 7]] => KeyList[KeyTypes::Seq(SequenceSet("5:7"))]
      KeyList[seq: [1, -1]] => KeyList[KeyTypes::Seq(SequenceSet("1,*"))]
    end

    test "for nullary search keys, input as strings or symbols" do
      KeyList["all"].keys => [KeyTypes::All]
      KeyList["FLAGGED"]  => KeyList[KeyTypes::Flagged]
      KeyList["Seen"]     => KeyList[KeyTypes::Seen]
      KeyList[:Answered]  => KeyList[KeyTypes::Answered]
    end

    test "hash entries with true value passes only the key" do
      KeyList[{flagged: true, answered: true, seen: true}] => KeyList[
        KeyTypes::Flagged, KeyTypes::Answered, KeyTypes::Seen
      ]
    end

    test "hash entries with false value passes only the UN-key" do
      KeyList[{flagged: false, answered: false, seen: false}] => KeyList[
        KeyTypes::Unflagged, KeyTypes::Unanswered, KeyTypes::Unseen,
      ]
    end

    test "hash nil value passes nothing" do
      KeyList[{flagged: true, seq: nil, answered: nil, text: nil}] => [
        KeyTypes::Flagged,
      ]
    end

    test "hash entries for unary search keys" do
      KeyList[{text: "отпуск"}] => KeyList[KeyTypes::Text["отпуск"]]
      KeyList[{on: "17-Feb-2024"}] => KeyList[
        KeyTypes::On[^(Date.parse("2024-02-17"))]
      ]
    end

    test "for multiple search keys, input as strings" do
      KeyList["ALL", "56:78,*", "seen"] => KeyList[
        KeyTypes::All, KeyTypes::Seq[SequenceSet["56:78,*"]], KeyTypes::Seen,
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

  class KeysHashTests < Test::Unit::TestCase
    test "hash entries with true value passes only the key" do
      input = {all: true, flagged: true, answered: true, seen: true}
      keys_hash = KeysHash[input]
      assert_equal input, keys_hash.compacted
      keys_hash.inputs => [:all, :flagged, :answered, :seen]
      keys_hash.keys => [
        KeyTypes::All,
        KeyTypes::Flagged,
        KeyTypes::Answered,
        KeyTypes::Seen,
      ]
    end

    test "hash entries with false value passes only the UN-key" do
      input = {flagged: false, answered: false, seen: false}
      keys_hash = KeysHash[input]
      keys_hash.compacted => ^input
      keys_hash.inputs => [:unflagged, :unanswered, :unseen]
      keys_hash.keys => [
        KeyTypes::Unflagged, KeyTypes::Unanswered, KeyTypes::Unseen
      ]
    end

    test "hash nil value passes nothing" do
      input = {flagged: true, seq: nil, answered: nil, text: nil}
      keys_hash = KeysHash[input]
      keys_hash.compacted => {flagged: true, **nil}
      keys_hash.inputs    => [:flagged]
      keys_hash.keys      => [KeyTypes::Flagged]
    end

    test "hash entries for unary search keys" do
      input = {text: "отпуск"}
      keys_hash = KeysHash[input]
      keys_hash.compacted => ^input
      keys_hash.inputs    => [[:text, "отпуск"]]
      keys_hash.keys => [KeyTypes::Text["отпуск"]]

      input = {on: "17-Feb-2024"}
      keys_hash = KeysHash[input]
      keys_hash.compacted => ^input
      keys_hash.inputs => [[:on, "17-Feb-2024"]]
      keys_hash.keys => [KeyTypes::On[^(Date.parse("2024-02-17"))]]
    end

    test "hash entries for simple nested search hashes" do
      input = {header: {"sender" => "foo", "references" => "bar"}}
      keys_hash = KeysHash[input]
      keys_hash.compacted => ^input
      keys_hash.inputs => [[:header, "sender", "foo"],
                           [:header, "references", "bar"]]
      # keys_hash.keys => [HeaderKey["sender", "foo"],
      #                    HeaderKey["references", "bar"]]
    end
  end

  class AndKeyTests < Test::Unit::TestCase
    test "#keys for one or more search keys" do
      AndKey["ALL", "56:78,*", "seen"] => AndKey[
        KeyTypes::All, KeyTypes::Seq[SequenceSet["56:78,*"]], KeyTypes::Seen,
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

end
