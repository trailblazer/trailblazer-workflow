module Trailblazer
  module Workflow
    class State
      # Find out possible configurations by traveling all routes of a collaboration.
      #
      # {states} are lane positions: [activity, suspend] tuples.
      module Discovery
        module_function

        # FIXME: move  me somewhere else!
        # "Deserialize" a {Position} from a serialized tuple.
        # Opposite of {#id_tuple_for}.
        def position_from_tuple(lanes, lane_id, task_id)
          lane_activity = lanes[lane_id]
          task = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: task_id).task

          Collaboration::Position.new(lane_activity, task)
        end


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

        def self.id_tuple_for(lanes, activity, task)
          activity_id = lanes[activity]
          task_id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

          return activity_id, task_id
        end

        def self.generate_state_table(discovery_states, lanes:)
          state_table = discovery_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}

            # what we want:
            # event_name => [activity, task], [lane_positions]
            # [start_position]

            lane_positions, start_position = state.to_a

            # raise start_position.inspect

            # We start from here:
            triggered_catch_event_id = Trailblazer::Activity::Introspect.Nodes(start_position.activity, task: start_position.task).id

            event_name = find_next_task_label(start_position.activity, start_position.task)
            # catch_event =

            # Go through each lane.
            lane_position_tuples = lane_positions.to_a.collect do |lane_position|
              next if lane_position.nil? # FIXME: why do we have that?


              Testing.serialize_lane_position(lane_position, lanes: lanes)
            end

            {
              event_name: event_name,
              start_position: { # the catch event we start from.
                tuple: id_tuple_for(lanes, start_position.activity, start_position.task),
                comment: serialize_comment(event_name),
              },
              lane_positions: lane_position_tuples
            }

          end

          state_table
        end





        def self.readable_name_for_resume_event(position, tuple: false, lane_icons: {})
          resume_labels = position[:comment][1]

          lane_name  = position[:tuple][0]
          lane_label = "#{lane_name}:"
          lane_label = lane_icons[lane_name] if lane_icons.key?(lane_name)

          catch_events = resume_labels.collect { |catch_label| "▶#{catch_label}" }
            .join(" ")

          return [position[:tuple][0], catch_events] if tuple

          "#{lane_label} [#{catch_events}]"
        end



        def self.serialize_comment(event_name)
          ["before", event_name]
        end

        def self.render_state_table

        end

        # Enrich each Discovery state with the possible resume events
        def self.generate_from(states)
          rows = states.collect do |state|

            lane_positions, start_position = state # DISCUSS: introduce a Discovery::State object?
            # triggered_catch_event_id = Trailblazer::Activity::Introspect.Nodes(start_position.activity, task: start_position.task).id

            # Go through each lane.
            row = lane_positions.collect do |activity, suspend|
              next if suspend.to_h["resumes"].nil?

              resumes = resumes_from_suspend(activity, suspend)

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

        # Compute real catch events from the ID for a particular resume.
        def self.resumes_from_suspend(activity, suspend)
          suspend.to_h["resumes"].collect do |catch_event_id|
            _catch_event = Trailblazer::Activity::Introspect.Nodes(activity, id: catch_event_id).task
            # task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]
            # # raise task_after_catch.inspect

            # Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
          end
        end
      end # Discovery
    end
  end
end
