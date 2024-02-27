# frozen_string_literal: true

require "date"

require_relative "errors"

module Net
  class IMAP < Protocol
    module Types # :nodoc: all

      module Formats
        ASTRING     = /\A[^\0]*\z/n
        ATOM        = /\A#{ResponseParser::Patterns::ATOM}\z/n
        ATOM_CHAR   = ResponseParser::Patterns::ATOM_CHAR
        FILTER_NAME = %r{\A[#{ATOM_CHAR.source}&&[^/]]+\z}n
        OBJECTID    = /\A#{ResponseParser::Patterns::OBJECTID}\z/n
      end

      StringType = ->(name, regexp) {
        ->(value) {
          value = String.try_convert(value) or
          raise TypeError, "expected String, got %s" % [value.class]
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

      SearchKeyName = StringType["search-key name", Formats::ATOM]
      FlagKeyword   = StringType["flag-keyword",    Formats::ATOM]
      Astring       = StringType["astring",         Formats::ASTRING]
      HeaderFldName = StringType["header-fld-name", Formats::ASTRING]
      FilterName    = StringType["filter-name",     Formats::FILTER_NAME]
      ObjectID      = StringType["objectid",        Formats::OBJECTID]
      EnvelopeField = Astring
      FullText      = Astring

    end
  end
end
