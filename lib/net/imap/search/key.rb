# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class Key < Data
        def self.[](key)
          case key
          when Key                    then key
          when KeyList                then key.to_key
          when SequenceSet::Coercible then KeyTypes::Seq[key]
          when String, Symbol         then KeyTypes[key.downcase.to_sym][]
          when Array                  then KeyTypes::And[*key]
          when Hash                   then KeyList.new(key).to_key
          else raise DataFormatError, "invalid search-key: %p" % [key]
          end
        end

        # See documentation for #hash_key.  Returns +nil+ when the class
        # represents multiple search-key types, for example: KeyTypes::Generic.
        #
        # See also #imap_name.
        def self.hash_key = nil

        # See documentation for #imap_name.  Returns +nil+ when the class
        # represents multiple search-key types, for example: KeyTypes::Generic.
        def self.imap_name = hash_key&.name&.tr("_", "-")&.upcase

        # The search key arguments, usually the same as #deconstruct.
        def args = deconstruct

        # Returns an array that represents the IMAP search-key, usually
        # #imap_name followed by #imap_args.
        def to_a = imap_name.is_a?(String) ? [imap_name, *imap_args] : imap_args

        # Returns the IMAP string name for this search-key type.  Returns +nil+
        # when the IMAP grammar doesn't use a name for the search key.
        #
        # See also: #hash_key
        def imap_name = self.class.imap_name

        # An array of IMAP search-key argumwnts.  Prepended with #imap_name to
        # create #to_a.  Usually the same as #args and #deconstruct.
        def imap_args = args.then { recursive_imap_args _1 }

        # Returns a hash serializatiun of the search key, based on #hash_key and
        # #hash_value.  The result can be sent to Key[] to recreate the search
        # key:
        #
        #     search_key == Net::IMAP::Search::Key[search_key.to_h] # => true
        def to_h = {hash_key => hash_value}

        # Returns the key for #to_h, usually a symbol.  See also: #imap_name.
        def hash_key = self.class.hash_key

        # An object to be used as the value for #to_h.  See also #imap_args.
        def hash_value
          return true if imap_args.empty?
          args.reverse.reduce {|acc, arg| {arg => acc} }
        end

        private

        def recursive_imap_args(args)
          args.flat_map {|arg| arg.is_a?(Key) ? arg.to_a : arg }
        end

        def inner_to_h(inner_key)
          inner_key.is_a?(KeyTypes::And) ? inner_key.hash_value : inner_key.to_h
        end

      end

    end
  end
end
