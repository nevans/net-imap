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
            raise DataFormatError, "invalid #{name} string"
          value
        }
      }

      NumberType = ->(name, min:, bits:) {
        [name, min, bits] => [String, 0 | 1, Integer]
        range = (min.zero? ? 0 : 1)..(2**bits - 1)
        desc  = "#{min.zero? ? "a non-zero" : "an"} unsigned integer"
        ->(num) {
          num = Integer(num)
          range.cover?(num) or raise DataFormatError, "#{name} must be #{desc}"
          num
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

      Number            = NumberType["number",              min: 0, bits: 32]
      NzNumber          = NumberType["nz-number",           min: 1, bits: 32]
      ModSequenceValue  = NumberType["mod-sequence-value",  min: 1, bits: 63]
      ModSequenceValzer = NumberType["mod-sequence-valzer", min: 0, bits: 63]

    end
  end
end
