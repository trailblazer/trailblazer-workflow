module Trailblazer
  module Workflow
    module Generate
      # State guards are code blocks defined by the user to allow/deny executing
      # a catch event.
      module StateGuards
          module_function

          def call(iteration_set, namespace:, **options)
            states    = StateTable.aggregate_by_state(iteration_set)
            cli_rows  = StateTable.render_data(states, **options)

            available_states = cli_rows.collect do |row|
              {
                suggested_state_name: row["state name"],
                key: row[:catch_events].collect { |position| Present.id_for_position(position) }.uniq.sort
              }
            end

            # formatting, find longest state name.
            max_length = available_states.collect { |row| row[:suggested_state_name].inspect.length }.max

            state_guard_rows = available_states.collect do |row|
              id_snippet = %(, id: #{row[:key].inspect}) # TODO: move me to serializer code.

              %(  #{row[:suggested_state_name].inspect.ljust(max_length)} => {guard: ->(ctx, process_model:, **) { raise "implement me!" }#{id_snippet}},)
            end.join("\n")

            snippet = %(#{namespace}::StateGuards = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash({
#{state_guard_rows}
})
)
          end
        end
      end
    end # Generate
  end
end
