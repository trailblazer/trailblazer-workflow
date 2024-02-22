module Trailblazer
  module Workflow
    class Collaboration
      # Maintains catch events and their particular state guard and allows
      # evaluating the guard using `#call`.
      #
      # This is used in Advance.
      class StateGuards
        # Generate
        # Compile time
        def self.from_user_hash(state_guards_cfg, iteration_set:)
          # DISCUSS: Do we really need this table?
          state_table = Trailblazer::Workflow::Introspect::StateTable.aggregate_by_state(iteration_set)

          # TODO: make smarter keying so we don't need to do this finding here all the time.
          catch_2_guard = state_guards_cfg.flat_map do |state_label, user_cfg|
            start_positions, catch_positions = state_table.find do |start_positions, catch_events|
              catch_events.collect { |event_position| Introspect::Present.id_for_position(event_position) }.sort == user_cfg[:id]
            end

            raise "unknown state id #{user_cfg[:id]}" if start_positions.nil? # FIXME: test this case.

            catch_positions.collect { |catch_position| [catch_position, user_cfg[:guard]] }
          end

          StateGuards.new(catch_2_guard.to_h)
        end

        def initialize(catch_2_guard)
          @catch_2_guard = catch_2_guard
        end

        def call(ctx, start_task_position:)
          @catch_2_guard.fetch(start_task_position).(ctx, **ctx.to_hash) # TODO: discuss exec interface
        end
      end
    end # Collaboration
  end
end
