# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyTypes
        module Formats
          ASTRING     = /\A[^\0]*\z/n
          ATOM        = /\A#{ResponseParser::Patterns::ATOM}\z/n
          ATOM_CHAR   = ResponseParser::Patterns::ATOM_CHAR
          FILTER_NAME = %r{\A[#{ATOM_CHAR.source}&&[^/]]+\z}n
        end

        module Params
          String = ->(name, regexp) {
            ->(value) {
              value = String.try_convert(value) or
                raise TypeError, "expected String"
              value.b.match?(FORMAT) or
                raise DataFormatError, "invalid filter-name string"
              value
            }
          }

          Date = ->(value) {
            if value.respond_to?(:to_date)
              value = value.to_date
            elsif value.respond_to?(:to_str)
              value = IMAP.decode_date(value.to_str)
            end
            value in Date or raise TypeError, "expected date"
            value
          }

          Name          = String["search-key name", Formats::ATOM]
          FlagKeyword   = String["flag-keyword",    Formats::ATOM]
          Astring       = String["astring",         Formats::ASTRING]
          FilterName    = String["filter-name",     Formats::FILTER_NAME]
          EnvelopeField = Astring
          FullText      = Astring
        end

        Nullary = Data.define(:name) do
          include Key
          def initialize(name:) = super name: Params::Name[seqset]
        end

        def self.search_key(const_name, type = nil, &)
          const_name => Symbol
          attr_name = const_name.downcase
          data_type = type ? unary_key(attr_name, type, &) : nullary_key(attr_name, &)
          const_define const_name, data_type
        end

        def self.nullary_key(attr_name, &block)
          Data.define do
            include Key
            define_method(:name) { attr_name }
          end
        end

        def self.unary_key(attr_name, type, &block)
          Data.define(attr_name) do
            include Key

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

        def self.bool_keys(name, ...)
          [search_key(name, ...),
           search_key(:"Un#{name}", ...)]
        end

        search_key :All
        search_key :SaveDateSupported

        bool_keys :ANSWERED
        bool_keys :DELETED
        bool_keys :DRAFT
        bool_keys :FLAGGED
        bool_keys :SEEN

        search_key :Seq,        SequenceSet
        search_key :UID,        SequenceSet

        bool_keys  :Keyword,    Params::FlagKeyword

        search_key :Filter,     Params::Filter
        search_key :EmailID,    Params::ObjectID
        search_key :ThreadID,   Params::ObjectID

        search_key :Bcc,        Params::EnvelopeField
        search_key :Cc,         Params::EnvelopeField
        search_key :From,       Params::EnvelopeField
        search_key :Subject,    Params::EnvelopeField
        search_key :To,         Params::EnvelopeField
        search_key :Body,       Params::FullText
        search_key :Text,       Params::FullText
      end

    end
  end
end
