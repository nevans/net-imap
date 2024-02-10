# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # SearchProgram is used to validate and format arguments to IMAP
    # {#search}[rdoc-ref:IMAP#search],
    # {#sort}[rdoc-ref:IMAP#sort],
    # {#thread}[rdoc-ref:IMAP#thread],
    # {#uid_search}[rdoc-ref:IMAP#uid_search],
    # {#uid_sort}[rdoc-ref:IMAP#uid_sort], and
    # {#uid_thread}[rdoc-ref:IMAP#uid_thread].
    # The class represents <tt>search-program</tt> from the \IMAP grammar: a
    # list of one or more <tt>search-key</tt>s.  A search program with multiple
    # search keys matches the intersection of all of its search keys.
    #
    # == Search key translation
    #
    # Most search keys are composed of a label and some number of arguments.
    # Every (currently known) search key can be represented by a single element
    # hash.
    #
    # [Sequence Set]
    #   +sequence-set+ search keys have no label in the \IMAP grammar.  They may
    #   be input as a SequenceSet, Integer, Range, Set, a valid +sequence-set+
    #   String, or as an Array that contains _only_ these types (recursively).
    #       seqset_key = "55:61,*,33"
    #       seqset_key = [55..61, -1, 33]
    #       seqset_key = Set.new [55..61, -1, 33]
    #       seqset_key = Net::IMAP::SequenceSet[55..61, :*, 33]
    #
    #   Alternatively, a SequenceSet may be input as a hash with a +:seq+ key.
    #   For example:
    #       seqset_key = {seq: [55..61, "*", 33]}
    #
    # [Nullary]
    #   Search keys with no parameters may be input as the label string or a
    #   hash with a +true+ value.  For example:
    #       flagged_key = "FLAGGED"
    #       flagged_key = {flagged: true}
    #
    # [Boolean flags]
    #   In addition to the nullary form (described above) search key labels with
    #   the <tt>"UN"</tt> prefix may also be input as a hash with a +false+
    #   value.  For example:
    #       unflagged_key = "UNFLAGGED"
    #       unflagged_key = {flagged: false}
    #       unflagged_key = {unflagged: true}
    #
    # [Unary]
    #   Search key with a single parameter may be input as a single element
    #   Hash.  For example:
    #       uid_key  = {uid: 12345..}
    #       from_key = {from: "shugo"}
    #       to_key   = {to: "nicholas"}
    #
    # [Multiple arguments]
    #   Search keys with multiple parameters may be input as a nested hash.  The
    #   nested key must match the data type of the argument.  For example,
    #   string parameters should use String keys (not Symbol).
    #       list_id_key = {header: {"List-ID" => "list-header.example.com"}}
    #
    #   Alternatively, use a hash with a single +:args+ key.
    #       list_id_key = {header: {args: %w[List-ID list.example.test]}
    #
    # [Combining search keys]
    #   Any hash with more than one element will combine those search keys into
    #   a list.
    #       keys = {
    #         seq: [55..61, "*", 33], uid: (12345..),
    #         flagged: true, answered: false,
    #         from: "shugo", to: "nicholas",
    #         header: {"List-ID" => "list-header.example.com"},
    #       }
    #
    #   Except when they are valid SequenceSet inputs, arrays also combine into
    #   multiple search keys.
    #       keys = [
    #         [55..61, "*", 33], {uid: (12345..)},
    #         "flagged", "unanswered",
    #         {from: "shugo", to: "nicholas"},
    #         {header: {"List-ID" => "list-header.example.com"}},
    #       ]
    #
    #   By default, a search key list matches the intersection of all search
    #   keys in the list.  To _explicitly_ convert one or more search keys into
    #   an atomic parenthesized list that matches the intersection, use a hash
    #   with an +:and+ key.
    #       intersection = {
    #         and: {
    #           seq: [55..61, "*", 33], uid: (12345..),
    #           flagged: true, answered: false,
    #           from: "shugo", to: "nicholas",
    #           header: {"List-ID" => "list-header.example.com"},
    #         }
    #       }
    #
    #   Search keys lists may also be combined using +:or+, to match the union
    #   of all search keys in the list.  In the \IMAP grammar +OR+ is a binary
    #   search key, but +:or+ may be used to combine any list of one or search
    #   keys: a single key will simply output itself and more than two keys will
    #   rucursively generate as many +OR+ search keys as are needed.
    #       union = {
    #         or: {
    #           seq: [55..61, "*", 33], uid: (12345..),
    #           flagged: true, answered: false,
    #           from: "shugo", to: "nicholas",
    #           header: {"List-ID" => "list-header.example.com"},
    #         }
    #       }
    #       union = {
    #         or: [
    #           [55..61, "*", 33],
    #           {or: [
    #             {uid: (12345..)},
    #             {or: [
    #               "flagged",
    #               {or: [
    #                 "unanswered",
    #                 {
    #                   or: {
    #                     from: "shugo",
    #                     or: {
    #                       to: "nicholas",
    #                       header: {"List-ID" => "list-header.example.com"}
    #                     }
    #                   }
    #                 }
    #               ]}
    #             ]}
    #           ]}
    #         ]
    #       }
    #
    # == Search command arguments
    #
    # Search command arguments are generated from a list of search keys.
    #
    # supplied directly, as an Array.  This does no
    # validation of search key argument types or arity and only minimal
    # translation: only sequence sets and hashes.
    #
    # Range, Set, and Array arguments are converted to SequenceSet when they are
    # composed entirely of integers, ranges, <tt>:*</tt>, and valid
    # +sequence-set+ strings.  Note that <tt>*</tt> is not a valid atom char, so
    # +sequence-set+ strings should be placed inside an Array or SequenceSet.
    #
    #
    # === Ignored search keys
    #
    # Hash entries with a value of +nil+  are ignored.
    #
    # ...
    #
    # === Virtual search keys
    #
    # Use the following "virtual search keys" to generate search keys for system
    # flags similarly to keyword flags.
    # +:flags+::
    #   <tt>{flags: flags}</tt> matches messages with the specified flag(s).
    #   The flags list may contain both system flags (as symbols) and keyword
    #   flags (as strings).
    # +:unflags+::
    #   <tt>{unflags: flag}</tt> matches messages without the specified flag(s).
    #   The flags list may contain both system flags (as symbols) and keyword
    #   flags (as strings).
    #
    # The following match _any_ of the given values.  +OR+ search keys will be
    # generated, if multiple values are given.
    # +:size+::
    #   <tt>{size: sizes}</tt> matches messages with +RFC822.SIZE+
    #   within the specified range.
    #
    #   <em>The +:size+ "virtual search key" generates search keys using
    #   +LARGER+ and +SMALLER+.</em>
    #
    # +:internaldate+::
    #   <tt>{internaldate: dates}</tt> matches messages whose internal date is
    #   any of the specified dates.  _dates_ should be an array of dates and
    #   ranges of dates.
    #
    #   <em>The +:internaldate+ "virtual search key" generates search keys using
    #   +BEFORE+, +ON+, and +SINCE+.</em>
    #
    # +:within+::
    #   <tt>{within: intervals}</tt> matches messages with +INTERNALDATE+
    #   younger than the specified interval number of seconds ago.
    #
    #   <em>The +:within+ "virtual search key" generates search keys using
    #   +EARLIER+ and +YOUNGER+, which both
    #   require the +WITHIN+ extension</em>.
    #   {[RFC5032]}[https://www.rfc-editor.org/rfc/rfc5032.html]
    #
    # +:date+::
    #   <tt>{date: dates}</tt> matches messages whose +Date:+ header field is
    #   any of the specified dates.  _dates_ should be an array of dates and
    #   ranges of dates.
    #
    #   <em>The +:date+ "virtual search key" generates search keys using
    #   +SENTBEFORE+, +SENTON+, and +SENTSINCE+.</em>
    #
    # +:savedate+::
    #   <tt>{savedate: dates}</tt> matches messages whose save date is
    #   any of the specified dates.  _dates_ should be an array of dates and
    #   ranges of dates.
    #
    #   <em>The +:savedate+ "virtual search key" generates search keys using
    #   +SAVEDBEFORE+, +SAVEDON+, and +SAVEDSINCE+, which all
    #   require the +SAVEDATE+ extension</em>.
    #   {[RFC8514]}[https://www.rfc-editor.org/rfc/rfc8514.html#section-4.3]
    #
    # == TODO...
    #--
    #
    # Nested Array::  <tt>{key => [arg1, arg2, arg3]}</tt> becomes
    #                 <tt>[key, arg1, key, arg2, key, arg3]</tt>.
    # Nested Hash::   <tt>{key => {a1 => a2, b1 => {b2 => b3}}}</tt> becomes
    #                 <tt>[key, a1, a2, key, b1, b2, b3]</tt>
    #                 (with exceptions, documented below).
    #
    # <em>By default,</em> a nested array value is converted into the
    # intersection of multiple search keys with the same label.  <em>Some hash
    # keys may override this behavior.</em>
    #
    # <em>By default,</em> a nested hash with non-symbol keys can be used to
    # represents search keys with more than one argument.  Multiple keys will be
    # translated to a flattened list of search keys, which are combined as an
    # intersection.  <em>Some hash keys may override this behavior.</em> For
    # For example:
    #     {header: {"List-ID" => "ruby"}}
    #     # translates to
    #     ["HEADER", "List-ID", "ruby"]
    #
    # === Nested hashes
    #
    # Multiple keys will be translated to a flattened list of search keys,
    # which are combined as an intersection.  For example:
    #     {header: {"Message-ID" => [something, another]}}
    #     # translates to
    #     ["HEADER", "Message-ID", something,
    #      "HEADER", "Message-ID", another]
    #
    # Deeply nested hashes can represent any arbitrary number of arguments.
    # For example:
    #     {foo: {"one" => ["binary", {"two" => ["trinary1", "trinary2"]}]}}
    #     # translates to
    #     ["FOO", "one", "binary",
    #      "FOO", "one", "two", "trinary1",
    #      "FOO", "one", "two", "trinary2"]
    #
    # === Special hash keys
    #
    # * +:any+, +:or+
    # * +:all+, +:and+
    # * +:key+, +:keys+
    # * +:args+
    # * +:seq+
    #
    # Use a nested hash with +:or+ to combine as a union:
    #     {header: {"List-ID"    => "ruby",
    #               "Message-ID" => {or: [something, another]}}}
    #     # translates to
    #     [
    #       "HEADER", "List-ID", "ruby",
    #       "OR",
    #         "HEADER", "Message-ID", something,
    #         "HEADER", "Message-ID", another,
    #     ]
    #
    # +:or+ is applied recursively to nested hash values.  For example:
    #     {or: {header: {"List-ID"    => "ruby",
    #                    "Message-ID" => [something, another]}}
    #     # translates to
    #     [
    #       "OR",
    #         "HEADER", "List-ID", "ruby",
    #         "OR",
    #           "HEADER", "Message-ID", something,
    #           "HEADER", "Message-ID", another,
    #     ]
    #
    # Use +:and+ (or another nested array) to explicitly request an
    # intersection and prevent +:or+ recursion.  For example:
    #     # Using :and
    #     {or: {header: {"List-ID"    => "ruby",
    #                    "Message-ID" => {and: [something, another]}}}
    #     # Using a double-nested array:
    #     {or: {header: {"List-ID"    => "ruby",
    #                    "Message-ID" => [[something, another]]}}
    #     # Both translate to:
    #     [
    #       "OR",
    #         "HEADER", "List-ID", "ruby",
    #         ["HEADER", "Message-ID", something,
    #          "HEADER", "Message-ID", another],
    #     ]
    #
    # Use +:args+ to override this override this behavior, and simply append
    # an array of arguments.  For example:
    #     {foo: {args: [foo_arg1, foo_arg2, foo_arg3],
    #      bar: {"baz" => {args: [barbaz_arg1, barbaz_arg2}
    #     # translates to
    #     ["FOO", foo_arg1, foo_arg2, foo_arg3,
    #      "BAR", "baz", barbaz_arg1, barbaz_arg3]
    #
    # Use +:keys+ to override this override this behavior, and treat each
    # an array of arguments.  For example:
    #
    # Some hash keys have special meaning (details below):
    #
    # * <tt>{seq: seqset}</tt> for a sequence set with no label.
    # * +:and+ crates a parenthesized list from an array of search keys.
    # * <tt>{or:  keys}</tt> combines all keys in the array with +OR+.
    #
    # For example:
    #   search = SearchProgram.new(
    #      seq: seqset,
    #      or:  {
    #        subject: "foo",
    #        before: yesterday,
    #        and: {flagged: true, answered: false],
    #        from: "alice",
    #      }
    #   }
    #   search.search_arguments == [
    #     SequenceSet[seqset],
    #     "OR",
    #       "SUBJECT", "foo",
    #       "OR",
    #         "BEFORE" yesterday.to_date,
    #         "OR",
    #           ["FLAGGED", "UNANSWERED"],
    #           "FROM", "alice",
    #   ]
    #
    #
    #     # TODO: examples
    #
    # == TODO
    #++
    #
    #class SearchProgram
    #  def self.parse(args, charset: nil)
    #    case args
    #    when String then new(parse: args, charset: charset)
    #    when Array  then new(args:  args, charset: charset)
    #    else raise ArgumentError, "expected a string or array"
    #    end
    #  end

    #  attr_reader :charset, :search_keys

    #  # TODO: handle charset kwarg compatibility outside this
    #  # TODO: move raw data compatibility outside this
    #  def initialize(*args, charset: nil, **kwargs)
    #    kwargs = kwargs.compact
    #    args << kwargs unless kwargs.empty?
    #    @search_keys = load_search_keys(*args)
    #    @search_key_args = keys_to_args(*args)
    #    @search_keys.any? or raise DataFormatError, "missing search keys"
    #    @search_key_args.any? or raise DataFormatError, "missing search args"
    #  end

    #  # #search_arguments outputs an argument list of String, Integer, Date,
    #  # SequenceSet, and recursively nested Array values which should be
    #  # compatible with Net::IMAP's generic argument encoding.
    #  def search_arguments
    #    charset ? ["CHARSET", charset, *@search_key_args] : @search_key_args
    #  end

    #  def validate # :nodoc:
    #    # any validation is done during initialization or assignment
    #  end

    #  def send_data(imap, tag) # :nodoc:
    #    imap.__send__(:send_args_data, search_arguments, tag)
    #  end

    #  private

    #  def load_search_keys(*keys)
    #    split_keys_array(keys)
    #    # TODO: validate
    #    # TODO: Search::Key data type
    #  end

    #  # Converts a "search keys" object into an array of individual "search key"
    #  # objects.
    #  #
    #  # Also converts arrays and strings into SequenceSet as needed, so other
    #  # methods don't need to check SequenceSet::Coercible.
    #  def split_search_keys(keys)
    #    case keys
    #    when SequenceSet::Coercible then Search::Key::SeqSet.new(keys).keys
    #    when String                 then Search::Key::Argless.new(keys).keys
    #    when Array                  then split_keys_array(keys)
    #    when Hash                   then split_keys_hash(keys)
    #    else                             [keys]
    #    end
    #  end

    #  # In a "keys" array, hash values are flattened, but array values are not.
    #  def split_keys_array(keys)
    #    keys = keys.flat_map {
    #      _1.is_a?(Array) ? [split_keys_array(_1)] : split_search_keys(_1)
    #    }
    #    raise DataFormatError, "empty search key" if keys.empty?
    #    keys
    #  end

    #  # If a single search key is actually a container of multiple search keys,
    #  # it needs to be wrapped in an array.
    #  #
    #  # NOTE: call split_search_keys first
    #  def key_to_args(key)
    #    key = Search::Key[key] || key
    #    case key
    #    when Search::Key            then key.command_args
    #    when RawData                then [key]
    #    when Hash                   then key_hash_to_args key
    #    when Array                  then and_key_to_args  key
    #    else raise DataFormatError, "Invalid search-key: %p" % [key]
    #    end
    #  end

    #  # TODO: NOT, FUZZY
    #  def hash_entry_to_args(key, value)
    #    return [] if value.nil?
    #    case key
    #    when /\A OR     \z/ix then or_key_to_args          value
    #    when /\A NOT    \z/ix then not_key_to_args         value
    #    when /\A HEADER \z/ix then header_key_to_args      value
    #    when String           then generic_search_key_args key, value
    #    when :and             then and_key_to_args         value
    #    when :seq             then Search::Key::SeqSet.new(value).command_args
    #    when :args            then Search::Args.new(value).command_args
    #    when :parse           then parse_string            value
    #    when :raw             then raw_data                value
    #    when Symbol           then generic_search_key_args key, value
    #    else raise DataFormatError, "Invalid search-key: %p => %p" % [key, value]
    #    end
    #  end

    #  def generic_search_key_args(label, value)
    #    label = search_key_label label
    #    case value
    #    when true  then [label]
    #    when false then ["UN#{label}"]
    #    when String, Date, Time, Integer, RawData
    #      [label, value]
    #    when SequenceSet::Coercible
    #      [label, SequenceSet[value]]
    #    when Hash
    #      higher_arity_to_args(label, value)
    #    else
    #      raise DataFormatError, "unknown search-key: %p => %p" % [label, value]
    #    end
    #  end

    #  def higher_arity_to_args(label, value)
    #    raise "TODO: higher_arity_to_args (%p => %p)" % [label, value]
    #  end

    #  # Converts one or more search keys into their arguments list
    #  def keys_to_args(*keys)
    #    split_search_keys(keys).flat_map { key_to_args _1 }
    #  end

    #  def split_keys_hash(keys) keys.compact.map { {_1 => _2} } end

    #  def keys_hash_to_args(hash)
    #    hash.flat_map { hash_entry_to_args _1, _2 }
    #  end

    #  def key_hash_to_args(hash)
    #    hash = hash.compact # TODO: recursively compact, for arity > 1
    #    raise DataFormatError, "empty search key" if hash.empty?
    #    args = keys_hash_to_args(hash)
    #    hash.size == 1 ? args : [args]
    #  end

    #  def nullary_to_args(string)
    #    # TODO: ensure this is a valid nullary search_key
    #    [string]
    #  end

    #  def raw_data(data)
    #    [data.is_a?(RawData) ? data : RawData.new(data.to_str)]
    #  end

    #  # TODO: validate label
    #  def search_key_label(label) label.to_s.upcase end

    #  def not_key_to_args(value) = ["NOT", key_to_args(value)]

    #  def or_key_to_args(search_keys)
    #    split_search_keys(search_keys).reverse
    #      .reduce { ["OR", *key_to_args(_2), *key_to_args(_1)] }
    #  end

    #  def and_key_to_args(keys)
    #    args = keys.is_a?(Array) ? keys_to_args(*keys) : keys_to_args(keys)
    #    raise DataFormatError, "missing criteria in intersection" if args.empty?
    #    [args]
    #  end

    #  def header_key_to_args(headers)
    #    headers.flat_map { ["HEADER", _1.to_s, _2.to_str] }
    #  end

    #  # NOTE: this is not _completely_ backward compatible
    #  def normalize_search_args(args)
    #    args.map {|arg|
    #      case arg
    #      when Hash                   then keys_hash_to_args(arg)
    #      when SequenceSet::Coercible then SequenceSet[arg]
    #      when Array                  then normalize_search_args(arg)
    #      else                             arg
    #      end
    #    }
    #  end

    #  def parse_string(string)
    #    string = string.to_str
    #    case string
    #    when SequenceSet::Coercible then [SequenceSet[string]]
    #    else
    #      # TODO: parse, validate, only print deprecation for invalid
    #      warn "Raw search string is deprecated (other than sequence-set). " \
    #        "Use Net::IMAP::RawData.new(string) instead."
    #      [RawData.new(string)]
    #    end
    #  end

    #end

    #class Search
    #  class Key
    #    def self.[](key)
    #      pp self: self, key: key.class
    #      self == Key ? select(key) : new(key)
    #    rescue Exception => ex
    #      pp method: __method__, key:, ex:;
    #      nil
    #    end

    #    def self.select(key)
    #      case key
    #      when Key                    then key
    #      when SequenceSet::Coercible then SeqSet[keys]
    #      when String                 then Argless[keys]
    #      else
    #        # warn "TODO: convert %p to %s" % [key, Key]
    #        nil
    #      end
    #    end

    #    def keys = [self] # override in KeysList

    #    def type      = self.class
    #    def type_args = [value]
    #    def inspect   = "%s[%p]" % [type, type_args.join(", ")]
    #    def to_h      = {name => value}

    #    def command_args = raise NotImplementedError, "implement in subclass"
    #    def name         = raise NotImplementedError, "implement in subclass"
    #    def value        = raise NotImplementedError, "implement in subclass"

    #    class KeysList < Key
    #      attr_reader :keys

    #      def initialize(keys) = @keys = split_search_keys(keys)
    #      def name = :keys
    #      alias value keys
    #      def command_args = keys.flat_map(&:command_args)

    #      private

    #      def split_search_keys(keys)
    #        case keys
    #        when KeyList                then keys.keys
    #        when SequenceSet::Coercible then Key::SeqSet[keys].keys
    #        when String                 then Key::Argless[keys].keys
    #        when Array                  then split_keys_array(keys)
    #        when Hash                   then split_keys_hash(keys)
    #        else
    #          raise NotImplementedError, "TODO"
    #          [keys]
    #        end
    #          &.then(&:compact)
    #          .tap do
    #            raise DataFormatError, "empty search key" unless keys&.any?
    #          end
    #      end

    #      # In a "keys" array, hash values are flattened, but array values are not.
    #      def split_keys_array(keys)
    #        keys = keys.flat_map { Key(_1) }
    #        raise DataFormatError, "empty search key" if keys.empty?
    #        keys
    #      end

    #      # TEMP
    #      def Key(key) Key[_1] or raise NotImplementedError, "TODO" end
    #      # _1.is_a?(Array) ? [split_keys_array(_1)] : split_search_keys(_1)

    #      def split_keys_hash(keys)
    #        keys.compact.map { Key({_1 => _2}) }
    #      end

    #    end

    #    class SeqSet < Key
    #      attr_reader :value
    #      def initialize(value) = @value = SequenceSet[value]
    #      def name = :seq
    #      def command_args = [value]
    #      def inspect = "%s[%p]" % [self.class, value]
    #    end

    #    class And < Key
    #      attr_reader :value
    #      def initialize(value) = @value = KeysList[value]
    #      def name = :and
    #      def command_args = [value.command_args]
    #      def inspect = "%s[%p]" % [self.class, value]
    #    end

    #    class Argless < Key
    #      attr_reader :name
    #      def initialize(name) = @name = name.to_str # TODO: validate
    #      def command_args = [name]
    #      def value = true
    #      def inspect = "%s[%p]" % [self.class, name]
    #    end

    #    class Unary < Key
    #      attr_reader :value
    #      def initialize(value)
    #        @value = coerce_value(value)
    #      end
    #      def command_args = [name, value]
    #      def inspect = "%s[%p, %p]" % [self.class, name, value]
    #      def coerce_value(value) = value
    #    end

    #    class UnaryString < Unary
    #      def coerce_value(value) = value.to_str
    #    end

    #    class GenericUnary < Unary
    #      attr_reader :name
    #      def initialize(name, value)
    #        @name = name.to_str # TODO: validate
    #        super(value)
    #      end
    #      def inspect = "%s[%p, %p]" % [self.class, name, value]
    #    end

    #  end

    #  # a psuedo-key
    #  class Args < Key
    #    attr_reader :args
    #    def initialize(args) = @args = normalize_search_args(args)
    #    def command_args = args
    #    def name = :args
    #    def inspect = "%s[%p]" % [self.class, args]

    #    private

    #    # NOTE: this is not _completely_ backward compatible
    #    def normalize_search_args(args)
    #      args.map {|arg|
    #        case arg
    #        when Integer                then arg
    #        when Hash                   then hash_args(arg)
    #        when SequenceSet::Coercible then SequenceSet[arg]
    #        when Array                  then normalize_search_args(arg)
    #        else arg
    #        end
    #      }
    #    end

    #    def hash_to_args(hash)
    #      SearchProgram.new(hash).search_arguments
    #    end

    #  end

    #  # a psuedo-key
    #  class Raw < Key
    #    attr_reader :data
    #    def initialize(data) = @data = data
    #    def command_args
    #      [data.is_a?(RawData) ? data : RawData.new(data.to_str)]
    #    end
    #    def to_h = {raw: data}
    #    def inspect = "%s[%p]" % [self.class, data]
    #  end

    #end
  end
end
