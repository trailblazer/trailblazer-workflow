module Trailblazer
  module Workflow
    class State
      # Find out possible configurations by traveling all routes of a collaboration.
      #
      # {states} are lane positions: [activity, suspend] tuples.
      module Discovery
        module Present
          # Maintains the following fields
          # start_position: where we started
          # lane_positions: where the workflow stopped, for each lane.
          State = Struct.new(:start_position, :lane_states, :state_from_discovery_fixme) do # FIXME: state_from_discovery_fixme is the "runtime Discovery state"
            # def to_a
            #   return start_position, lane_states
            # end
          end
        end

        # Enrich each Discovery state with the possible resume events
        def self.generate_from(states)
          rows = states.collect do |state|

            lane_positions, start_position = state # DISCUSS: introduce a Discovery::State object?

            # triggered_catch_event_id = Trailblazer::Activity::Introspect.Nodes(start_position.activity, task: start_position.task).id

            # Go through each lane.
            row = lane_positions.flat_map do |activity, suspend|
              next if suspend.to_h["resumes"].nil?

              resumes = suspend.to_h["resumes"].collect do |catch_event_id|
                catch_event = Trailblazer::Activity::Introspect.Nodes(activity, id: catch_event_id).task
                # task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]
                # # raise task_after_catch.inspect

                # Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
              end

              # [
              #   lanes[activity],
              #   resumes.inspect,

              #   "#{lanes[activity]} suspend",
              #   suspend.to_h[:semantic][1],
              # ]

              {
                activity: activity,
                suspend: suspend,
                resumes: resumes,
              }
            end

            Present::State.new(start_position, row, state)
          end

        end
      end # Discovery
    end
  end
end
