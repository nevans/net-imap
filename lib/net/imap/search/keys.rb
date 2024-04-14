# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class Key < Data
        def self.[](key)
          case key
          when Key                    then key
          when SequenceSet::Coercible then KeyTypes::Seq[key]
          when String, Symbol         then KeyTypes[key.downcase.to_sym][]
          when Array                  then AndKey[*key]
          when Hash                   then KeyList.new(key).to_key
          else raise DataFormatError, "invalid search-key: %p" % [key]
          end
        end

        # See documentation for #key.
        #
        # Returns +nil+ when the class represents multiple search-key types, for
        # example: KeyTypes::Generic.
        def self.key = nil

        # See documentation for #name.
        #
        # Returns +nil+ when the class represents multiple search-key types, for
        # example: KeyTypes::Generic.
        def self.name = key&.name&.tr("_", "-")&.upcase

        # Returns an array that represents the IMAP search-key, usually #name
        # followed by #args.
        def to_a = [name, *args]

        # Returns the IMAP string name for this search-key type.
        #
        # Returns a symbol when the IMAP grammar doesn't use a name for the
        # search key:
        # * <tt>:seq</tt> for sequence numbers and
        # * <tt>:and</tt> for parenthesized lists.
        #
        # See also: #key
        def name = self.class.name

        # Returns an array of the search-key's arguments, not including #name.
        #
        # The result should be usable as an input to the class.[] method, to
        # recreate an identical Key:
        #    key == key.class[*key.args] # => true
        def args = deconstruct

        # Returns a hash that represents the Key object.  See #key and #value.
        #
        # The result should be usable as an input to Key[] to recreate an
        # identical Key:
        #    key == Key[key.to_h] # => true
        def to_h = {key => value}

        # A Symbol to be used as the key for #to_h.  See also: #name.
        def key  = self.class.key

        # An object to be used as the value for #to_h.  See also #args.
        def value
          args.empty? ? true : args.reverse.reduce {|acc, arg| {arg => acc} }
        end
      end

      # A search-key (or pseudo-search-key) composed of a list of keys.
      class KeyListKey < Key.define(:keys)
        def self.[](*keys)    = new(keys:)
        def initialize(keys:) = super keys: KeyList.new(keys).keys
        def deconstruct       = keys.deconstruct
      end

      class AndKey < KeyListKey
        def self.key = :and
        def name = key
        def to_a = [keys.flat_map(&:to_a)]
        def to_h = value.then { _1.is_a?(Hash) ? _1 : {key => value} }
        def value = merged_value.then {|ary| (ary in [hash]) ? hash : ary }

        private

        def merged_value = merge_array array_value
        def array_value = keys.map(&:to_h)

        def merge_array(array_value)
          array_value.each_with_object([{}]) do |hash, ary|
            merge_value(ary, hash)
          end
        end

        def merge_value(ary, hash)
          last = ary.last
          if hash.size == 1 && (key, * = hash.first) && !last.key?(key)
            last.update(hash)
          else
            ary << hash
          end
        end
      end

    end
  end
end
