module Trailblazer
  module Workflow
    module Test
      module Assertions
        def assert_positions(asserted_positions, expected_tuples, lanes:)
          expected_positions =
            expected_tuples.collect do |testing_row|
              Trailblazer::Workflow::State::Discovery.position_from_tuple(lanes, *testing_row[:tuple])
            end

          sorting_block = ->(a, b) { a.activity.object_id <=> b.activity.object_id }

          sorted_asserted_positions = asserted_positions.to_a.sort(&sorting_block)
          sorted_expected_positions = expected_positions.sort(&sorting_block)

          sorted_asserted_positions.collect.with_index do |position, index|
            assert_equal position, sorted_expected_positions[index],
              Assertions.error_message_for(position, sorted_expected_positions[index], lanes: lanes)
          end

          # FIXME: figure out why we can't just compare the entire array!
          # assert_equal sorted_asserted_positions, sorted_expected_positions
        end

        # Compile error message when the expected lane position doesn't match the actual one.
        def self.error_message_for(position, expected_position, lanes:) # TODO: test me.
          # TODO: make the labels use UTF8 icons etc, as in the CLI rendering code.
          expected_label = State::Discovery::Testing.serialize_lane_position(position, lanes: lanes)[:comment]
          actual_label   = State::Discovery::Testing.serialize_lane_position(expected_position, lanes: lanes)[:comment]

          "Lane #{lanes.invert[position.activity].inspect}:\n   expected #{expected_label}\n   actual   #{actual_label}"
        end

        # Grab the start_position and expected_lane_positions from the discovered plan, run
        # the collaboration from there and check if it actually reached the expected configuration.
        def assert_advance(event_label, test_plan:, lanes:, schema:, message_flow:, expected_ctx:, ctx: {seq: []}, **) # TODO: allow {ctx}
          testing_row = test_plan.find { |row| row[:event_label] == event_label }

          start_position = testing_row[:start_position]
          start_tuple = start_position[:tuple] # #{start_position[:comment]}
          start_position = Trailblazer::Workflow::State::Discovery.position_from_tuple(lanes, *start_tuple)

          # current position.
          #DISCUSS: here, we could also ask the State layer for the start configuration, on a different level.
          lane_positions = testing_row[:start_configuration].collect do |row|
            Trailblazer::Workflow::State::Discovery.position_from_tuple(lanes, *row[:tuple])
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

          assert_positions configuration[:lane_positions], testing_row[:expected_lane_positions], lanes: lanes

          # assert_equal ctx.inspect, expected_ctx.inspect
          ctx
        end

      end

      module Plan
        module_function

        # Code fragment with assertions for the discovered/configured test plan.
        def for(test_structure, input:)
          code_string = test_structure.collect do |row|


          # raise row[:start_configuration].inspect
          start_position = row[:start_position]

          tuples_for_expected = row[:expected_lane_positions]


            %(
# test: #{row[:event_label]}
ctx = assert_advance "#{row[:event_label]}", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: message_flow
assert_exposes ctx, seq: [:revise, :revise], reader: :[]
)
          end
        end

        def render_comment_header(discovered_states, **options)
          CommentHeader.(discovered_states, **options)
        end

        module CommentHeader
          module_function

          def call(discovered_states, **options)

            all_start_position_labels = discovered_states.collect do |row|
              row[:positions_before][0].collect do |activity, task|
                [
                  activity,
                  Discovery::Present.readable_name_for_suspend_or_terminus(activity, task, **options)
                ]
              end
            end

            start_position_combined_column = format_positions_column(all_start_position_labels, **options)

            rows = discovered_states.collect.with_index do |row, index|
              positions_before, start_position = row[:positions_before]

              Hash[
                "triggered catch",
                start_position_label(start_position, row, **options),

                "start configuration",
                # start_configuration(positions_before, **options)
                start_position_combined_column[index],
              ]
            end

            Discovery::Present::Table.render(["triggered catch", "start configuration"], rows)
          end

          def start_position_label(start_position, row, **options)
            outcome = row[:outcome]

            start_position_label_for(start_position, expected_outcome: outcome, **options)
          end

          def start_position_label_for(position, expected_outcome:, **options)
            event_label = Discovery::Present.readable_name_for_catch_event(*position.to_a, **options)

            event_label += " ⛞" if expected_outcome == :failure # FIXME: what happens to :symbol after serialization?

            event_label
          end


          def compute_combined_column_widths(position_rows, lanes_cfg:, **)
            # Find out the longest entry per lane.
            columns = lanes_cfg.collect { |_, cfg| [cfg[:activity], []] }.to_h # {<lifecycle> => [], ...}

            position_rows.each do |event_labels|
              event_labels.each do |(activity, suspend_label)|
                length = suspend_label ? suspend_label.length : 0 # DISCUSS: why can {suspend_label} be nil?

                columns[activity] << length
              end
            end

            _columns_2_length = columns.collect { |activity, lengths| [activity, lengths.max] }.to_h
          end

          def format_positions_column(position_rows, lanes_cfg:, **options)
            columns_2_length = compute_combined_column_widths(position_rows, lanes_cfg: lanes_cfg, **options)

            rows = position_rows.collect do |event_labels|
              columns = event_labels.collect do |activity, suspend_label|
                col_length = columns_2_length[activity]

                suspend_label.ljust(col_length, " ")
              end

              content = columns.join(" ")
            end

            rows
          end
        end

      end

    end # Test
  end
end
