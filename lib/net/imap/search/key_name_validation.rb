# frozen_string_literal: true

module Net
  class IMAP < Protocol
    class Search

      module KeyNameValidation

        def self.included(mod)
          mod.extend ClassMethods
        end

        def initialize(name:, **) super(name: validate_name!(name), **) end

        module ClassMethods
          def known_names(names = nil)
            if names
              Array(names).each do known_name _1 end
              @known_names
            elsif @known_names
              @known_names
            else
              subclasses.map(&:known_names).reduce(Set.new, &:merge)
            end
          end

          def known_name(name) = (@known_names ||= Set.new) << -name.to_s.upcase

          def match_name = ->name { known_name? name }
          def known_name?(val)
            str = val.to_s and known_names.any? { _1.casecmp? str }
          end

          def validate_name!(name)
            Types::SearchKeyName[name]
            case name
            when method(:known_name?)
              name.is_a?(Symbol) ? name.upcase.name : -name
            when String
              warn("Possibly invalid search key: #{name}.  " \
                   "To silence warning: " \
                   "`#{self}.known_name #{name.dump}`")
              -name
            when Symbol
              raise DataFormatError, "unknown flag search-key: %p" % [name]
            end
          end
        end

        private

        def validate_name!(name) = self.class.validate_name!(name)
      end
    end
  end
end

