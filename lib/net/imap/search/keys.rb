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
      OrKey         = Class.new(KeyListKey)
      SeqSetKey     = Data.define(:seqset)
      FlagKey       = Data.define(:name)
      UnaryKey      = Data.define(:name, :value)
      ModSeqKey     = Data.define(:entry_name, :entry_type_req, :modseq)
      AnnotationKey = Data.define(:entry_match, :att, :value)

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

      class OrKey
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
        known_names %w[KEYWORD UNKEYWORD]
        def validate_value(value) = Types::FlagKeyword[value]
      end

      class AstringKey < StringKey
        known_names %w[ BCC CC FROM SUBJECT TO ]  # Envelope
        known_names %w[ BODY TEXT ]               # Full text search
        def validate_value(value) = Types::Astring[value]
      end

      class ObjectIDKey < StringKey
        known_names %w[ EMAILID THREADID ]
        def validate_value(value) = Types::ObjectID[value]
      end

      class FilterKey < StringKey
        known_name "FILTER"
        def validate_value(value) = Types::FilterName[value]
      end

      class DateKey < UnaryKey
        known_names %w[      BEFORE      ON      SINCE ] # Internal Date
        known_names %w[  SENTBEFORE  SENTON  SENTSINCE ] # Date: header
        known_names %w[ SAVEDBEFORE SAVEDON SAVEDSINCE ] # SAVEDATE
        def coerce_value(value) = Types::Date[value]
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

      HeaderKey = Data.define(:field_name, :value) do
        def initialize(field_name:, value:)
          super field_name: Types::HeaderFldName[field_name],
                value:      Types::Astring[value]
        end
      end

      # MODSEQ (RFC7162)
      class ModSeqKey
        def initialize(entry_name: nil, entry_type_req: nil, modseq:)
          super
        end
      end

      # ANNOTATE-EXPERIMENT-1 (RFC5257)
      class AnnotationKey
      end

    end
  end
end
