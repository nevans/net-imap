# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class KeyList
        def self.[](*keys) new(keys) end

        attr_reader :keys
        alias deconstruct keys

        def initialize(keys)
          @keys = extract_keys(keys)
          raise DataFormatError, "invalid empty search keys" if @keys.empty?
        end

        private

        def extract_keys(keys)
          case keys
          when Array then Params.new(keys).keys
          when Hash  then KeysHash.new(keys).keys
          else raise DataFormatError, "invalid search-key list"
          end
        end

        class Params < KeyList
          private

          def extract_keys(keys)
            keys.flat_map {|value|
              case value
              when SequenceSet::Coercible then SeqSetKey[value]
              when String, Symbol         then FlagKey[value]
              when Array                  then AndKey[*value]
              when Hash                   then KeysHash.new(value).keys
              else raise DataFormatError, "invalid search-key: %p" % [value]
              end
            }
          end
        end

        class KeysHash
          def self.[](...) = new(...)

          attr_reader :input

          def initialize(*prefix, input)
            @input = Hash.try_convert(input) or raise TypeError, "expected hash"
          end

          def keys = compacted.flat_map { hash_entry_to_key _1, _2 }
          def compacted = input.compact # TODO

          def inputs
            compacted.map {|key, value| # TODO: flat_map
              case value
              when true  then key
              when false then key.is_a?(Symbol) ? :"un#{key}" : "UN#{key}"
              else            [key, value]
              end
            }
          end

          private

          # TODO: OR
          # TODO: NOT, FUZZY
          # TODO: HEADER
          # TODO: MODSEQ
          # TODO: ANNOTATE
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
            else
              raise DataFormatError, "unknown search-key: %p" % [key]
            end
          end

          def bool_key(key, bool)
            case bool
            when true  then key
            when false then key.is_a?(Symbol) ? :"un#{key}" : "UN#{key}"
            else
              raise DataFormatError, "invalid search-key: %p => %p" % [
                key, bool
              ]
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

        end

      end
    end
  end
end
