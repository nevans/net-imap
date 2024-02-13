# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class KeyList
        def self.[](*keys) new(keys) end

        attr_reader :keys
        alias deconstruct keys

        def initialize(keys) @keys = extract_keys(keys) end

        private

        def extract_keys(keys)
          case keys
          when SequenceSet::Coercible then [SeqSetKey[keys]]
          when String, Symbol         then [FlagKey[keys]]
          when Array                  then keys_from_array(keys)
          when Hash                   then keys_from_hash(keys)
          else invalid! keys.class
          end
            .tap do invalid! "empty search keys" if _1.empty? end
        end

        def keys_from_array(keys)
          keys.flat_map {|value|
            case value
            when SequenceSet::Coercible then SeqSetKey[value]
            when String, Symbol         then FlagKey[value]
            when Array                  then AndKey[*value]
            when Hash                   then keys_from_hash(value)
            else invalid! value.class
            end
          }
        end

        def keys_from_hash(hash)
          hash.flat_map { hash_entry_to_key _1, _2 }
        end

         # TODO: NOT, FUZZY
         def hash_entry_to_key(key, value)
           return [] if value.nil?
           key in String | Symbol or
             raise TypeError, "expected string or symbol key"
           case key
           when :seq                   then SeqSetKey[value]
           when :and                   then AndKey.new(value)
           when UIDKey.match_name      then UIDKey[value]
           when FlagKey.match_name     then FlagKey[bool_key(key, value)]
           when DateKey.match_name     then DateKey[key, value]
           when AstringKey.match_name  then AstringKey[key, value]
           when KeywordKey.match_name  then KeywordKey[key, value]
           when ObjectIDKey.match_name then ObjectIDKey[key, value]
           when FilterKey.match_name   then FilterKey[key, value]
           else invalid! "%p => %p" % [key, value]
           end
           # when /\A OR     \z/ix then or_key_to_args          value
           # when /\A NOT    \z/ix then not_key_to_args         value
           # when /\A HEADER \z/ix then header_key_to_args      value
         end

         def bool_key(key, bool)
           case bool
           when true  then key
           when false then key.is_a?(Symbol) ? :"UN#{key}" : "UN#{key}"
           else invalid! "%p => %p" % [key, bool]
           end
         end

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

         def invalid!(format, *args)
           raise DataFormatError, "Invalid search-key: #{format.to_s % args}"
         end

      end

    end
  end
end
