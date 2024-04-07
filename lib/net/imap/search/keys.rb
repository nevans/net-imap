# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class Key < Data
        def name = self.class.key.upcase.to_s
        def args = deconstruct
        def to_a = [name, *args]

        def to_h = {key => value}
        def key  = self.class.key
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

      AndKey        = Class.new(KeyListKey)
      OrKey         = Class.new(KeyListKey)

    end
  end
end
