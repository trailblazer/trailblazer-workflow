module Trailblazer
  module Workflow
    class State
      module Discovery
        module Testing
          def self.render_json(states, lanes:, additional_state_data:, initial_lane_positions:, task_map:)
            present_states = Trailblazer::Workflow::State::Discovery.generate_from(states) # returns rows with [{activity, suspend, resumes}]

            rows = present_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}

              start_position, lane_positions, discovery_state_fixme = state.to_a

              # "serialize" start task
              activity_id, triggered_catch_event_id = Discovery.id_tuple_for(lanes, start_position.activity, start_position.task)

              # {suspend_configuration} are the lane positions after we started running from {start_position}.
              suspend_configuration = additional_state_data[[state.state_from_discovery_fixme.object_id, :suspend_configuration]]


              # Go through each lane and define the expected positions after running from the start position.
              expected_lane_positions = suspend_configuration.lane_positions.collect do |lane_position|
                next if lane_position.nil? # FIXME: why do we have that?

                # puts lane_position[:suspend]  # DISCUSS: introduce State::Position? this comes from {#generate_from}.


                serialize_lane_position(lane_position, lanes: lanes, initial_lane_positions: initial_lane_positions)

              end

              {
                start_position: {
                  tuple: [activity_id, triggered_catch_event_id],
                  comment: Discovery.find_next_task_label(start_position.activity, start_position.task)
                },
                expected_lane_positions: expected_lane_positions,
              }
            end
          end

          # A lane position is always a {Suspend} (or a terminus).
          def self.serialize_lane_position(lane_position, lanes:)
            activity, suspend = lane_position.to_a

            position_tuple = Discovery.id_tuple_for(lanes, activity, suspend) # usually, this is a suspend. sometimes a terminus {End}.
            comment = nil

            if suspend.to_h["resumes"].nil? # FIXME: for termini.
              comment = [:terminus, suspend.to_h[:semantic]]
            else
            # Compute the task name that follows a particular catch event.
              resumes = Discovery.resumes_from_suspend(activity, suspend)

              resumes_label = resumes.collect do |catch_event|
                Discovery.find_next_task_label(activity, catch_event)
              end

              comment = resumes_label

            end

            {
              tuple: position_tuple,
              comment: comment
            }
          end

        end # Testing
      end
    end
  end
end
