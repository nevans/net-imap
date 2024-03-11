# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyTypes
        @mapping = {}

        def [](attr_name) @mapping[attr_name.downcase.to_sym] end

        def self.search_key(const_name, type = nil, &)
          attr_name = const_name.downcase
          data_type = if type
                        unary_search_key(attr_name, type, &)
                      else
                        nullary(attr_name.to_s, &)
                      end
          const_set const_name, data_type
          @mapping[attr_name] = data_type
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

        def self.unary_search_key(attr, type, &block)
          Key.define_with_name(attr, name: attr.to_s) do
            define_method :initialize do |**kwargs|
              kwargs[attr] &&= type[kwargs[attr]]
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

        search_key :Bcc,        Types::EnvelopeField
        search_key :Cc,         Types::EnvelopeField
        search_key :From,       Types::EnvelopeField
        search_key :Subject,    Types::EnvelopeField
        search_key :To,         Types::EnvelopeField
        search_key :Body,       Types::FullText
        search_key :Text,       Types::FullText

      end

    end
  end
end
