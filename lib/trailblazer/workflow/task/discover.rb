module Trailblazer
  module Workflow
    module Task
      # Discovery task: discover, serialize, create test plan, create state table/state guards
      module Discover
        module_function

        # DISCUSS: what about running this before we have a schema?
        def call(schema:, start_activity_json_id:, iteration_set_filename:, run_multiple_times: {}, test_filename:, collaboration_name:)
          lanes_cfg = schema.to_h[:lanes]

          start_task_position = find_start_task_position(start_activity_json_id, lanes_cfg) # FIXME: handle nil case

          initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(lanes_cfg)

          states = Trailblazer::Workflow::Discovery.(
            schema,
            initial_lane_positions: initial_lane_positions,
            start_task_position: start_task_position,
            message_flow: schema.to_h[:message_flow],

            run_multiple_times: run_multiple_times,
          )

         iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

         create_serialized_iteration_set(iteration_set, iteration_set_filename: iteration_set_filename, lanes_cfg: lanes_cfg)

         RenderTestPlan.(iteration_set, lanes_cfg: lanes_cfg,
          test_filename: test_filename,
          collaboration_name: collaboration_name,
          iteration_set_filename: iteration_set_filename
        )
        end


    # assert_equal testing_json, File.read("test/iteration_json.json")

    # iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(testing_json), lanes_cfg: lanes_cfg)

    # assert_equal JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg)), JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set_from_json, lanes_cfg: lanes_cfg))

        def find_start_task_position(start_activity_json_id, lanes_cfg)
          start_activity = lanes_cfg.(json_id: start_activity_json_id)[:activity]

          start_task = start_activity.to_h[:circuit].to_h[:start_task]

          _start_task_position = Trailblazer::Workflow::Collaboration::Position.new(start_activity, start_task)
        end

        def create_serialized_iteration_set(iteration_set, iteration_set_filename:, lanes_cfg:)
          interation_set_json = JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))

          File.write iteration_set_filename,  interation_set_json
        end

        module RenderTestPlan
          module_function

          def call(iteration_set, lanes_cfg:, test_filename:, collaboration_name:, input: {}, iteration_set_filename:)
            test_plan_comment_header = Trailblazer::Workflow::Test::Plan.render_comment_header(iteration_set, lanes_cfg: lanes_cfg)

            assertions = Trailblazer::Workflow::Test::Plan.for(iteration_set, lanes_cfg: lanes_cfg, input: input)


            test_content = %(=begin
#{test_plan_comment_header}
=end

require "test_helper"

class #{collaboration_name.gsub("::", "_")}CollaborationTest < Minitest::Spec
  include Trailblazer::Workflow::Test::Assertions
  require "trailblazer/test/assertions"
  include Trailblazer::Test::Assertions # DISCUSS: this is for assert_advance and friends.

  it "can run the collaboration" do
    schema = #{collaboration_name}
    test_plan = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(File.read("#{iteration_set_filename}")), lanes_cfg: schema.to_h[:lanes])

    #{assertions.join("\n")}
  end
end
)

            File.write(test_filename, test_content)


          end
        end
      end
    end # Task
  end
end
