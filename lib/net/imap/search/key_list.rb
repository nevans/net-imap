# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      class KeyList
        def self.[](*keys) new(keys) end

        attr_reader :keys
        alias deconstruct keys

        def initialize(keys)
          @keys = extract_keys(keys)
          raise DataFormatError, "invalid empty search keys" if @keys.empty?
        end

        private

        def extract_keys(keys)
          case keys
          when Array then Params.new(keys).keys
          when Hash  then KeysHash.new(keys).keys
          else raise DataFormatError, "invalid search-key list"
          end
        end

        class Params < KeyList
          private

          def extract_keys(keys)
            keys.flat_map {|value|
              case value
              when SequenceSet::Coercible then KeyTypes::Seq[value]
              when String, Symbol         then nullary_key(value)
              when Array                  then AndKey[*value]
              when Hash                   then KeysHash.new(value).keys
              else raise DataFormatError, "invalid search-key: %p" % [value]
              end
            }
          end

          def nullary_key(name)
            KeysHash[name.downcase.to_sym => true].keys
            # TODO: rescue unknown strings as KeyType::Generic?
          end

        end

        class KeysHash
          def self.[](...) = new(...)

          attr_reader :prefix, :input

          def initialize(*prefix, input)
            @prefix = prefix
            @input = Hash.try_convert(input) or raise TypeError, "expected hash"
          end

          def keys      = inputs.map         { input_to_key(*_1) }
          def inputs    = compacted.flat_map { entry_to_inputs _1, _2 }
          def compacted = input.compact # TODO

          private

          def recursive?(name)
            return true if name == :and
            name = name.to_s
            %w[OR NOT FUZZY].any? { _1.casecmp?(name) }
          end

          def entry_to_inputs(key, value)
            name = prefix.empty? ? key : prefix.first
            name in String | Symbol or
              raise TypeError, "expected string or symbol search-key name"
            return [[*prefix, key, value]] if recursive?(name)
            case value
            when true  then prefix.empty? ? key : [[*prefix, key]]
            when false then negate(*prefix, key)
            when Hash  then KeysHash[*prefix, key, value].inputs
            else            [[*prefix, key, value]]
            end
          end

          def negate(name, *args)
            name = name.is_a?(Symbol) ? :"un#{name}" : "UN#{name}"
            [name, *args]
          end

          # TODO: OR
          # TODO: NOT, FUZZY
          # TODO: HEADER
          # TODO: MODSEQ
          # TODO: ANNOTATE
          def input_to_key(key, *rest)
            key in Symbol | Types::Formats::LABEL or
              raise TypeError, "expected string or symbol key"
            case key
            when :all                   then KeyTypes::All[*rest]
            when :savedatesupported     then KeyTypes::SaveDateSupported[*rest]
            when :answered              then KeyTypes::Answered[*rest]
            when :unanswered            then KeyTypes::Unanswered[*rest]
            when :deleted               then KeyTypes::Deleted[*rest]
            when :undeleted             then KeyTypes::Undeleted[*rest]
            when :draft                 then KeyTypes::Draft[*rest]
            when :undraft               then KeyTypes::Undraft[*rest]
            when :flagged               then KeyTypes::Flagged[*rest]
            when :unflagged             then KeyTypes::Unflagged[*rest]
            when :seen                  then KeyTypes::Seen[*rest]
            when :unseen                then KeyTypes::Unseen[*rest]
            when :uid                   then KeyTypes::UID[*rest]
            when :seq                   then KeyTypes::Seq[*rest]
            when :keyword               then KeyTypes::Keyword[*rest]
            when :unkeyword             then KeyTypes::Unkeyword[*rest]
            when :filter                then KeyTypes::Filter[*rest]
            when :emailid               then KeyTypes::EmailID[*rest]
            when :threadid              then KeyTypes::ThreadID[*rest]
            when :from                  then KeyTypes::From[*rest]
            when :to                    then KeyTypes::To[*rest]
            when :cc                    then KeyTypes::Cc[*rest]
            when :bcc                   then KeyTypes::Bcc[*rest]
            when :subject               then KeyTypes::Subject[*rest]
            when :body                  then KeyTypes::Body[*rest]
            when :text                  then KeyTypes::Text[*rest]
            when :before                then KeyTypes::Before[*rest]
            when :on                    then KeyTypes::On[*rest]
            when :since                 then KeyTypes::Since[*rest]
            when :sentbefore            then KeyTypes::SentBefore[*rest]
            when :senton                then KeyTypes::SentOn[*rest]
            when :sentsince             then KeyTypes::SentSince[*rest]
            when :savedbefore           then KeyTypes::SavedBefore[*rest]
            when :savedon               then KeyTypes::SavedOn[*rest]
            when :savedsince            then KeyTypes::SavedSince[*rest]
            when :larger                then KeyTypes::Larger[*rest]
            when :smaller               then KeyTypes::Smaller[*rest]
            when :older                 then KeyTypes::Older[*rest]
            when :younger               then KeyTypes::Younger[*rest]
            when :x_gm_raw              then KeyTypes::XGmRaw[*rest]
            when :x_gm_msgid            then KeyTypes::XGmMsgID[*rest]
            when :x_gm_thrid            then KeyTypes::XGmThrID[*rest]
            when :header                then KeyTypes::Header[*rest]
            when :modseq                then KeyTypes::ModSeq[*rest]
            when :annotation            then KeyTypes::Annotation[*rest]

            when :and                   then AndKey.new(*rest)
            when :or                    then OrKey.new(*rest)
            when :not                   then NotKey.new(*rest)
            when :fuzzy                 then FuzzyKey.new(*rest)

            when Types::Formats::LABEL  then KeyTypes::Generic[key, *rest]
            else
              raise DataFormatError, "unknown search-key: %p" % [key]
            end
          end

          def bool_key(key, bool)
            case bool
            when true  then key
            when false then key.is_a?(Symbol) ? :"un#{key}" : "UN#{key}"
            else
              raise DataFormatError, "invalid search-key: %p => %p" % [
                key, bool
              ]
            end
          end

        end

      end
    end
  end
end
