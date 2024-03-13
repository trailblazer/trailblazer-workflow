module Trailblazer
  module Workflow
    module Introspect
      # Rendering-specific code using {Iteration::Set}.
        # Each row represents a configuration of suspends aka "state".
        # The state knows its possible resume events.
        #   does the state know which state fields belong to it?
      class StateTable < Trailblazer::Activity::Railway
        step :aggregate_by_state
        step :render_data

        def aggregate_by_state(ctx, iteration_set:, **)
          # Key by lane_positions, which represent a state.
          # State (lane_positions) => [events (start position)]
          states = {}

          # Collect the invoked start positions per Positions configuration.
          # This implies the possible "catch events" per configuration.
          iteration_set.collect do |iteration|
            start_positions = iteration.start_positions
            start_task_position = iteration.start_task_position

            events = states[start_positions]
            events = [] if events.nil?

            events += [start_task_position]

            states[start_positions] = events.uniq # TODO: this {uniq} is not explicitly tested.
          end

          ctx[:states] = states
        end

        def render_data(ctx, states:, lanes_cfg:, **)
          cli_rows = states.flat_map do |positions, catch_events|
            suggested_state_name = suggested_state_name_for(catch_events)

            suggested_state_name = "⏸︎ #{suggested_state_name}"

            triggerable_events = catch_events
              .collect { |event_position| Present.readable_name_for_catch_event(*event_position.to_a, lanes_cfg: lanes_cfg).inspect }
              .join(", ")


            Hash[
              "state name",
              suggested_state_name,

              "triggerable events",
              triggerable_events,

              :positions,
              positions,

              :catch_events, # this is triggerable_events as objects, not human-readable.
              catch_events
            ]
          end

          ctx[:rows] = cli_rows
        end

        def suggested_state_name_for(catch_events)
          catch_events
            .collect { |event_position| Present.label_for_next_task(*event_position.to_a) }
            .uniq
            .join("♦")
        end

        # Render the actual table, for CLI.
        class Render < Trailblazer::Activity::Railway
          step Subprocess(StateTable)
          step :render
          def render(ctx, rows:, **)
            cli_rows = rows.collect { |row| row.merge("state name" => row["state name"].inspect) }

            columns = ["state name", "triggerable events"]
            ctx[:table] = Present::Table.render(columns, cli_rows)
          end
        end
      end
    end # Introspect
  end
end
