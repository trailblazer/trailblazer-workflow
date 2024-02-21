module Trailblazer
  module Workflow
    module Test
      module Assertions
        def assert_positions(asserted_positions, expected_positions, lanes_cfg:, test_plan:)
          # FIXME: make 100% sure that row_position etc are always sorted.

          expected_positions_ary = expected_positions.to_a

          asserted_positions.to_a.collect.with_index do |position, index|
            assert_equal position, expected_positions_ary[index],
              Assertions.error_message_for(position, expected_positions_ary[index], lanes_cfg: lanes_cfg)
          end

          # FIXME: figure out why we can't just compare the entire array!
          # assert_equal sorted_asserted_positions, sorted_expected_positions
        end

        # Compile error message when the expected lane position doesn't match the actual one.
        def self.error_message_for(position, expected_position, lanes_cfg:) # TODO: test me.
          # TODO: make the labels use UTF8 icons etc, as in the CLI rendering code.
          expected_label = Introspect::Present.readable_name_for_suspend_or_terminus(*position.to_a, lanes_cfg: lanes_cfg)
          actual_label   = Introspect::Present.readable_name_for_suspend_or_terminus(*expected_position.to_a, lanes_cfg: lanes_cfg)

          lane_label = Introspect::Present.lane_options_for(*position.to_a, lanes_cfg: lanes_cfg)[:label]

          "Lane #{lane_label}:\n   expected #{expected_label}\n   actual   #{actual_label}"
        end

        # Grab the start_position and expected_lane_positions from the discovered plan, run
        # the collaboration from there and check if it actually reached the expected configuration.
        def assert_advance(event_label, test_plan:, lanes_cfg:, schema:, message_flow:, expected_ctx:, ctx: {seq: []}, **) # TODO: allow {ctx}
          iteration = test_plan.to_a.find { |iteration| iteration.event_label == event_label } or raise

          start_task_position = iteration.start_task_position

          # current position.
          #DISCUSS: here, we could also ask the State layer for the start configuration, on a different level.
          lane_positions = iteration.start_positions

          ctx_for_advance = ctx

          configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            schema,
            [ctx_for_advance, {throw: []}],
            {}, # circuit_options

            start_task_position: start_task_position,
            lane_positions: lane_positions, # current position/"state"

            message_flow: message_flow,
          )

          assert_positions configuration[:lane_positions], iteration.suspend_positions, lanes_cfg: lanes_cfg, test_plan: test_plan

          # assert_equal ctx.inspect, expected_ctx.inspect
          ctx
        end

      end
    end # Test
  end
end
