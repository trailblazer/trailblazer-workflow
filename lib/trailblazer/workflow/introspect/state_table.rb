module Trailblazer
  module Workflow
    module Introspect
      # Rendering-specific code using {Iteration::Set}.
        # Each row represents a configuration of suspends aka "state".
        # The state knows its possible resume events.
        # DISCUSS: does the state know which state fields belong to it?
      class StateTable < Trailblazer::Activity::Railway
        step :aggregate_by_state
        step :render_data

        def aggregate_by_state(ctx, iteration_set:, lanes_cfg:, **)
          # Key by lane_positions, which represent a state.
          # State (lane_positions) => [events (start position)]
          states = {}

          # Collect the invoked start positions per Positions configuration.
          # This implies the possible "catch events" per configuration.
          iteration_set.collect do |iteration|
            start_positions = iteration.start_positions
            start_task_position = iteration.start_task_position

            events = states[start_positions] || []

            events += [start_task_position]

            states[start_positions] = events.uniq # TODO: this {uniq} is not explicitly tested.
          end

          ctx[:states] = states
        end

        # DISCUSS: at some point, we need to separate data computing and rendering here.
        def render_data(ctx, states:, lanes_cfg:, **)
          suggested_state_names = {}

          cli_rows = states.flat_map do |start_positions, catch_events|
            suspend_tuples = start_positions.to_a.collect do |position|
              Iteration::Set::Serialize.id_tuple_for(*position.to_a, lanes_cfg: lanes_cfg)
            end

            suspend_id_hints = start_positions.to_a.collect do |position| # DISCUSS: are these start_positions ordered lifecycle,UI,reviewer, always?
              [Introspect::Present.lane_label_for(*position.to_a, lanes_cfg: lanes_cfg), Test::Plan::Introspect.id_hint_for_suspend_position(*position.to_a)].join(" ")
            end

            readable_suspend_id_hints = suspend_id_hints.join(" ")

            suggested_state_name = suggested_state_name_for(catch_events)

            suggested_state_name = "⏸︎ #{suggested_state_name}"

            # add an "ID hint" to the state name (part of the actual suspend gw's ID).
            if suggested_state_names[suggested_state_name]
              last_lane = catch_events[0].activity # DISCUSS: could be more explicit.

              suggested_state_name = "#{suggested_state_name}"
            else
              suggested_state_names[suggested_state_name] = true
            end

            triggerable_events = catch_events
              .collect { |event_position| Present.readable_name_for_catch_event(*event_position.to_a, lanes_cfg: lanes_cfg).inspect }
              .join(", ")


            Hash[
              "state name",
              suggested_state_name,

              "triggerable events",
              triggerable_events,

              "Suspend IDs",
              readable_suspend_id_hints,

              :suspend_tuples,
              suspend_tuples,

              :start_positions,
              start_positions,

              :catch_events, # this is triggerable_events as objects, not human-readable.
              catch_events
            ]
          end

          cli_rows = cli_rows.sort { |a, b| a["state name"] <=> b["state name"] }

          ctx[:rows] = cli_rows
        end

        def suggested_state_name_for(catch_events)
          catch_events
            .collect { |event_position| Present.label_for_next_task(*event_position.to_a) }
            .uniq
            .join("♦")
        end

        # Render the actual table, for CLI and debugging.
        class Render < Trailblazer::Activity::Railway
          step Subprocess(StateTable)
          step :render
          def render(ctx, rows:, **)
            cli_rows = rows.collect { |row| row.merge("state name" => row["state name"].inspect) }

            columns = ["state name", "triggerable events", "Suspend IDs"]
            ctx[:table] = Present::Table.render(columns, cli_rows)
          end
        end
      end
    end # Introspect
  end
end
