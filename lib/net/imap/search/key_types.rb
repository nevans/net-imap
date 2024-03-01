# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyTypes

        Nullary = Key.define(:name) do
          def initialize(name:) = super name: Types::SearchKeyName[name]
        end

        def self.search_key(const_name, type = nil, &)
          const_name => Symbol
          attr_name = const_name.downcase
          data_type = if type
                        unary_search_key(attr_name, type, &)
                      else
                        Nullary[attr_name]
                      end
          const_set const_name, data_type
        end

        def self.unary_search_key(attr_name, type, &block)
          Key.define(attr_name) do
            define_method(:name) { attr_name }
            alias_method :value, attr_name
            define_method(:to_h) { { name => value } }

            define_method :initialize do |**kwargs|
              kwargs[attr_name] = type[kwargs.fetch(attr_name)]
              super
            end

            class_eval(&block) if block
          end
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

        search_key :Seq,        SequenceSet
        search_key :UID,        SequenceSet

        search_key :Keyword,    Types::FlagKeyword
        search_key :Unkeyword,  Types::FlagKeyword

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
