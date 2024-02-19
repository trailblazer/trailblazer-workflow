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

        # Render a test plan JSON structure that can be checked in so the assertions
        # don't change with code modifications.
        module Structure
          module_function
          # {
          #       start_position: start_p___FIXME,
          #       start_configuration: serialized_start_configuration,
          #       expected_lane_positions: expected_lane_positions,

          #       expected_outcome: expected_outcome= additional_state_data[[state.state_from_discovery_fixme.object_id, :outcome]],

          #       event_label: default_event_label(start_p___FIXME, expected_outcome: expected_outcome, lane_icons: lane_icons)
          #     }
          def call(discovered_states, **options)
            discovered_states.collect do |row|
              {
                event_label:            CommentHeader.start_position_label(row[:positions_before][1], row, **options),
                start_configuration:    serialize_configuration(row[:positions_before][0], **options),
                suspend_configuration:  serialize_configuration(row[:suspend_configuration].lane_positions, **options),
                outcome:                row[:outcome],
              }
            end
          end

          def serialize_configuration(start_positions, **options)
            start_positions.collect do |activity, suspend|
              serialize_position(activity, suspend, **options)
            end
          end

          def id_tuple_for(activity, task, lanes_cfg:)
            activity_id = lanes_cfg.values.find { |cfg| cfg[:activity] == activity }[:label]
            task_id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

            return activity_id, task_id
          end
                    # FIXME: move  me somewhere else!
          # "Deserialize" a {Position} from a serialized tuple.
          # Opposite of {#id_tuple_for}.
          # def position_from_tuple(lanes, lane_id, task_id)
          #   lane_activity = lanes[lane_id]
          #   task = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: task_id).task

          #   Collaboration::Position.new(lane_activity, task)
          # end

          # A lane position is always a {Suspend} (or a terminus).
          def self.serialize_position(activity, suspend, **options)
            position_tuple = id_tuple_for(activity, suspend, **options) # usually, this is a suspend. sometimes a terminus {End}.

            comment =
              if suspend.to_h["resumes"].nil? # FIXME: for termini.
                comment = [:terminus, suspend.to_h[:semantic]]
              else
                [:before, Discovery::Present.readable_name_for_suspend_or_terminus(activity, suspend, **options)]
              end

            {
              tuple: position_tuple,
              comment: comment,
            }
          end
        end

        def render_comment_header(discovered_states, **options)
          CommentHeader.(discovered_states, **options)
        end

        module CommentHeader
          module_function

          def call(discovered_states, **options)
            start_position_combined_column    = render_combined_column_labels(discovered_states.collect { |row| row[:positions_before][0] }, **options)
            expected_position_combined_column = render_combined_column_labels(discovered_states.collect { |row| row[:suspend_configuration].lane_positions }, **options)

            rows = discovered_states.collect.with_index do |row, index|
              positions_before, start_position = row[:positions_before]

              Hash[
                "triggered catch",
                start_position_label(start_position, row, **options),

                "start configuration",
                start_position_combined_column[index],

                "expected reached configuration",
                expected_position_combined_column[index],
              ]
            end

            Discovery::Present::Table.render(["triggered catch", "start configuration", "expected reached configuration"], rows)
          end

          def start_position_label(start_position, row, **options)
            outcome = row[:outcome]

            start_position_label_for(start_position, expected_outcome: outcome, **options)
          end

          def start_position_label_for(position, expected_outcome:, **options)
            event_label = Discovery::Present.readable_name_for_catch_event(*position.to_a, **options)

            event_label += " #{Discovery::Present::ICONS[:failure]}" if expected_outcome == :failure # FIXME: what happens to :symbol after serialization?

            event_label
          end

          # Render the content of a combined column (usually used for positions, such as {}).
          # Note that this renders for the entire table/all rows.
          #
          #   ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx
          def render_combined_column_labels(positions_rows, **options)
            all_position_labels = positions_rows.collect do |positions|
              positions.collect do |activity, task|
                [
                  activity,
                  Discovery::Present.readable_name_for_suspend_or_terminus(activity, task, **options)
                ]
              end
            end

            position_combined_column = format_positions_column(all_position_labels, **options)
          end

          def compute_combined_column_widths(position_rows, lanes_cfg:, **)
            chars_to_filter = Discovery::Present::ICONS.values + lanes_cfg.collect { |_, cfg| cfg[:icon] } # TODO: do this way up in the code path.

            # Find out the longest entry per lane.
            columns = lanes_cfg.collect { |_, cfg| [cfg[:activity], []] }.to_h # {<lifecycle> => [], ...}

            position_rows.each do |event_labels|
              event_labels.each do |(activity, suspend_label)|
                length = suspend_label ? label_length(suspend_label, chars_to_filter: chars_to_filter) : 0 # DISCUSS: why can {suspend_label} be nil?

                columns[activity] << length
              end
            end

            _columns_2_length = columns.collect { |activity, lengths| [activity, lengths.max] }.to_h
          end

          # @private
          def label_length(label, chars_to_filter:)
            countable_label = chars_to_filter.inject(label) { |memo, char| memo.gsub(char, "@") }
            countable_label.length
          end

          def format_positions_column(position_rows, lanes_cfg:, **options)
            columns_2_length = compute_combined_column_widths(position_rows, lanes_cfg: lanes_cfg, **options)

            rows = position_rows.collect do |event_labels|
              columns = event_labels.collect do |activity, suspend_label|
                col_length = columns_2_length[activity]

                # Correct {#ljust}, it considers one emoji as two characters,
                # hence we need to add those when padding.
                emoji_overflows = suspend_label.chars.find_all { |char| char == "︎" } # this is a "wrong" character behind an emoji.

                suspend_label.ljust(col_length + emoji_overflows.size, " ")
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
