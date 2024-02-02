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
            lane_position_tuples = lane_positions.flat_map do |lane_position|
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

        # Each row represents a configuration of suspends aka "state".
        # The state knows its possible resume events.
        #   does the state know which state fields belong to it?
        def self.render_cli_state_table(discovery_state_table)
          start_position_to_catch = {}

          # Key by lane_positions, which represent a state.
          # State (lane_positions) => [events (start position)]
          states = {}

          discovery_state_table.each do |row|
            configuration = row[:lane_positions]

            events = states[configuration]
            events = [] if events.nil?

            events << row[:start_position]

            states[configuration] = events
          end


          # render
          cli_rows = states.flat_map do |configuration, events|
            suggested_state_name = events
              .collect { |event| event[:comment][1] }
              .uniq
              .join("/")

            suggested_state_name = "> #{suggested_state_name}"
              .inspect


            triggerable_events = events
              .collect { |event| readable_name_for_catch_event(event).inspect }
              .uniq
              .join(", ")


            Hash[
              "state name",
              suggested_state_name,

              "triggerable events",
              triggerable_events
            ]
          end

          Hirb::Helpers::Table.render(cli_rows, fields: [
              "state name",
              "triggerable events",
              # *lane_ids,
            ],
            max_width: 186,
          ) # 186 for laptop 13"
        end

        def self.readable_name_for_catch_event(position)
          "#{position[:tuple][0]}: (✉)➔[#{position[:comment][1]}]"
        end

        def self.readable_name_for_resume_event(position)
          resume_labels = position[:comment][1]

          catch_events = resume_labels.collect { |catch_label| "(✉)#{catch_label}" }
            .join(" ")

          "#{position[:tuple][0]}: ➔[#{catch_events}]"
        end

        def self.render_cli_event_table(discovery_state_table, render_ids: false, hide_lanes: [])
          rows = discovery_state_table.flat_map do |row|
            start_lane_id, start_lane_task_id = row[:start_position][:tuple]

            lane_positions = row[:lane_positions].flat_map do |lane_position|
              lane_id, suspend_id = lane_position[:tuple]
              comment = lane_position[:comment][1]

              [
                lane_id,
                comment
              ]
            end

            # The resulting hash represents one row.
            state_row = Hash[
              "event name",
              row[:event_name].inspect,

              "triggered catch event",
              readable_name_for_catch_event(row[:start_position]),

              *lane_positions
            ]

            rows = [
              state_row,
            ]

            # FIXME: use developer for coloring.
            # def bg_gray(str);        "\e[47m#{str}\e[0m" end

          # TODO: optional feature, extract!
            if render_ids
              lane_position_ids = row[:lane_positions].flat_map do |lane_position|
                tuple = lane_position[:tuple]

                # [tuple[0], "\e[34m#{tuple[1]}\e[0m"] # FIXME: when entry is shortened by Hirb, the stop byte gets lost.
                tuple
              end

              id_row = Hash[
                "triggered catch event",
                "\e[34m#{row[:start_position][:tuple][1]}\e[0m",

                *lane_position_ids, # TODO: this adds the remaining IDs.
              ]

              rows << id_row
            end


            rows
          end

          lane_ids = discovery_state_table[0][:lane_positions].collect { |lane_position| lane_position[:tuple][0] }

          lane_ids = lane_ids - hide_lanes # TODO: extract, new feature.

          Hirb::Helpers::Table.render(rows, fields: [
              "event name",
              "triggered catch event",
              *lane_ids,
            ],
            max_width: 186,
          ) # 186 for laptop 13"
        end

        # Find the next connected task, usually outgoing from a catch event.
        def self.find_next_task_label(activity, catch_event)
          task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]

          Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
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
            row = lane_positions.flat_map do |activity, suspend|
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
