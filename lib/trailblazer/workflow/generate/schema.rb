module Trailblazer
  module Workflow
    class Generate
      class Schema < Trailblazer::Activity::Railway
        step :render

        def render(ctx, parsed_structure:, namespace:, json_filename:, **options)
          lanes_cfg = parsed_structure[:lane_hints]

          lanes = parsed_structure[:intermediates].collect do |json_id, intermediate|
            tasks = intermediate.wiring.find_all { |task_ref, _| task_ref.data[:type] == :task }

            implementation = tasks.collect do |task_ref, _|
              %(          "#{task_ref.data[:label]}" => Trailblazer::Activity::Railway.Subprocess(#{namespace}::#{task_ref.data[:label]}),)
            end.join("\n")

            icon, label, _ = json_id.split(".") # FIXME: abstract.

            # lane_task_2_wiring = intermediate.wiring.find_all { |task_ref, _| task_ref.data[:type] == :task }
            %(      "#{json_id}" => {
        label: "#{label}",
        icon:  "#{icon}",
        implementation: {
#{implementation}
        }
      },)
          end.join("\n")

          snippet = %(module #{namespace}
  Schema = Trailblazer::Workflow.Collaboration(
    json_file: "#{json_filename}",
    lanes: {
#{lanes}
    }, # :lanes
    state_guards: #{namespace}::StateGuards::Decider,
  )
end
)

            ctx[:snippet] = snippet
        end
      end
    end
  end
end
