# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      KeyName = ->(name) {
        key  = Types::SearchKeyName[name].to_sym.downcase
        name = key.upcase.name unless name == key
        Module.new do
          singleton_class.define_method(:to_s) {
            "%s::KeyName[%p]" % [Search, name]
          }
          define_method(:key)  { key  }
          define_method(:name) { name }
        end
      }

      class Key < Data
        def self.define_with_name(*attrs, name:, &block)
          define(*attrs) do
            extend KeyName[name]
            class_exec(&block) if block
          end
        end

        def to_a = [name, *deconstruct]
        def to_h = {key => value}
        def name = self.class.name
        def key  = self.class.key
      end

      # A search-key (or pseudo-search-key) composed of a list of keys.
      class KeyListKey < Key.define(:keys)
        def self.[](*keys)    = new(keys:)
        def initialize(keys:) = super keys: KeyList.new(keys).keys
        def deconstruct       = keys.deconstruct
      end

      AndKey        = Class.new(KeyListKey)
      OrKey         = Class.new(KeyListKey)
      SeqSetKey     = Key.define(:seqset)
      UnaryKey      = Key.define(:name, :value)

      FlagKey       = Key.define(:name)
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

      class SeqSetKey
        def initialize(seqset:) = super seqset: SequenceSet[seqset]
      end

      class UIDKey < SeqSetKey
        def self.match_name = /UID/i
      end

      class UnaryKey
        include KeyNameValidation
        def initialize(name:, value:)
          super name:, value: coerce_value(value)
        end
      end

      class StringKey < UnaryKey
        def coerce_value(value)
          String.try_convert(value) or raise TypeError, "expected String"
        end
      end

      class KeywordKey < StringKey
        known_names %w[KEYWORD UNKEYWORD]
        def coerce_value(value) = Types::FlagKeyword[value]
      end

      class AstringKey < StringKey
        known_names %w[ BCC CC FROM SUBJECT TO ]  # Envelope
        known_names %w[ BODY TEXT ]               # Full text search
        def coerce_value(value) = Types::Astring[value]
      end

      class ObjectIDKey < StringKey
        known_names %w[ EMAILID THREADID ]
        def coerce_value(value) = Types::ObjectID[value]
      end

      class FilterKey < StringKey
        known_name "FILTER"
        def coerce_value(value) = Types::FilterName[value]
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

      class HeaderKey < Key.define(:field_name, :value)
        def initialize(field_name:, value:)
          super field_name: Types::HeaderFldName[field_name],
                value:      Types::Astring[value]
        end
      end

      # MODSEQ (RFC7162)
      class ModSeqKey < Key.define(:entry_name, :entry_type_req, :modseq)
        def self.[](*args, **kwargs)
          (args in [modseq]) ? super(nil, nil, modseq, **kwargs) : super
        end

        def initialize(modseq:, entry_name: nil, entry_type_req: nil)
          unless entry_name.nil? && entry_type_req.nil?
            entry_name     = Types::EntryName[entry_name]
            entry_type_req = Types::EntryTypeReq[entry_type_req]
          end
          modseq = Types::ModSequenceValzer[modseq]
          super
        end

        def deconstruct = super.compact
      end

      # ANNOTATE-EXPERIMENT-1 (RFC5257)
      class AnnotationKey < Key.define(:entry_match, :att, :value)
      end

    end
  end
end
