module Trailblazer
  module Workflow
    class Generate
      # state_table is a datastructure connecting the event label with the IDs
      # of the possible catch events, so we can retrieve the start positions.
      #
      # This generates app/concepts/posting/collaboration/generated/state_table.rb
      class StateTable < Trailblazer::Activity::Railway
        step Subprocess(Introspect::StateTable)
        step :render
        # Generate code stubs for a state table.

        def render(ctx, rows:, namespace:, **)
          available_states = rows.collect do |row|
            {
              suggested_state_name: row["state name"],
              key: row[:catch_events].collect { |position| Introspect::Present.id_for_position(position) }.uniq.sort
            }
          end

          # formatting, find longest state name.
          max_length = available_states.collect { |row| row[:suggested_state_name].inspect.length }.max

          state_guard_rows = available_states.collect do |row|
            id_snippet = %(id: #{row[:key].inspect}) # TODO: move me to serializer code.

            %(    #{row[:suggested_state_name].inspect.ljust(max_length)} => {#{id_snippet},) # TODO: rename {:id} to {:catch_event[_id]s}
          end.join("\n")

          snippet = %(# This file is generated by trailblazer-workflow.
module #{namespace}::Generated
  StateTable = {
#{state_guard_rows}
  }
end
)

          ctx[:snippet] = snippet
        end
      end
    end # Generate
  end
end