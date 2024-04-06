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
              when SequenceSet::Coercible then KeyTypes::Seq[value]
              when String, Symbol         then nullary_key(value)
              when Array                  then AndKey[*value]
              when Hash                   then KeysHash.new(value).keys
              else raise DataFormatError, "invalid search-key: %p" % [value]
              end
            }
          end

          def nullary_key(name)
            KeysHash[name.downcase.to_sym => true].keys
            # TODO: rescue unknown strings as KeyType::Generic?
          end

        end

        class KeysHash
          def self.[](...) = new(...)

          attr_reader :prefix, :input

          def initialize(*prefix, input)
            @prefix = prefix
            @input = Hash.try_convert(input) or raise TypeError, "expected hash"
          end

          def keys      = inputs.map         { input_to_key(*_1) }
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

          # TODO: OR, NOT, FUZZY
          def input_to_key(key, *args)
            search_key = obsolete_input_to_key(key, *args) and
              return search_key
            case key
            in Symbol
              KeyTypes.fetch(key)[*args]
            in Types::Formats::LABEL
              KeyTypes::Generic[key, *args]
            else
              raise DataFormatError, "unknown search-key type: %p" % [key]
            end
          end

          def obsolete_input_to_key(key, *args)
            case key
            when :and    then AndKey.new(*args)
            when :or     then OrKey.new(*args)
            when :not    then NotKey.new(*args)
            when :fuzzy  then FuzzyKey.new(*args)
            end
          end

        end
      end
    end
  end
end
