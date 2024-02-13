# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      # A search-key (or pseudo-search-key) composed of a list of keys.
      class KeyListKey
        attr_reader :key_list
        def self.[](*keys)        = new keys
        def initialize(keys)      = @key_list = KeyList.new(keys)
        def keys                  = key_list.keys
        def deconstruct           = key_list.deconstruct
      end

      AndKey        = Class.new(KeyListKey)
      SeqSetKey     = Data.define(:seqset)
      FlagKey       = Data.define(:name)
      UnaryKey      = Data.define(:name, :value)
      class FlagKey
        include KeyNameValidation

        # RFC3501, RFC9051
        known_names %w[
          ALL
          ANSWERED  UNANSWERED
          DELETED   UNDELETED
          DRAFT     UNDRAFT
          FLAGGED   UNFLAGGED
          SEEN      UNSEEN
        ]
        known_name "SAVEDATESUPPORTED" # SAVEDATE [RFC8514]
      end

      class AndKey
      end

      class SeqSetKey
        def initialize(seqset:)
          super seqset: SequenceSet[seqset]
        end
      end

      class UnaryKey
        include KeyNameValidation
        def initialize(name:, value:)
          value = coerce_value(value)
          validate_value(value)
          super
        end
        def validate_value(value) = nil # assume coerce_value handles it...
      end

      class UIDKey < SeqSetKey
        def self.match_name = /UID/i
      end

      class StringKey < UnaryKey
        def coerce_value(value)
          String.try_convert(value) or raise TypeError, "expected String"
        end
      end

      class KeywordKey < StringKey
        FORMAT = /\A#{ResponseParser::Patterns::ATOM}\z/n
        # RFC3501, RFC9051
        known_names %w[KEYWORD UNKEYWORD]

        def validate_value(value)
          value.b.match?(FORMAT) or
            raise DataFormatError, "invalid flag-keyword string"
        end
      end

      class AstringKey < StringKey
        known_names %w[ BCC CC FROM SUBJECT TO ]  # Envelope
        known_names %w[ BODY TEXT ]               # Full text search

        def validate_value(value)
          value.b.include?("\0".b) and
            raise DataFormatError, "string contains illegal NULL character"
        end
      end

      class ObjectIDKey < StringKey
        FORMAT = /\A#{ResponseParser::Patterns::OBJECTID}\z/n
        known_names %w[ EMAILID THREADID ]

        def validate_value(value)
          value.b.match?(FORMAT) or
            raise DataFormatError, "invalid objectid string"
        end
      end

      class FilterKey < StringKey
        # filter-name           =  1*<any ATOM-CHAR except "/">
        ATOM_CHAR = ResponseParser::Patterns::ATOM_CHAR
        FORMAT = %r{\A[#{ATOM_CHAR.source}&&[^/]]+\z}n
        known_name "FILTER"

        def validate_value(value)
          value.b.match?(FORMAT) or
            raise DataFormatError, "invalid filter-name string"
        end
      end

      class DateKey < UnaryKey
        known_names %w[      BEFORE      ON      SINCE ] # Internal Date
        known_names %w[  SENTBEFORE  SENTON  SENTSINCE ] # Date: header
        known_names %w[ SAVEDBEFORE SAVEDON SAVEDSINCE ] # SAVEDATE

        def coerce_value(value)
          if value.respond_to?(:to_date)
            value = value.to_date
          elsif value.respond_to?(:to_str)
            value = IMAP.decode_date(value.to_str)
          end
          value in Date or raise TypeError, "expected date"
          value
        end
      end

      class NumberKey < UnaryKey
        def coerce_value(value) = Integer(value)
      end

      class Number64Key < NumberKey
        known_names %w[ LARGER SMALLER ]
      end

      class NzNumberKey < NumberKey
        known_names %w[  OLDER YOUNGER ] # Internal Date (WITHIN extension)
      end

    end
  end
end
