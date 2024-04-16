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
        def name = key&.name&.tr("_", "-")&.upcase

        # An array of IMAP search-key argumwnts.  Prepended with #name to create
        # #to_a.  Usually the same as #deconstruct.
        def args = deconstruct

        # Returns a hash that represents the Key object.  See #key and #value.
        #
        # The result can be sent to Key[] to recreate the key:
        #    key == Key[key.to_h] # => true
        def to_h = {key => value}

        # A Symbol to be used as the key for #to_h.  See also: #name.
        def key  = self.class.key

        # An object to be used as the value for #to_h.  See also #args.
        def value
          args.empty? ? true : args.reverse.reduce {|acc, arg| {arg => acc} }
        end
      end

    end
  end
end
