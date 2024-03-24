# frozen_string_literal: true

require "net/imap"
require "test/unit"

class SearchKeyTypesTests < Test::Unit::TestCase
  Search          = Net::IMAP::Search
  SequenceSet     = Net::IMAP::SequenceSet
  DataFormatError = Net::IMAP::DataFormatError

  include Search::KeyTypes

  # TODO: Add :and, OR, NOT, FUZZY

  test "date-based keys convert Time objects (#to_date)" do
    date = Date.parse("2024-02-17")
    time = Time.parse("2024-02-17T13:00:00")
    assert_equal ["BEFORE", date], Before[time].to_a
  end

  test "date-based keys convert IMAP formatted date strings" do
    date = Date.parse("2024-02-17")
    assert_equal ["BEFORE", date], Before["17-Feb-2024"].to_a
  end

  input = [1, 3..5, 33, -1]
  seqset = SequenceSet[input]

  data "Seq", {
    type: Seq, args: [input],
    to_a: [seqset],
    to_h: {seq: seqset},
  }, keep: true

  data "UID", {
    type: UID, args: [input],
    to_a: ["UID", seqset],
    to_h: {uid: seqset},
  }, keep: true

  data "All", {
    type: All, args: [],
    to_a: %w[ALL],
    to_h: {all: true},
  }, keep: true

  data "SaveDateSupported", {
    type: SaveDateSupported, args: [],
    to_a: %w[SAVEDATESUPPORTED],
    to_h: {savedatesupported: true},
  }, keep: true

  data "Answered", {
    type: Answered, args: [],
    to_a: %w[ANSWERED],
    to_h: {answered: true},
  }, keep: true

  data "Deleted", {
    type: Deleted, args: [],
    to_a: %w[DELETED],
    to_h: {deleted: true},
  }, keep: true

  data "Flagged", {
    type: Flagged, args: [],
    to_a: %w[FLAGGED],
    to_h: {flagged: true},
  }, keep: true

  data "Draft", {
    type: Draft, args: [],
    to_a: %w[DRAFT],
    to_h: {draft: true},
  }, keep: true

  data "Seen", {
    type: Seen, args: [],
    to_a: %w[SEEN],
    to_h: {seen: true},
  }, keep: true

  data "Unanswered", {
    type: Unanswered, args: [],
    to_a: %w[UNANSWERED],
    to_h: {unanswered: true},
  }, keep: true

  data "Undeleted", {
    type: Undeleted, args: [],
    to_a: %w[UNDELETED],
    to_h: {undeleted: true},
  }, keep: true

  data "Undraft", {
    type: Undraft, args: [],
    to_a: %w[UNDRAFT],
    to_h: {undraft: true},
  }, keep: true

  data "Unflagged", {
    type: Unflagged, args: [],
    to_a: %w[UNFLAGGED],
    to_h: {unflagged: true},
  }, keep: true

  data "Unseen", {
    type: Unseen, args: [],
    to_a: %w[UNSEEN],
    to_h: {unseen: true},
  }, keep: true

  data "Keyword", {
    type: Keyword, args: ["$Forwarded"],
    to_h: {keyword: "$Forwarded"},
    to_a: %w[KEYWORD $Forwarded],
  }, keep: true

  data "Unkeyword", {
    type: Unkeyword, args: ["$MDNSent"],
    to_a: %w[UNKEYWORD $MDNSent],
    to_h: {unkeyword: "$MDNSent"},
  }, keep: true

  data "Filter", {
    type: Filter, args: ["on-the-road"],
    to_a: %w[FILTER on-the-road],
    to_h: {filter: "on-the-road"},
  }, keep: true

  data "EmailID", {
    type: EmailID, args: ["msg-123-abc"],
    to_a: %w[EMAILID  msg-123-abc],
    to_h: {emailid: "msg-123-abc"},
  }, keep: true

  data "ThreadID", {
    type: ThreadID, args: ["thd-abc-123"],
    to_a: %w[THREADID thd-abc-123],
    to_h: {threadid: "thd-abc-123"},
  }, keep: true

  data "From", {
    type: From, args: ["maria@example.test"],
    to_a: %w[FROM maria@example.test],
    to_h: {from: "maria@example.test"},
  }, keep: true

  data "To", {
    type: To, args: ["shugo@example.test"],
    to_a: %w[TO shugo@example.test],
    to_h: {to: "shugo@example.test"},
  }, keep: true

  data "Bcc", {
    type: Bcc, args: ["Smith"],
    to_a: %w[BCC Smith],
    to_h: {bcc: "Smith"},
  }, keep: true

  data "Cc", {
    type: Cc, args: ["Eric"],
    to_a: %w[CC Eric],
    to_h: {cc: "Eric"},
  }, keep: true

  data "Subject", {
    type: Subject, args: ["ruby news"],
    to_a: ["SUBJECT", "ruby news"],
    to_h: {subject: "ruby news"},
  }, keep: true

  data "Body", {
    type: Body, args: ["substring found in msg body"],
    to_a: ["BODY", "substring found in msg body"],
    to_h: {body: "substring found in msg body"},
  }, keep: true

  data "Text", {
    type: Text, args: ["substring found in msg text"],
    to_a: ["TEXT", "substring found in msg text"],
    to_h: {text: "substring found in msg text"},
  }, keep: true

  date = Date.parse("2024-02-17")

  data "Before", {
    type: Before, args: [date],
    to_a: ["BEFORE", date],
    to_h: {before: date},
  }, keep: true

  data "On", {
    type: On, args: [date],
    to_a: ["ON", date],
    to_h: {on: date},
  }, keep: true

  data "Since", {
    type: Since, args: [date],
    to_a: ["SINCE", date],
    to_h: {since: date},
  }, keep: true

  data "SavedBefore", {
    type: SavedBefore, args: [date],
    to_a: ["SAVEDBEFORE", date],
    to_h: {savedbefore: date},
  }, keep: true

  data "SavedOn", {
    type: SavedOn, args: [date],
    to_a: ["SAVEDON", date],
    to_h: {savedon: date},
  }, keep: true

  data "SavedSince", {
    type: SavedSince, args: [date],
    to_a: ["SAVEDSINCE", date],
    to_h: {savedsince: date},
  }, keep: true

  data "SentBefore", {
    type: SentBefore, args: [date],
    to_a: ["SENTBEFORE", date],
    to_h: {sentbefore: date},
  }, keep: true

  data "SentOn", {
    type: SentOn, args: [date],
    to_a: ["SENTON", date],
    to_h: {senton: date},
  }, keep: true

  data "SentSince", {
    type: SentSince, args: [date],
    to_a: ["SENTSINCE", date],
    to_h: {sentsince: date},
  }, keep: true

  data "Larger", {
    type: Larger, args: [123_456],
    to_a: ["LARGER", 123_456],
    to_h: {larger: 123_456},
  }, keep: true

  data "Smaller", {
    type: Smaller, args: [123_456],
    to_a: ["SMALLER", 123_456],
    to_h: {smaller: 123_456},
  }, keep: true

  data "Older", {
    type: Older, args: [123_456],
    to_a: ["OLDER", 123_456],
    to_h: {older: 123_456},
  }, keep: true

  data "Younger", {
    type: Younger, args: [123_456],
    to_a: ["YOUNGER", 123_456],
    to_h: {younger: 123_456},
  }, keep: true

  data "Header", {
    type: Header, args: ["List-ID", "ruby-lang.org"],
    to_a: %w[HEADER List-ID ruby-lang.org],
    to_h: {header: {"List-ID" => "ruby-lang.org"}},
  }, keep: true

  data "ModSeq (with single argument)", {
    type: ModSeq, args: [123_456_789],
    to_a: ["MODSEQ", 123_456_789],
    to_h: {modseq: 123_456_789},
  }, keep: true

  data "ModSeq (with metadata entry args)", {
    type: ModSeq, args: ["/flags/\\draft", "all", 620_162_338],
    to_a: ["MODSEQ", "/flags/\\draft", "all", 620_162_338],
    to_h: {modseq: {"/flags/\\draft" => {"all" => 620_162_338}}},
  }, keep: true

  data "Annotation", {
    type: Annotation, args: ["/comment", "value", "IMAP4"],
    to_a: %w[ANNOTATION /comment value IMAP4],
    to_h: {annotation: {"/comment" => {"value" => "IMAP4"}}},
  }, keep: true

  data "X-GM-RAW", {
    type: XGmRaw, args: ["has:attachment in:unread"],
    to_a: ["X-GM-RAW", "has:attachment in:unread"],
    to_h: {x_gm_raw: "has:attachment in:unread"},
  }, keep: true

  data "X-GM-MSGID", {
    type: XGmMsgID, args: [1278455344230334865],
    to_a: ["X-GM-MSGID", 1278455344230334865],
    to_h: {x_gm_msgid: 1278455344230334865},
  }, keep: true

  data "X-GM-THRID", {
    type: XGmThrID, args: [1266894439832287888],
    to_a: ["X-GM-THRID", 1266894439832287888],
    to_h: {x_gm_thrid: 1266894439832287888},
  }, keep: true

  data "Generic (no args)", {
    type: Generic, args: ["abc"],
    to_a: ["abc"],
    to_h: {"abc" => true},
  }, keep: true

  data "Generic (single arg)", {
    type: Generic, args: ["abc", 123],
    to_a: ["abc", 123],
    to_h: {"abc" => 123},
  }, keep: true

  data "Generic (multiple args)", {
    type: Generic, args: ["a", "b", "c", 123],
    to_a: ["a", "b", "c", 123],
    to_h: {"a" => {"b" => {"c" => 123}}},
  }, keep: true

  test "#to_a" do |data|
    data => type:, args:, to_a: expected
    assert_equal expected, type[*args].to_a
  end

  test "#to_h" do
    data => type:, args:, to_h: expected
    assert_equal expected, type[*args].to_h
  end

end
