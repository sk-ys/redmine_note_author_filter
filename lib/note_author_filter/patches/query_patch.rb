module NoteAuthorFilter
  module Patches
    module QueryPatch
      extend ActiveSupport::Concern

      included do
        include InstanceMethods

        alias_method :statement_without_notes_updated_by, :statement
        alias_method :statement, :statement_with_notes_updated_by
      end

      module InstanceMethods
        def statement_with_notes_updated_by
          # Replace "me" value to User.current
          IssueQuery::note_author_filter_keys.each do |key|
            if filters[key].is_a?(Hash)
              filters[key][:values] = filters[key][:values].map { |v| v == "me" ? User.current.id.to_s : v }
            end
          end

          statement_without_notes_updated_by
        end
      end
    end
  end
end

Query.send(:include, NoteAuthorFilter::Patches::QueryPatch)
