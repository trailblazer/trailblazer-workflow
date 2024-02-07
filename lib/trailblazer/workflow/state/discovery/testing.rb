module Trailblazer
  module Workflow
    class State
      module Discovery
        module Testing
          # DISCUSS: In the Testing JSON, we want
          #   1. start event, start configuration, input => expected suspend configuration
          #   2. a "comment" table above that which draws out the same in readable format.
          def self.render_structure(states, lanes:, additional_state_data:, task_map:)
            present_states = Trailblazer::Workflow::State::Discovery.generate_from(states) # returns rows with [{activity, suspend, resumes}]

# FIXME: we're actually going through events here, not states!
            rows = present_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}

              start_position, start_configuration, discovery_state_fixme = state.to_a   # DISCUSS: do we need the "present_state" from {#generate_from}?

              # "serialize" start task
              activity_id, triggered_catch_event_id = Discovery.id_tuple_for(lanes, start_position.activity, start_position.task)

              # {suspend_configuration} are the lane positions after we started running from {start_position}.
              suspend_configuration = additional_state_data[[state.state_from_discovery_fixme.object_id, :suspend_configuration]]

              # Go through each lane and define the expected positions after running from the start position.
              expected_lane_positions = suspend_configuration.lane_positions.collect do |lane_position|
                next if lane_position.nil? # FIXME: why do we have that?

                # puts lane_position[:suspend]  # DISCUSS: introduce State::Position? this comes from {#generate_from}.


                serialize_lane_position(lane_position, lanes: lanes)
              end

              serialized_start_configuration = start_configuration.collect do |position|
                next if position.nil? # FIXME: what the hecke is this?

                position = position.values # FIXME: {Position} interface

                serialize_lane_position(position, lanes: lanes)
              end

              serialized_start_configuration = serialized_start_configuration.compact # FIXME: what the hecke is this?

              {
                start_position: {
                  tuple: [activity_id, triggered_catch_event_id],
                  comment: ["before", Discovery.find_next_task_label(start_position.activity, start_position.task)]
                },
                start_configuration: serialized_start_configuration,
                expected_lane_positions: expected_lane_positions,

                expected_outcome: additional_state_data[[state.state_from_discovery_fixme.object_id, :outcome]],
              }
            end
          end

          # Render the "test plan" in readable form.
          def self.render_comment_header(structure, lane_icons:)
            cli_rows = structure.collect do |testing_row| # row = :start_position, :start_configuration, :expected_lane_positions
              triggered_catch_event_label = Discovery.readable_name_for_catch_event(testing_row[:start_position], lane_icons: lane_icons)

              triggered_catch_event_label += " ⛞" if testing_row[:expected_outcome] == :failure # FIXME: what happens to :symbol after serialization?

              start_configuration = testing_row[:start_configuration].collect do |lane_position|
                Discovery.readable_name_for_resume_event(lane_position, tuple: true)
              end

              expected_lane_positions = testing_row[:expected_lane_positions].collect do |lane_position|
                readable_name_for_resume_event_or_terminus(lane_position, lane_icons: lane_icons, tuple: true)
              end

              Hash[
                "triggered catch",
                triggered_catch_event_label,

                "input ctx",
                nil,

                :start_configuration,
                start_configuration,


                "expected lane positions",
                expected_lane_positions
              ]
            end


            cli_rows = format_start_positions_for(cli_rows, column_name: :start_configuration, lane_icons: lane_icons, formatted_col_name: :start_configuration_formatted)
            cli_rows = format_start_positions_for(cli_rows, column_name: "expected lane positions", lane_icons: lane_icons, formatted_col_name: :expected_lane_positions_formatted)

            Hirb::Helpers::Table.render(cli_rows, fields: [
              "triggered catch",
              :start_configuration_formatted,
              :expected_lane_positions_formatted,
            ],
            max_width: 186,
          ) # 186 for laptop 13"
          end

          def self.format_start_positions_for(rows, column_name:, formatted_col_name:, lane_icons:)
            # Find out the longest entry per lane.
            columns = {}

            rows.each do |row|
              row[column_name].each do |lane_label, catch_label|
                columns[lane_label] ||= []

                length = catch_label ? catch_label.length : 0 # DISCUSS: why can {catch_label} be nil?

                columns[lane_label] << length
              end
            end

            columns_2_length = columns.collect { |lane_label, lengths| [lane_label, lengths.sort.last] }.to_h

            # TODO: always same col order!!!
            rows = rows.collect do |row|
              columns = row[column_name].collect do |lane_label, catch_label|
                col_length = columns_2_length[lane_label]
                lane_label = lane_icons[lane_label]

                catch_label = "" if catch_label.nil? # DISCUSS: why can {catch_label} be nil?

                "#{lane_label} " + catch_label.ljust(col_length, " ")
              end

              content = columns.join(" ")

              row = row.merge(formatted_col_name => content)
            end

            rows
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

              comment = Discovery.serialize_comment(resumes_label)

            end

            {
              tuple: position_tuple,
              comment: comment,
            }
          end

          def self.readable_name_for_resume_event_or_terminus(position, lane_icons:, tuple: false)
            if position[:comment][0] ==  :terminus

              terminus_label = "◉End.#{position[:comment][1]}"
              lane_label     = lane_icons[position[:tuple][0]]

              return [position[:tuple][0], terminus_label] if tuple
              return "#{lane_label} #{terminus_label}"
            end

            Discovery.readable_name_for_resume_event(position, lane_icons: lane_icons, tuple: tuple)
          end

        end # Testing
      end
    end
  end
end
