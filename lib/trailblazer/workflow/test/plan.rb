module Trailblazer
  module Workflow
    module Test
      module Plan
        # Code fragment with assertions for the discovered/configured test plan.
        def self.for(test_structure, input:)
          code_string = test_structure.collect do |row|


          # raise row[:start_configuration].inspect
          start_position = row[:start_position]


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
