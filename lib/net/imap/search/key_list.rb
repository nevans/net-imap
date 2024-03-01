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

          attr_reader :prefix, :input

          def initialize(*prefix, input)
            @prefix = prefix
            @input = Hash.try_convert(input) or raise TypeError, "expected hash"
          end

          def keys      = inputs.map         { input_to_key    _1, _2 }
          def inputs    = compacted.flat_map { entry_to_inputs _1, _2 }
          def compacted = input.compact # TODO

          private

          def recursive?(name)
            return true if name == :and
            name = name.to_s
            %w[OR NOT FUZZY].any? { _1.casecmp?(name) }
          end

          def entry_to_inputs(key, value)
            name = prefix.empty? ? key : prefix.first
            name in String | Symbol or
              raise TypeError, "expected string or symbol search-key name"
            return [[*prefix, key, value]] if recursive?(name)
            case value
            when true  then prefix.empty? ? key : [[*prefix, key]]
            when false then negate(*prefix, key)
            when Hash  then KeysHash[*prefix, key, value].inputs
            else            [[*prefix, key, value]]
            end
          end

          def negate(name, *args)
            name = name.is_a?(Symbol) ? :"un#{name}" : "UN#{name}"
            [name, *args]
          end

          # TODO: OR
          # TODO: NOT, FUZZY
          # TODO: HEADER
          # TODO: MODSEQ
          # TODO: ANNOTATE
          def input_to_key(key, value)
            key in String | Symbol or
              raise TypeError, "expected string or symbol key"
            case key
            when :seq                   then SeqSetKey[value]
            when :and                   then AndKey.new(value)
            when UIDKey.match_name      then UIDKey[value]
            when FlagKey.match_name     then FlagKey[key]
            when DateKey.match_name     then DateKey[key, value]
            when AstringKey.match_name  then AstringKey[key, value]
            when /\AHEADER\Z/i          then HeaderKey[key, value]
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

        end

      end
    end
  end
end
