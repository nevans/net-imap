# frozen_string_literal: true

require "date"

require_relative "errors"

module Net
  class IMAP < Protocol
    module Types # :nodoc: all

      module Formats
        atom_char   = ResponseParser::Patterns::ATOM_CHAR
        ASTRING     = /\A[^\0]*\z/n
        ATOM        = /\A#{ResponseParser::Patterns::ATOM}\z/n
        FILTER_NAME = %r{\A[#{atom_char.source}&&[^/]]+\z}n
        LABEL       = /\A#{ResponseParser::Patterns::TAGGED_EXT_LABEL}\z/n
        OBJECTID    = /\A#{ResponseParser::Patterns::OBJECTID}\z/n
      end

      LabelType = ->(name, regexp = Formats::LABEL) {
        validation = StringType[name, regexp]
        ->(value) { validation[value.is_a?(Symbol) ? value.to_s : value] }
      }

      StringType = ->(name, regexp) {
        ->(value) {
          value = String.try_convert(value) or
            raise TypeError, "expected String, got %s" % [value.class]
          value.b.match?(regexp) or
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
        value in ::Date or raise TypeError, "expected date"
        value
      }

      TaggedExtLabel = LabelType["tagged-ext-label"]

      # Although no specification explicitly requires search-key extensions to
      # use the tagged-ext-label format, using another format seems unlikely.
      SearchKeyName  = LabelType["search-key name"]

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
