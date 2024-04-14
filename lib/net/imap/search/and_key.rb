# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

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
