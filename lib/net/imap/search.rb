# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # == Search key definitions
    #
    # The search keys described below are defined by
    # {RFC3501 § 6.4.4}[https://www.rfc-editor.org/rfc/rfc3501.html#section-6.4.4],
    # {RFC9051 § 6.4.4}[https://www.rfc-editor.org/rfc/rfc9051.html#section-6.4.4],
    # and various extensions.
    #
    # === Combining search keys
    # The argument to these search keys may be a search key hash or an array of
    # search keys.
    #
    # +:and+::
    #   <tt>{and: search_keys}</tt> explicitly converts into a parenthesized
    #   list of search keys.
    #
    # +OR+::
    #   <tt>{or: search_keys}</tt>  the specified search key.
    #
    # === Modifying a search key
    # +NOT+::
    #   <tt>{not: search_key}</tt> negates the specified search key.
    #
    # +FUZZY+::
    #   <tt>{fuzzy: search_key}</tt> uses fuzzy matching for the specified
    #   search key.
    #
    #   <em>Requires the <tt>SEARCH=FUZZY</tt> extension</em>.
    #   {[RFC6203]}[https://www.rfc-editor.org/rfc/rfc6203.html#section-6]
    #
    # === Sequence set membership
    # The argument to these search keys must be a valid input to
    # SequenceSet.new.
    #
    # <tt>:seq</tt>::
    #   <tt>{seq: set}</tt> matches messages with message sequence numbers in
    #   the set.
    #
    #   *NOTE:* <em>The +:seq+ label is needed for SearchProgram's hash
    #   representation, but the +sequence-set+ search key is unlabeled in the
    #   \IMAP grammar.</em>
    # +UID+::
    #   <tt>{uid: set}</tt> matches messages with unique identifiers in
    #   the set.
    #
    # === All or nothing searches
    #
    # Use +true+ to enable search keys which have no arguments.
    #
    # +ALL+::
    #   <tt>{all: true}</tt> matches every message in the mailbox.
    #
    # +SAVEDATESUPPORTED+::
    #   <tt>{savedatesupported: true}</tt> matches every message in the mailbox
    #   if the mailbox supports the save date attribute.  Otherwise, it matches
    #   no messages.
    #
    #   <em>Requires the +SAVEDATE+ extension</em>.
    #   {[RFC8514]}[https://www.rfc-editor.org/rfc/rfc8514.html#section-4.3]
    #
    # === Flags
    #
    # Search keys with no arguments are used for system flag checks.  Use +true+
    # to check for the presence of the flag and +false+ to check for its
    # absence.
    #
    # +ANSWERED+::
    #   <tt>{answered: true}</tt> matches messages with the
    #   <tt>\\Answered</tt> flag.
    # +UNANSWERED+::
    #   <tt>{answered: false}</tt> matches messages without the
    #   <tt>\\Answered</tt> flag.
    #
    # +DELETED+::
    #   <tt>{deleted: true}</tt> matches messages with the
    #   <tt>\\Deleted</tt> flag.
    # +UNDELETED+::
    #   <tt>{deleted: false}</tt> matches messages without the
    #   <tt>\\Deleted</tt> flag.
    #
    # +DRAFT+::
    #   <tt>{draft: true}</tt> matches messages with the
    #   <tt>\\Draft</tt> flag.
    # +UNDRAFT+::
    #   <tt>{draft: false}</tt> matches messages without the
    #   <tt>\\Draft</tt> flag.
    #
    # +FLAGGED+::
    #   <tt>{flagged: true}</tt> matches messages with the
    #   <tt>\\Flagged</tt> flag.
    # +UNFLAGGED+::
    #   <tt>{flagged: false}</tt> matches messages without the
    #   <tt>\\Flagged</tt> flag.
    #
    # +SEEN+::
    #   <tt>{seen: true}</tt> matches messages with the
    #   <tt>\\Seen</tt> flag.
    # +UNSEEN+::
    #   <tt>{seen: false}</tt> matches messages without the
    #   <tt>\\Seen</tt> flag.
    #
    # The following search keys take a single keyword flag argument.  When an
    # array of keyword flag values is specified, a parenthesized list of search
    # keys will be generated, one per keyword, to match messages with _all_ of
    # the keyword flags.
    #
    # +KEYWORD+::
    #   <tt>{keyword: flag}</tt> matches messages with the specified keyword
    #   flag.
    # +UNKEYWORD+::
    #   <tt>{unkeyword: flag}</tt> matches messages without the specified
    #   keyword flag.
    #
    # === Substring searches
    #
    # Searching inside envelope fields:
    # +BCC+::
    #   <tt>{bcc: substring}</tt> matches messages with the specified substring
    #   in the envelope's BCC field.
    # +CC+::
    #   <tt>{cc: substring}</tt> matches messages with the specified substring
    #   in the envelope's CC field.
    # +FROM+::
    #   <tt>{from: substring}</tt> matches messages with the specified substring
    #   in the envelope's FROM field.
    # +SUBJECT+::
    #   <tt>{subject: substring}</tt> matches messages with the specified
    #   substring in the envelope's SUBJECT field.
    # +TO+::
    #   <tt>{to: substring}</tt> matches messages with the specified substring
    #   in the envelope's TO field.
    #
    # Searching message headers:
    # +HEADER+::
    #   <tt>{header: {field => substring}}</tt> matches messages with the
    #   specified header field containing the specified substring.
    #
    # === Full text searches
    # Full text searches _may_ use flexible matching---rather than simple
    # substring matches---at the server's discretion.  For example, these may
    # use stemming or only match on full words.
    #
    # +BODY+::
    #   <tt>{body: string}</tt> matches messages with the specified string in
    #   the body of the message.  This does not match on any header fields.
    # +TEXT+::
    #   <tt>{text: string}</tt> matches messages with the specified string in
    #   the header or body of the message.
    #
    # === Date comparisons
    # The argument to these search keys must respond to +#to_date+ or be
    # parseable by Net::IMAP.decode_date.
    #
    # Searching on +INTERNALDATE+:
    # +BEFORE+::
    #   <tt>{before: date}</tt> matches messages whose internal date is
    #   earlier than the specified date.
    # +ON+::
    #   <tt>{on: date}</tt> matches messages whose internal date is
    #   within the specified date.
    # +SINCE+::
    #   <tt>{since: date}</tt> matches messages whose internal date is
    #   later than the specified date.
    #
    # Searching on +Date:+ header field:
    # +SENTBEFORE+::
    #   <tt>{sentbefore: date}</tt> matches messages whose internal date is
    #   earlier than the specified date.
    # +SENTON+::
    #   <tt>{senton: date}</tt> matches messages whose internal date is
    #   within the specified date.
    # +SENTSINCE+::
    #   <tt>{sentsince: date}</tt> matches messages whose internal date is
    #   later than the specified date.
    #
    # Searching on +SAVEDATE+:
    # +SAVEDBEFORE+::
    #   <tt>{savedbefore: date}</tt> matches messages whose internal date is
    #   earlier than the specified date.
    #
    #   <em>Requires the +SAVEDATE+ extension</em>.
    #   {[RFC8514]}[https://www.rfc-editor.org/rfc/rfc8514.html#section-4.3]
    # +SAVEDON+::
    #   <tt>{savedon: date}</tt> matches messages whose internal date is
    #   within the specified date.
    #
    #   <em>Requires the +SAVEDATE+ extension</em>.
    #   {[RFC8514]}[https://www.rfc-editor.org/rfc/rfc8514.html#section-4.3]
    # +SAVEDSINCE+::
    #   <tt>{savedsince: date}</tt> matches messages whose internal date is
    #   later than the specified date.
    #
    #   <em>Requires the +SAVEDATE+ extension</em>.
    #   {[RFC8514]}[https://www.rfc-editor.org/rfc/rfc8514.html#section-4.3]
    #
    # === Integer comparisons
    # The argument to these search keys must be an Integer:
    #
    # Searching on +RFC822.SIZE+:
    # +LARGER+::
    #   <tt>{larger: bytes}</tt> matches messages with +RFC822.SIZE+
    #   larger than the specified number of bytes.
    # +SMALLER+::
    #   <tt>{smaller: bytes}</tt> matches messages with +RFC822.SIZE+
    #   smaller than the specified number of bytes.
    #
    # Searching on the number of seconds elapsed since +INTERNALDATE+:
    # +OLDER+::
    #   <tt>{older: interval}</tt> matches messages with +INTERNALDATE+
    #   older than the specified interval number of seconds ago.
    #
    #   <em>Requires the +WITHIN+ extension</em>.
    #   {[RFC5032]}[https://www.rfc-editor.org/rfc/rfc5032.html]
    # +YOUNGER+::
    #   <tt>{younger: interval}</tt> matches messages with +INTERNALDATE+
    #   younger than the specified interval number of seconds ago.
    #
    #   <em>Requires the +WITHIN+ extension</em>.
    #   {[RFC5032]}[https://www.rfc-editor.org/rfc/rfc5032.html]
    #
    # === ObjectID
    # The argument to these search keys must be an exact match (substring
    # matches are not supported):
    #
    # +EMAILID+::
    #   <tt>{emailid: objectid}</tt> matches messages whose +EMAILID+ is the
    #   specified ObjectID.
    #
    #   <em>Requires the +OBJECTID+ extension</em>.
    #   {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html#section-6]
    #
    # +THREADID+::
    #   <tt>{threadid: objectid}</tt> matches messages whose +THREADID+ is the
    #   specified ObjectID.
    #
    #   <em>Requires the +OBJECTID+ extension</em>.
    #   {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html#section-6]
    #
    # === Filters
    #
    # +FILTER+::
    #   <tt>{filter: filter_name}</tt> references a filter that is stored on the
    #   server and matches all of the messages which would be matched by that
    #   filter's search criteria.
    #
    #   <em>Requires the +FILTERS+ extension</em>.
    #   {[RFC5466]}[https://www.rfc-editor.org/rfc/rfc5466.html#section-3.1]
    #
    # === Modification sequence
    #
    # +MODSEQ+::
    #   <tt>{modseq: mod_sequence}</tt> matches messages that have
    #   modification values that are equal to or greater than
    #   +mod_sequence+.
    #
    #   <tt>{modseq: {entry_name => {entry_type_req => mod_sequence}}}</tt>
    #   matches messages that contain specific metadata items which have been
    #   updated since +mod_sequence+.
    #
    #   <em>Requires the +CONDSTORE+ extension</em>.
    #   {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
    #
    # === Annotations
    #
    #   <tt>{annotation: {entry_match => {att_search => value}}}</tt>
    #
    #   <em>Requires the annotations (+ANNOTATE-EXPERIMENT-1+) extension</em>.
    #   {[RFC5257]}[https://www.rfc-editor.org/rfc/rfc5257.html].
    #
    class Search
      autoload :Key,               "#{__dir__}/search/key"
      autoload :KeyList,           "#{__dir__}/search/key_list"
      autoload :KeyNameValidation, "#{__dir__}/search/key_name_validation"
      autoload :KeyTypes,          "#{__dir__}/search/key_types"

      attr_reader :keys, :charset

      def initialize(*keys, charset: nil, **kwkeys)
        keys << kwkeys unless kwkeys.empty?
        @keys    = KeyList[*keys]
        @charset = charset&.to_str
      end

    end
  end
end
