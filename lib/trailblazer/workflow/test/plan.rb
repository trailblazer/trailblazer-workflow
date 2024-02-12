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
            assert_equal position, sorted_expected_positions[index], "baaaaal"
          end

          # FIXME: figure out why we can't just compare the entire array!
          # assert_equal sorted_asserted_positions, sorted_expected_positions
        end

        def assert_advance(event_label, test_plan:, lanes:, schema:, message_flow:, **) # TODO: allow {ctx}
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

          configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            schema,
            [{seq: []}, {throw: []}],
            {}, # circuit_options

            start_position: start_position,
            lane_positions: lane_positions, # current position/"state"

            message_flow: message_flow,
          )

          assert_positions configuration[:lane_positions], testing_row[:expected_lane_positions], lanes: lanes
          assert_equal ctx.inspect, "asdf"
        end

      end

      module Plan
        # Code fragment with assertions for the discovered/configured test plan.
        def self.for(test_structure, input:)
          code_string = test_structure.collect do |row|


          # raise row[:start_configuration].inspect
          start_position = row[:start_position]

          tuples_for_expected = row[:expected_lane_positions]


            %(
# test: #{row[:event_label]}

start_tuple = #{start_position[:tuple]} # #{start_position[:comment]}
start_position = Trailblazer::Workflow::State::Discovery.position_from_tuple(lanes, *start_tuple)

# current position.
#DISCUSS: here, we could also ask the State layer for the start configuration, on a different level.
lane_positions = [#{row[:start_configuration].collect do |row|
  "Trailblazer::Workflow::State::Discovery.position_from_tuple(lanes, *#{row[:tuple].inspect})"
end.join(", ")}]

lane_positions = Trailblazer::Workflow::Collaboration::Positions.new(lane_positions)

configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
  schema,
  [{seq: []}, {throw: []}],
  {}, # circuit_options

  start_position: start_position,
  lane_positions: lane_positions, # current position/"state"

  message_flow: message_flow,
)

assert_positions configuration[:lane_positions], #{row[:expected_lane_positions].inspect}, lanes: lanes



# TODO: test {:last_lane}.
    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]
    assert_equal configuration.lane_positions.values.inspect, %([{"resumes"=>["catch-before-#{}"], :semantic=>[:suspend, "from initial_lane_positions"]}, \
#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{}"] type=:suspend semantic=[:suspend, "suspend-Gateway_14h0q7a"]>])
    assert_equal ctx.inspect, %({:seq=>[:create_form]})
)
          end
        end
      end

    end # Test
  end
end
