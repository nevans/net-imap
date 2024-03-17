# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyTypes
        @mapping = {}

        def [](key_name) @mapping[key_name.downcase.to_sym] end

        def self.search_key(const_name, type = nil, &)
          key_name = const_name.to_sym.downcase
          type = case type
          when nil  then nullary(key_name.to_s, &)
          when Hash then n_ary_search_key(key_name, type, &)
          else           unary_search_key(key_name, type, &)
          end
          const_set const_name, type
          @mapping[key_name] = type
        end

        class NullaryKey < Key
          def value = true
        end

        def self.nullary(name, &block)
          NullaryKey.define_with_name(name:, &block)
        end

        class UnaryKey < Key
          def self.value = deconstruct.first
        end

        def self.unary_search_key(name, type, &block)
          attr = name.to_sym.downcase
          UnaryKey.define_with_name(attr, name: name.to_s) do
            define_method :initialize do |**kwargs|
              kwargs[attr] &&= type[kwargs[attr]]
              super(**kwargs)
            end
          end
            .then { block ? Class.new(_1, &block) : _1 }
        end

        def self.n_ary_search_key(name, types, &block)
          attrs = types.keys
          types = types.compact
          Key.define_with_name(*attrs, name: name.to_s) do
            define_method :initialize do |**kwargs|
              types.each do |attr, type|
                kwargs[attr] &&= type[kwargs[attr]]
              end
              super(**kwargs)
            end
          end
            .then { block ? Class.new(_1, &block) : _1 }
        end

        search_key :All
        search_key :SaveDateSupported

        search_key :Answered
        search_key :Unanswered
        search_key :Deleted
        search_key :Undeleted
        search_key :Draft
        search_key :Undraft
        search_key :Flagged
        search_key :Unflagged
        search_key :Seen
        search_key :Unseen

        search_key :Keyword,    Types::FlagKeyword
        search_key :Unkeyword,  Types::FlagKeyword

        search_key :Seq, SequenceSet do
          def name = key
          def to_a = [seq]
        end

        search_key :UID,        SequenceSet

        search_key :Filter,     Types::FilterName

        search_key :EmailID,    Types::ObjectID
        search_key :ThreadID,   Types::ObjectID

        search_key :From,       Types::EnvelopeField
        search_key :To,         Types::EnvelopeField
        search_key :Cc,         Types::EnvelopeField
        search_key :Bcc,        Types::EnvelopeField
        search_key :Subject,    Types::EnvelopeField

        search_key :Body,       Types::FullText
        search_key :Text,       Types::FullText

        search_key :Header,
          field_name: Types::HeaderFldName,
          string:     Types::Astring

      end

    end
  end
end
