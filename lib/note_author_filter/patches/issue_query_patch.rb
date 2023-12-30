module NoteAuthorFilter
  module Patches
    module IssueQueryPatch
      extend ActiveSupport::Concern

      included do
        prepend InstanceOverwriteMethods
        include InstanceMethods

        alias_method :initialize_available_filters_without_notes_author_filter, :initialize_available_filters
        alias_method :initialize_available_filters, :initialize_available_filters_with_notes_author_filter

        class_attribute :notes_author_filter_keys
        self.notes_author_filter_keys = [
          "notes_created_by",
          "last_notes_created_by"
        ] +
        ((Redmine::VERSION::MAJOR >= 5 && Redmine::VERSION::MINOR >= 1) || Redmine::VERSION::MAJOR >= 6 ?
          [
            "notes_updated_by",
            "last_notes_updated_by",
            "notes_created_or_updated_by",
            "last_notes_created_or_updated_by"
          ] : [])
      end

      module InstanceOverwriteMethods
        def build_from_params(params, defaults = {})
          super

          notes_author_filter_keys.each do |notes_author_filter_key|
            add_filter notes_author_filter_key, '=', User
          end

          self
        end

        def sql_for_notes_created_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, false, true, false)
          "#{neg} EXISTS (#{subquery})"
        end
        def sql_for_last_notes_created_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, true, true, false)
          "#{neg} EXISTS (#{subquery})"
        end

        def sql_for_notes_updated_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, false, false, true)
          "#{neg} EXISTS (#{subquery})"
        end
        def sql_for_last_notes_updated_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, true, false, true)
          "#{neg} EXISTS (#{subquery})"
        end

        def sql_for_notes_created_or_updated_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, false, true, true)
          "#{neg} EXISTS (#{subquery})"
        end
        def sql_for_last_notes_created_or_updated_by_field(field, operator, value)
          neg = (operator == '!' ? 'NOT' : '')
          subquery = generate_subquery(field, operator, value, true, true, true)
          "#{neg} EXISTS (#{subquery})"
        end
      end

      module InstanceMethods
        def initialize_available_filters_with_notes_author_filter
          initialize_available_filters_without_notes_author_filter

          notes_author_filter_keys.each do |notes_author_filter_key|
            add_available_filter(notes_author_filter_key, type: :list, values: lambda {author_values})
          end
        end
      end

      def generate_subquery(field, operator, value, last, created, updated)
        if last
          "SELECT 1 FROM #{Journal.table_name} sj" +
          " WHERE sj.journalized_type='Issue'" +
          " AND sj.journalized_id=#{Issue.table_name}.id" +
          " AND (" +
            (created ? "#{sql_for_field field, '=', value, 'sj', 'user_id'}" : "") +
            ((created & updated) ? " OR " : "") +
            (updated ? "#{sql_for_field field, '=', value, 'sj', 'updated_by_id'}" : "") +
          ")" +
          " AND sj.id IN (SELECT MAX(#{Journal.table_name}.id) FROM #{Journal.table_name}" +
          "   WHERE #{Journal.table_name}.journalized_type='Issue' AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id" +
          "   AND (#{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)})" +
          "   AND notes != '')"
        else
          "SELECT 1 FROM #{Journal.table_name}" +
          " WHERE #{Journal.table_name}.journalized_type='Issue'" +
          " AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id" +
          " AND (" +
            (created ? "#{sql_for_field field, '=', value, Journal.table_name, 'user_id'}" : "") +
            ((created & updated) ? " OR " : "") +
            (updated ? "#{sql_for_field field, '=', value, Journal.table_name, 'updated_by_id'}" : "") +
          ")" +
          " AND (#{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)})" +
          " AND notes != ''"
        end
      end
    end
  end
end

IssueQuery.send(:include, NoteAuthorFilter::Patches::IssueQueryPatch)
