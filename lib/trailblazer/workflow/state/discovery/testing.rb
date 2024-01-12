module Trailblazer
  module Workflow
    class State
      module Discovery
        module Testing
          def self.id_tuple_for(lanes, activity, task)
            activity_id = lanes[activity]
            task_id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

            return activity_id, task_id
          end

          def self.render_json(states, lanes:, additional_state_data:, initial_lane_positions:, task_map:)
            present_states = Trailblazer::Workflow::State::Discovery.generate_from(states) # returns rows with [{activity, suspend, resumes}]

            rows = present_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}

              start_position, lane_positions, discovery_state_fixme = state.to_a

              # "serialize" start task
              activity_id, triggered_catch_event_id = id_tuple_for(lanes, start_position.activity, start_position.task)

              # {suspend_configuration} are the lane positions after we started running from {start_position}.
              suspend_configuration = additional_state_data[[state.state_from_discovery_fixme.object_id, :suspend_configuration]]


              # Go through each lane and define the expected positions after running from the start position.
              expected_lane_positions = suspend_configuration.lane_positions.collect do |lane_position|
                next if lane_position.nil? # FIXME: why do we have that?

                # puts lane_position[:suspend]  # DISCUSS: introduce State::Position? this comes from {#generate_from}.
                activity, suspend = lane_position


                if initial_lane_positions.invert[suspend]
                  {
                    tuple: [lanes[activity], nil], # FIXME: to indicate this is a virtual "task".
                  }
                else
                  next if suspend.to_h["resumes"].nil? # FIXME: for termini.

                  position_tuple = id_tuple_for(lanes, activity, suspend) # usually, this is a suspend.

                # Compute the task name that follows a particular catch event.
                  resumes = Discovery.resumes_from_suspend(activity, suspend)

                  resumes_label = resumes.collect do |catch_event|
                    task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]

                    Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
                  end


                  comment = resumes_label
                  # task_map.invert.each do |id, label|
                  #   if task_id =~ /#{id}$/
                  #     comment = "--> #{label}" and break
                  #   end
                  # end

                  {
                    tuple: position_tuple,
                    comment: comment
                  }
                end

              end


              {
                start_position: [activity_id, triggered_catch_event_id],
                expected_lane_positions: expected_lane_positions,
              }
            end

          end
        end
      end
    end
  end
end
