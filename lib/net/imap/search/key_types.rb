# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyTypes
        @registry = {}
        def self.[](name)   = @registry[name]
        def self.fetch(...) = @registry.fetch(...)

        def self.search_key(const_name, types = {}, &)
          key_name = Types::SearchKeyName[const_name].to_sym.downcase
          key_type = new(key_name, types, &)
          const_set const_name, key_type
          @registry[key_type.key] = key_type
        end

        def self.new(key_name, types = {}, &block)
          unless types.nil? || types.is_a?(Hash)
            types = {key_name.to_sym.downcase => types}
          end
          Key.define(*types.keys) do
            extend  KeyTypes.named key_name
            include KeyTypes.typed types if types
          end
            .then { block ? Class.new(_1, &block) : _1 }
        end

        def self.named(key_name)
          Module.new do
            define_method(:key) { key_name }
          end
        end

        def self.typed(types)
          types = types.dup.freeze

          Module.new do
            const_set :TYPES, types

            const_set(:ClassMethods, Module.new do
              def member_types     = self::MemberTypes::TYPES
              def member_type(key) = member_types.fetch(key)

              def coerce(**kwargs)
                kwargs.to_h {|key, value| [key, member_type(key)[value]] }
              end
            end)

            singleton_class.define_method :included do |mod|
              mod.const_set :MemberTypes, self
              mod.extend self::ClassMethods
            end

            def initialize(**kwargs) = super(**coerce(**kwargs))

            private

            def coerce(...) = self.class.coerce(...)
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

        search_key :Keyword,      Types::FlagKeyword
        search_key :Unkeyword,    Types::FlagKeyword

        search_key :Seq, SequenceSet do
          def name = key
          def to_a = [seq]
        end

        search_key :UID,          SequenceSet

        search_key :Filter,       Types::FilterName

        search_key :EmailID,      Types::ObjectID
        search_key :ThreadID,     Types::ObjectID

        # Substring matching (should be case-insensitive)
        search_key :From,         Types::EnvelopeField
        search_key :To,           Types::EnvelopeField
        search_key :Cc,           Types::EnvelopeField
        search_key :Bcc,          Types::EnvelopeField
        search_key :Subject,      Types::EnvelopeField

        # "Full text" searching (may use stemming, etc)
        search_key :Body,         Types::FullText
        search_key :Text,         Types::FullText

        # Internal Date
        search_key :Before,       Types::Date
        search_key :On,           Types::Date
        search_key :Since,        Types::Date

        # "Date:" header
        search_key :SentBefore,   Types::Date
        search_key :SentOn,       Types::Date
        search_key :SentSince,    Types::Date

        # SAVEDATE extension [RFC8514]
        search_key :SavedBefore,  Types::Date
        search_key :SavedOn,      Types::Date
        search_key :SavedSince,   Types::Date

        # RFC822.SIZE
        search_key :Larger,       Types::Number64
        search_key :Smaller,      Types::Number64

        # Internal Date (WITHIN extension [RFC5032])
        search_key :Older,        Types::NzNumber
        search_key :Younger,      Types::NzNumber

        search_key(:Header,
                   field_name: Types::HeaderFldName,
                   substring:  Types::Astring)

        # Modification sequence number (CONDSTORE extension [RFC7162])
        search_key(:ModSeq,
                   entry_name:     Types::EntryName,
                   entry_type_req: Types::EntryTypeReq,
                   modseq:         Types::ModSequenceValzer) do
          def self.[](*args, **kwargs)
            (args in [modseq]) ? super(nil, nil, modseq, **kwargs) : super
          end

          def initialize(...)
            super
            entry_name && !entry_type_req and
              raise DataFormatError, "missing entry-type-req"
            !entry_name && entry_type_req and
              raise DataFormatError, "missing entry-name"
          end

          def deconstruct = super.compact
        end

        # Annotations (ANNOTATE-EXPERIMENT-1 extension [RFC5257])
        search_key(:Annotation,
                   entry_match: Types::EntryMatch,
                   att:         Types::AttSearch,
                   data:        Types::NString8)

        search_key(
          :Generic,
          name: Types::SearchKeyName,
          args: method(:Array)
        ) do
          def self.[](*args, **kwargs)
            (args in name, *rest) ? super(name, rest, **kwargs) : super
          end

          def key = name
          def deconstruct = to_a
        end

        # See https://developers.google.com/gmail/imap/imap-extensions#extension_of_the_search_command_x-gm-raw
        search_key :XGmRaw, Types::Astring do
          def self.key = :x_gm_raw
          def name = "X-GM-RAW"
        end

        # See https://developers.google.com/gmail/imap/imap-extensions#access_to_the_unique_message_id_x-gm-msgid
        search_key :XGmMsgID, Types::UInt64 do
          def self.key = :x_gm_msgid
          def name = "X-GM-MSGID"
        end

        # See https://developers.google.com/gmail/imap/imap-extensions#access_to_the_thread_id_x-gm-thrid
        search_key :XGmThrID, Types::UInt64 do
          def self.key = :x_gm_thrid
          def name = "X-GM-THRID"
        end

      end

    end
  end
end
