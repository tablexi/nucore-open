# In Oracle, .lock(true) will create a "select * from (select ... FOR UPDATE)"
# Oracle does not allow locks in subqueries.
# TODO Remove this monkey patch once pull request is accepted
# https://github.com/collectiveidea/awesome_nested_set/pull/187
if NUCore::Database.oracle?
  Rails.application.config.to_prepare do
    module CollectiveIdea
      module Acts
        module NestedSet
          module Model
            def set_default_left_and_right
              highest_right_row = nested_set_scope(:order => "#{quoted_right_column_full_name} desc").first
              highest_right_row && highest_right_row.lock!

              maxright = highest_right_row ? (highest_right_row[right_column_name] || 0) : 0
              # adds the new node to the right of all existing nodes
              self[left_column_name] = maxright + 1
              self[right_column_name] = maxright + 2
            end
          end
        end
      end
    end
  end
end