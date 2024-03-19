module Trailblazer
  module Workflow
    module Test
      module Assertions
        def assert_positions(asserted_positions, expected_positions, lanes:, test_plan:, **)
          # FIXME: make 100% sure that row_position etc are always sorted.

          expected_positions_ary = expected_positions.to_a

          asserted_positions.to_a.collect.with_index do |position, index|
            assert_equal position, expected_positions_ary[index],
              Assertions.error_message_for(position, expected_positions_ary[index], lanes_cfg: lanes)
          end

          # FIXME: figure out why we can't just compare the entire array!
          # assert_equal sorted_asserted_positions, sorted_expected_positions
        end

        # Compile error message when the expected lane position doesn't match the actual one.
        def self.error_message_for(position, expected_position, **options) # TODO: test me.
          # TODO: make the labels use UTF8 icons etc, as in the CLI rendering code.
          expected_label = Introspect::Present.readable_name_for_suspend_or_terminus(*position.to_a, **options)
          actual_label   = Introspect::Present.readable_name_for_suspend_or_terminus(*expected_position.to_a, **options)

          lane_label = Introspect::Present.lane_options_for_position(position, **options)[:label]

          "Lane #{lane_label}:\n   expected #{expected_label}\n   actual   #{actual_label}"
        end

        # Grab the start_position and expected_lane_positions from the discovered plan, run
        # the collaboration from there and check if it actually reached the expected configuration.
        def assert_advance(event_label, test_plan:, schema:, ctx: {seq: []}, flow_options: {}, invalid: false, **) # TODO: allow {ctx}
# TODO: this is endpoint code! should we use endpoint here?
          ctx_for_advance = Trailblazer::Context(ctx, {}, flow_options[:context_options])
          flow_options    = {throw: []}.
            merge(flow_options).
            merge(
              event_label: event_label,
              iteration_set: test_plan,
              **schema.to_h
            )

          signal, (ctx, flow_options) = Workflow::Advance.([ctx_for_advance, flow_options], # TODO: use (#invoke)
          )# DISCUSS: add circuit_options? #FIXME: this sucks

          configuration = flow_options[:configuration]

          # we're expecting an invalid transition.
          if invalid
            # assert_equal signal.to_h[:semantic], :failure  # TODO: reuse endpoint/matcher
            assert [:failure, :not_authorized].include?(signal.to_h[:semantic])  # TODO: reuse endpoint/matcher
            return ctx # FIXME: test this!
          end

          iteration = test_plan.to_a.find { |iteration| iteration.event_label == event_label }

          assert_positions configuration[:lane_positions], iteration.suspend_positions, test_plan: test_plan, **schema.to_h

          # assert_equal ctx.inspect, expected_ctx.inspect
          ctx
        end

      end
    end # Test
  end
end
