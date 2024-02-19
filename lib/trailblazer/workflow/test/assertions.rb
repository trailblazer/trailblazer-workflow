module Trailblazer
  module Workflow
    module Test
      module Assertions
        def assert_positions(asserted_positions, expected_tuples, lanes_cfg:, test_plan:)
          expected_positions =
            expected_tuples.collect do |position_row|
              test_plan.position_from_tuple(*position_row[:tuple])
            end

          # sorting_block = ->(a, b) { a.activity.object_id <=> b.activity.object_id }

          # sorted_asserted_positions = asserted_positions.to_a.sort(&sorting_block)
          # sorted_expected_positions = expected_positions.sort(&sorting_block)

          # FIXME: make 100% sure that row_position etc are always sorted.

          asserted_positions.to_a.collect.with_index do |position, index|
            assert_equal position, expected_positions[index],
              Assertions.error_message_for(position, expected_positions[index], lanes_cfg: lanes_cfg)
          end

          # FIXME: figure out why we can't just compare the entire array!
          # assert_equal sorted_asserted_positions, sorted_expected_positions
        end

        # Compile error message when the expected lane position doesn't match the actual one.
        def self.error_message_for(position, expected_position, lanes_cfg:) # TODO: test me.
          # TODO: make the labels use UTF8 icons etc, as in the CLI rendering code.
          expected_label = Test::Plan::Structure.serialize_suspend_position(*position.to_a, lanes_cfg: lanes_cfg)[:comment]
          actual_label   = Test::Plan::Structure.serialize_suspend_position(*expected_position.to_a, lanes_cfg: lanes_cfg)[:comment]

          lane_label = Discovery::Present.lane_options_for(*position.to_a, lanes_cfg: lanes_cfg)[:label]

          "Lane #{lane_label}:\n   expected #{expected_label}\n   actual   #{actual_label}"
        end

        # Grab the start_position and expected_lane_positions from the discovered plan, run
        # the collaboration from there and check if it actually reached the expected configuration.
        def assert_advance(event_label, test_plan:, lanes_cfg:, schema:, message_flow:, expected_ctx:, ctx: {seq: []}, **) # TODO: allow {ctx}
          testing_row = test_plan[event_label]

          start_position = testing_row[:start_position]
          start_tuple = start_position[:tuple]
          start_position = test_plan.position_from_tuple(*start_tuple)

          # current position.
          #DISCUSS: here, we could also ask the State layer for the start configuration, on a different level.
          lane_positions = testing_row[:start_configuration].collect do |row|
            test_plan.position_from_tuple(*row[:tuple])
          end

          lane_positions = Trailblazer::Workflow::Collaboration::Positions.new(lane_positions)

          ctx_for_advance = ctx

          configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            schema,
            [ctx_for_advance, {throw: []}],
            {}, # circuit_options

            start_position: start_position,
            lane_positions: lane_positions, # current position/"state"

            message_flow: message_flow,
          )

          assert_positions configuration[:lane_positions], testing_row[:suspend_configuration], lanes_cfg: lanes_cfg, test_plan: test_plan

          # assert_equal ctx.inspect, expected_ctx.inspect
          ctx
        end

      end
    end # Test
  end
end
