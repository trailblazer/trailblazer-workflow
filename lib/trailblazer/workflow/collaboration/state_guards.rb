module Trailblazer
  module Workflow
    class Collaboration
      # Maintains catch events and their particular state guard and allows
      # evaluating the guard using `#call`.
      #
      # This is used in Advance.
      #
      class StateGuards
        # Compile time
        # Note: this is called at every boot-up and needs to be reasonably fast, as we're mapping
        #       catch events to state guards.
        def self.from_user_hash(state_guards_cfg, state_table:)
          catch_2_guard = state_guards_cfg.flat_map do |state_label, user_cfg|
            catch_event_ids = state_table.fetch(state_label)[:id] # raise if we don't know this state label.

            catch_event_ids.collect { |catch_id| [catch_id, user_cfg[:guard]] }
          end

          StateGuards.new(catch_2_guard.to_h)
        end

        def initialize(catch_2_guard)
          @catch_2_guard = catch_2_guard
        end

        def call(ctx, start_task_position:)
          catch_id = Trailblazer::Activity::Introspect.Nodes(start_task_position.activity, task: start_task_position.task).id # TODO: do that at compile-time.

          @catch_2_guard.fetch(catch_id).(ctx, **ctx.to_hash) # TODO: discuss exec interface
        end
      end
    end # Collaboration
  end
end
