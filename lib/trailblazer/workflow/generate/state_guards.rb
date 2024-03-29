module Trailblazer
  module Workflow
    class Generate
      # State guards are code blocks defined by the user to allow/deny executing
      # a catch event.
      class StateGuards < Trailblazer::Activity::Railway
        step :render

        def render(ctx, rows:, namespace:, **options)
          # formatting, find longest state name.
          max_length = rows.collect { |row| row["state name"].inspect.length }.max

          state_guard_rows = rows.collect do |row|
            # id_snippet = %(, id: #{row[:key].inspect}) # TODO: move me to serializer code.

            %(        #{row["state name"].inspect.ljust(max_length)} => {guard: ->(ctx, model:, **) { model.state == #{row["state name"].inspect} }},)
          end.join("\n")

          snippet = %(module #{namespace}
  module StateGuards
    Decider = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash(
      {
#{state_guard_rows}
      },
      state_table: Generated::StateTable,
    )
  end
end
)

          ctx[:snippet] = snippet
        end
      end
    end # Generate
  end
end
