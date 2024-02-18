module Trailblazer
  module Workflow
    module Discovery
      # Rendering-specific code using {Discovery:states}.
      module Present
        module StateTable
          module_function

          # Each row represents a configuration of suspends aka "state".
          # The state knows its possible resume events.
          #   does the state know which state fields belong to it?
          def call(discovered_states, lanes_cfg:)
            # raise discovery_state_table.inspect
            start_position_to_catch = {}

            # Key by lane_positions, which represent a state.
            # State (lane_positions) => [events (start position)]
            states = {}

            # Collect the invoked start positions per Positions configuration.
            # This implies the possible "catch events" per configuration.
            discovered_states.each do |row|
              positions_before, start_position = row[:positions_before]

              events = states[positions_before]
              events = [] if events.nil?

              events << start_position

              states[positions_before] = events
            end

            # render
            cli_rows = states.flat_map do |configuration, catch_events|
              suggested_state_name = suggested_state_name_for(catch_events)

              suggested_state_name = "⏸︎ #{suggested_state_name}".inspect

              triggerable_events = catch_events
                .collect { |event_position| Present.readable_name_for_catch_event(*event_position.to_a, lanes_cfg: lanes_cfg).inspect }
                .uniq
                .join(", ")


              Hash[
                "state name",
                suggested_state_name,

                "triggerable events",
                triggerable_events
              ]
            end

            columns = ["state name", "triggerable events"]
            Present::Table.render(columns, cli_rows)
          end

          # @private
          # TODO: move to StateTable
          def suggested_state_name_for(catch_events)
            catch_events
              .collect { |event_position| Present.label_for_next_task(*event_position.to_a) }
              .uniq
              .join("/")
          end
        end
      end
    end
  end
end
