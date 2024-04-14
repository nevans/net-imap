# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchKeyTypesTests < Test::Unit::TestCase
  Search          = Net::IMAP::Search
  SequenceSet     = Net::IMAP::SequenceSet
  DataFormatError = Net::IMAP::DataFormatError

  include Search::KeyTypes

  # TODO: Add :and, OR, NOT, FUZZY
  # TODO: Add :any?, :all?

  input = [1, 3..5, 33, -1]
  seqset = SequenceSet[input]

  data "Seq", {
    type: Seq, input: [seqset],
    to_a: [seqset],
    to_h: {seq: seqset},
  }, keep: true

  data "UID", {
    type: UID, input: [seqset],
    to_a: ["UID", seqset],
    to_h: {uid: seqset},
  }, keep: true

  data "All", {
    type: All, input: [],
    to_a: %w[ALL],
    to_h: {all: true},
  }, keep: true

  data "SaveDateSupported", {
    type: SaveDateSupported, input: [],
    to_a: %w[SAVEDATESUPPORTED],
    to_h: {savedatesupported: true},
  }, keep: true

  data "Answered", {
    type: Answered, input: [],
    to_a: %w[ANSWERED],
    to_h: {answered: true},
  }, keep: true

  data "Deleted", {
    type: Deleted, input: [],
    to_a: %w[DELETED],
    to_h: {deleted: true},
  }, keep: true

  data "Flagged", {
    type: Flagged, input: [],
    to_a: %w[FLAGGED],
    to_h: {flagged: true},
  }, keep: true

  data "Draft", {
    type: Draft, input: [],
    to_a: %w[DRAFT],
    to_h: {draft: true},
  }, keep: true

  data "Seen", {
    type: Seen, input: [],
    to_a: %w[SEEN],
    to_h: {seen: true},
  }, keep: true

  data "Unanswered", {
    type: Unanswered, input: [],
    to_a: %w[UNANSWERED],
    to_h: {unanswered: true},
  }, keep: true

  data "Undeleted", {
    type: Undeleted, input: [],
    to_a: %w[UNDELETED],
    to_h: {undeleted: true},
  }, keep: true

  data "Undraft", {
    type: Undraft, input: [],
    to_a: %w[UNDRAFT],
    to_h: {undraft: true},
  }, keep: true

  data "Unflagged", {
    type: Unflagged, input: [],
    to_a: %w[UNFLAGGED],
    to_h: {unflagged: true},
  }, keep: true

  data "Unseen", {
    type: Unseen, input: [],
    to_a: %w[UNSEEN],
    to_h: {unseen: true},
  }, keep: true

  data "Keyword", {
    type: Keyword, input: ["$Forwarded"],
    to_h: {keyword: "$Forwarded"},
    to_a: %w[KEYWORD $Forwarded],
  }, keep: true

  data "Unkeyword", {
    type: Unkeyword, input: ["$MDNSent"],
    to_a: %w[UNKEYWORD $MDNSent],
    to_h: {unkeyword: "$MDNSent"},
  }, keep: true

  data "Filter", {
    type: Filter, input: ["on-the-road"],
    to_a: %w[FILTER on-the-road],
    to_h: {filter: "on-the-road"},
  }, keep: true

  data "EmailID", {
    type: EmailID, input: ["msg-123-abc"],
    to_a: %w[EMAILID  msg-123-abc],
    to_h: {emailid: "msg-123-abc"},
  }, keep: true

  data "ThreadID", {
    type: ThreadID, input: ["thd-abc-123"],
    to_a: %w[THREADID thd-abc-123],
    to_h: {threadid: "thd-abc-123"},
  }, keep: true

  data "From", {
    type: From, input: ["maria@example.test"],
    to_a: %w[FROM maria@example.test],
    to_h: {from: "maria@example.test"},
  }, keep: true

  data "To", {
    type: To, input: ["shugo@example.test"],
    to_a: %w[TO shugo@example.test],
    to_h: {to: "shugo@example.test"},
  }, keep: true

  data "Bcc", {
    type: Bcc, input: ["Smith"],
    to_a: %w[BCC Smith],
    to_h: {bcc: "Smith"},
  }, keep: true

  data "Cc", {
    type: Cc, input: ["Eric"],
    to_a: %w[CC Eric],
    to_h: {cc: "Eric"},
  }, keep: true

  data "Subject", {
    type: Subject, input: ["ruby news"],
    to_a: ["SUBJECT", "ruby news"],
    to_h: {subject: "ruby news"},
  }, keep: true

  data "Body", {
    type: Body, input: ["substring found in msg body"],
    to_a: ["BODY", "substring found in msg body"],
    to_h: {body: "substring found in msg body"},
  }, keep: true

  data "Text", {
    type: Text, input: ["substring found in msg text"],
    to_a: ["TEXT", "substring found in msg text"],
    to_h: {text: "substring found in msg text"},
  }, keep: true

  date = Date.parse("2024-02-17")

  data "Before", {
    type: Before, input: [date],
    to_a: ["BEFORE", date],
    to_h: {before: date},
  }, keep: true

  data "On", {
    type: On, input: [date],
    to_a: ["ON", date],
    to_h: {on: date},
  }, keep: true

  data "Since", {
    type: Since, input: [date],
    to_a: ["SINCE", date],
    to_h: {since: date},
  }, keep: true

  data "SavedBefore", {
    type: SavedBefore, input: [date],
    to_a: ["SAVEDBEFORE", date],
    to_h: {savedbefore: date},
  }, keep: true

  data "SavedOn", {
    type: SavedOn, input: [date],
    to_a: ["SAVEDON", date],
    to_h: {savedon: date},
  }, keep: true

  data "SavedSince", {
    type: SavedSince, input: [date],
    to_a: ["SAVEDSINCE", date],
    to_h: {savedsince: date},
  }, keep: true

  data "SentBefore", {
    type: SentBefore, input: [date],
    to_a: ["SENTBEFORE", date],
    to_h: {sentbefore: date},
  }, keep: true

  data "SentOn", {
    type: SentOn, input: [date],
    to_a: ["SENTON", date],
    to_h: {senton: date},
  }, keep: true

  data "SentSince", {
    type: SentSince, input: [date],
    to_a: ["SENTSINCE", date],
    to_h: {sentsince: date},
  }, keep: true

  data "Larger", {
    type: Larger, input: [123_456],
    to_a: ["LARGER", 123_456],
    to_h: {larger: 123_456},
  }, keep: true

  data "Smaller", {
    type: Smaller, input: [123_456],
    to_a: ["SMALLER", 123_456],
    to_h: {smaller: 123_456},
  }, keep: true

  data "Older", {
    type: Older, input: [123_456],
    to_a: ["OLDER", 123_456],
    to_h: {older: 123_456},
  }, keep: true

  data "Younger", {
    type: Younger, input: [123_456],
    to_a: ["YOUNGER", 123_456],
    to_h: {younger: 123_456},
  }, keep: true

  data "Header", {
    type: Header, input: ["List-ID", "ruby-lang.org"],
    to_a: %w[HEADER List-ID ruby-lang.org],
    to_h: {header: {"List-ID" => "ruby-lang.org"}},
  }, keep: true

  data "ModSeq (with single argument)", {
    type: ModSeq, input: [123_456_789],
    to_a: ["MODSEQ", 123_456_789],
    to_h: {modseq: 123_456_789},
  }, keep: true

  data "ModSeq (with metadata entry args)", {
    type: ModSeq, input: ["/flags/\\draft", "all", 620_162_338],
    to_a: ["MODSEQ", "/flags/\\draft", "all", 620_162_338],
    to_h: {modseq: {"/flags/\\draft" => {"all" => 620_162_338}}},
  }, keep: true

  data "Annotation", {
    type: Annotation, input: ["/comment", "value", "IMAP4"],
    to_a: %w[ANNOTATION /comment value IMAP4],
    to_h: {annotation: {"/comment" => {"value" => "IMAP4"}}},
  }, keep: true

  data "Or (two simple inputs)", {
    type: Or, input: ["56:78,*", "seen"],
    args: [Seq["56:78,*"], Seen[]],
    to_a: ["OR", SequenceSet["56:78,*"], "SEEN"],
    to_h: {or: [{seq: SequenceSet["56:78,*"]}, {seen: true}]},
  }, keep: true

  data "Or (two hash inputs)", {
    type: Or, input: [{subject: "topic"}, {from: "me", to: "you"}],
    args: [Subject["topic"], Search::AndKey[From["me"], To["you"]]],
    to_a: ["OR", "SUBJECT", "topic", %w[FROM me TO you]],
    to_h: {or: [{subject: "topic"}, {from: "me", to: "you"}]},
  }, keep: true

  data "Or (more than two inputs)", {
    type: Or,
    input: ["56:78,*",
            %w[seen flagged],
            {subject: "topic"},
            {from: "me", to: "you"}],
    args: [Seq["56:78,*"],
           Or[Search::AndKey[Seen[], Flagged[]],
              Or[Subject["topic"],
                 Search::AndKey[From["me"], To["you"]] ] ] ],
    to_a: ["OR", SequenceSet["56:78,*"],
           "OR", %w[SEEN FLAGGED],
           "OR", "SUBJECT", "topic", %w[FROM me TO you]],
    to_h: {or: [ {seq: SequenceSet["56:78,*"]},
                 {or: [{seen: true, flagged: true},
                       {or: [ {subject: "topic"},
                              {from: "me", to: "you"} ]} ]} ]},
  }, keep: true

  # data "Or (nested)", {
  #   type: Or, input: ["56:78,*", "seen", {subject: "foo"}],
  #   to_a: %w[OR 56:78,* OR SEEN SUBJECT foo],
  #   to_h: {or: ["56:76,*", {or: ["seen", {subject: "foo"}]}]},
  # }, keep: true

  # test "array elements are not flattened or combined" do
  #   OrKey[123, 555] => OrKey[
  #     KeyTypes::Seq[SequenceSet["123"]], KeyTypes::Seq[SequenceSet["555"]]
  #   ]
  #   OrKey["ALL", "56:78,*", "seen"] => OrKey[
  #     KeyTypes::All, KeyTypes::Seq[SequenceSet["56:78,*"]], KeyTypes::Seen
  #   ]
  # end

  data "X-GM-RAW", {
    type: XGmRaw, input: ["has:attachment in:unread"],
    to_a: ["X-GM-RAW", "has:attachment in:unread"],
    to_h: {x_gm_raw: "has:attachment in:unread"},
  }, keep: true

  data "X-GM-MSGID", {
    type: XGmMsgID, input: [1278455344230334865],
    to_a: ["X-GM-MSGID", 1278455344230334865],
    to_h: {x_gm_msgid: 1278455344230334865},
  }, keep: true

  data "X-GM-THRID", {
    type: XGmThrID, input: [1266894439832287888],
    to_a: ["X-GM-THRID", 1266894439832287888],
    to_h: {x_gm_thrid: 1266894439832287888},
  }, keep: true

  data "Generic (no args)", {
    type: Generic, input: ["Abc"],
    args: [],
    to_a: ["Abc"],
    to_h: {"Abc" => true},
  }, keep: true

  data "Generic (single arg)", {
    type: Generic, input: ["abc", 123],
    args: [123],
    to_a: ["abc", 123],
    to_h: {"abc" => 123},
  }, keep: true

  data "Generic (multiple args)", {
    type: Generic, input: ["a", "b", "c", 123],
    args: ["b", "c", 123],
    to_a: ["a", "b", "c", 123],
    to_h: {"a" => {"b" => {"c" => 123}}},
  }, keep: true

  test "#to_a" do |data|
    data => type:, input:, to_a: expected
    assert_equal expected, type[*input].to_a
  end

  test "#to_h" do
    data => type:, input:, to_h: expected
    assert_equal expected, type[*input].to_h
  end

  test "can be loaded by hash" do |data|
    data => type:, input:, to_h: hash
    args = data[:args] || input
    Search::KeyList[hash] => [search_key]
    assert_equal type, search_key.class
    assert_equal args, search_key.args
    assert_equal hash, search_key.to_h
  end

  class TypeCoercionTests < Test::Unit::TestCase
    include Search::KeyTypes

    test "Seq converts to SequenceSet" do
      assert_equal SequenceSet["123:456,55,9"], Seq["123:456,55,9"].seq
      assert_equal SequenceSet["123456"],       Seq[123_456].seq
      Seq[123_456]    => Seq[seq: SequenceSet["123456"]]
      Seq[[1..3, 45]] => Seq[SequenceSet["1:3,45"]]
      Seq[:*]         => Seq[SequenceSet["*"]]
      Seq[?*]         => Seq[SequenceSet["*"]]
      Seq[-1]         => Seq[SequenceSet["*"]]
      Seq[987..]      => Seq[SequenceSet["987:*"]]
    end

    test "Seq must be valid SequenceSet input" do
      assert_raise ArgumentError   do Seq[] end
      assert_raise ArgumentError   do Seq[1, 2, 3] end
      assert_raise DataFormatError do Seq[0] end
      assert_raise DataFormatError do Seq[nil] end
      assert_raise DataFormatError do Seq[[]] end
      assert_raise DataFormatError do Seq[2**32] end
      assert_raise DataFormatError do Seq[-2] end
      assert_raise DataFormatError do Seq["invalid"] end
    end

    test "UID converts to SequenceSet" do
      assert_equal SequenceSet["123:456,55,9"], UID["123:456,55,9"].uid
      assert_equal SequenceSet["123456"],       UID[123_456].uid
      UID[123_456]    => UID[uid: SequenceSet["123456"]]
      UID[[1..3, 45]] => UID[SequenceSet["1:3,45"]]
      UID[:*]         => UID[SequenceSet["*"]]
      UID[?*]         => UID[SequenceSet["*"]]
      UID[-1]         => UID[SequenceSet["*"]]
      UID[987..]      => UID[SequenceSet["987:*"]]
    end

    test "UID must be valid SequenceSet input" do
      assert_raise ArgumentError   do UID[] end
      assert_raise ArgumentError   do UID[1, 2, 3] end
      assert_raise DataFormatError do UID[0] end
      assert_raise DataFormatError do UID[nil] end
      assert_raise DataFormatError do UID[[]] end
      assert_raise DataFormatError do UID[2**32] end
      assert_raise DataFormatError do UID[-2] end
      assert_raise DataFormatError do UID["invalid"] end
    end

    test "Keyword must be a valid flag-keyword" do
      assert_raise DataFormatError do Keyword[""] end
      assert_raise DataFormatError do Keyword["no spaces"] end
      assert_raise DataFormatError do Keyword["(no-parens)"] end
      assert_raise DataFormatError do Keyword["[no-rbra]"] end
    end

    test "NULL character in string raises an error" do
      assert_raise DataFormatError do From["null -> \0"] end
      assert_raise DataFormatError do To["null -> \0"] end
      assert_raise DataFormatError do Cc["null -> \0"] end
      assert_raise DataFormatError do Bcc["null -> \0"] end
      assert_raise DataFormatError do Subject["null -> \0"] end
      assert_raise DataFormatError do Body["null -> \0"] end
      assert_raise DataFormatError do Text["null -> \0"] end
      assert_raise DataFormatError do Header["List-ID", "null -> \0"] end
    end

    test "EmailID/ThreadID must be a valid objectid" do
      assert_raise(DataFormatError) do EmailID[""] end
      assert_raise(DataFormatError) do ThreadID["+==+"] end
    end

    test "Filter must be a valid filter-name" do
      assert_raise(DataFormatError) do Filter[""] end
      assert_raise(DataFormatError) do Filter["filter/name"] end
    end

    test "date values convert Time objects (#to_date)" do
      date = Date.parse("2024-02-17")
      time = Time.parse("2024-02-17T13:00:00")
      assert_equal ["BEFORE", date], Before[time].to_a
    end

    test "date values convert IMAP formatted date strings" do
      assert_equal ["SINCE",  Date.new(2024, 2, 17)], Since["17-Feb-2024"].to_a
      assert_equal ["SENTON", Date.new(2024, 4, 7)],  SentOn["7-Apr-2024"].to_a
    end

    test "date values must be a valid IMAP formatted date string" do
      assert_raise(Date::Error) do Before[""] end
      assert_raise(Date::Error) do SavedOn["2222-10-10"] end
    end

    test "number64 must be a valid IMAP number (uint63)" do
      assert_raise(ArgumentError)   do Larger["NaN"] end
      assert_raise(DataFormatError) do Larger[-1] end
      assert_raise(DataFormatError) do Smaller[2**63] end
      assert_raise(DataFormatError) do ModSeq[2**63] end
    end

    test "nznumber must be a valid IMAP number (uint32, except 0)" do
      assert_raise(ArgumentError)   do Older["NaN"] end
      assert_raise(DataFormatError) do Older[-1] end
      assert_raise(DataFormatError) do Younger[0] end
      assert_raise(DataFormatError) do Younger[2**32] end
    end

    test "Generic#name must be a valid label" do
      assert_raise(ArgumentError)   do Generic[] end
      assert_raise(DataFormatError) do Generic[""] end
      assert_raise(DataFormatError) do Generic["no spaces"] end
      assert_raise(DataFormatError) do Generic["exclamation!"] end
      assert_raise(DataFormatError) do Generic["question?"] end
    end

    test "OR with too few criteria" do
      assert_raise ArgumentError do Or[]       end
      assert_raise ArgumentError do Or[nil]    end
      assert_raise ArgumentError do Or[[]] end
      assert_raise DataFormatError do Or[{}] end
    end
  end

end
