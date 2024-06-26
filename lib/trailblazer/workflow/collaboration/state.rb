module Trailblazer
  module Workflow
    module State
      # Finding a configuration for a specific event:
      # 1. From the event label, figure out lane and event ID.
      # 2. a StateTable instance knows which event ID maps to one or many configurations.
      # 3. Resolver finds the matching configuration by running the respective state guards.
      class Resolver
        def initialize(guards, table)
          @guards = guards
          @table = table
        end

        def call(lane_label, catch_id, args, **kws)
          # First, find all state guards that "point to" this catch event.
          possible_states = @table.find_all { |state_name, cfg| cfg[:catch_tuples].include?([lane_label, catch_id]) }

          # Execute those, the first returning true indicates the configuration.
          target_state = possible_states.find { |state_name, cfg| @guards.(state_name, args, **kws) }

          return target_state, possible_states
        end
      end
    end
  end
end
