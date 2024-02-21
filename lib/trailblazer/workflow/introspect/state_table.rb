module Trailblazer
  module Workflow
    module Introspect
      # Rendering-specific code using {Iteration::Set}.
      module StateTable
        module_function

        # Each row represents a configuration of suspends aka "state".
        # The state knows its possible resume events.
        #   does the state know which state fields belong to it?
        def call(iteration_set, lanes_cfg:)
          states = aggregate_by_state(iteration_set)

          cli_rows = render_data(states, lanes_cfg: lanes_cfg)

          cli_rows = cli_rows.collect { |row| row.merge("state name" => row["state name"].inspect) }

          columns = ["state name", "triggerable events"]
          Present::Table.render(columns, cli_rows)
        end

        def aggregate_by_state(iteration_set)
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

            states[start_positions] = events
          end

          states
        end

        def render_data(states, lanes_cfg:)
          cli_rows = states.flat_map do |positions, catch_events|
            suggested_state_name = suggested_state_name_for(catch_events)

            suggested_state_name = "⏸︎ #{suggested_state_name}"

            triggerable_events = catch_events
              .collect { |event_position| Present.readable_name_for_catch_event(*event_position.to_a, lanes_cfg: lanes_cfg).inspect }
              .uniq
              .join(", ")


            Hash[
              "state name",
              suggested_state_name,

              "triggerable events",
              triggerable_events,

              :positions,
              positions,

              :catch_events,
              catch_events
            ]
          end
        end

        # @private
        # TODO: move to StateTable
        def suggested_state_name_for(catch_events)
          catch_events
            .collect { |event_position| Present.label_for_next_task(*event_position.to_a) }
            .uniq
            .join("♦")
        end

        # Generate code stubs for a state guard class.
        module Generate
          module_function

          def call(iteration_set, **options)
            states    = StateTable.aggregate_by_state(iteration_set)
            cli_rows  = StateTable.render_data(states, **options)

            available_states = cli_rows.collect do |row|
              {
                suggested_state_name: row["state name"],
                key: row[:catch_events].collect { |position| Present.id_for_position(position) }.uniq.sort
              }
            end

            # user_configuration = available_states.collect do |row|
            #   [
            #     row["state_name"],
            #     {
            #       guard: %()
            #     }
            #   ]
            # end

            # formatting, find longest state name.
            max_length = available_states.collect { |row| row[:suggested_state_name].length }.max

            state_guard_rows = available_states.collect do |row|
              %(  #{row[:suggested_state_name].ljust(max_length).inspect} => {guard: ->(ctx, process_model:, **) { raise "implement me!" }})
            end.join("\n")

            snippet = %(
state_guards: {
#{state_guard_rows}
}
)
          end
        end
      end
    end
  end
end
