module Trailblazer
  module Workflow
    module Test
      module Plan
        module_function

        # Code fragment with assertions for the discovered/configured test plan.
        def for(discovered_states, input:, **options)
          code_string = discovered_states.collect do |row|

          # TODO: introduce a "test structure" that computes event label, and then links to the specific row of the {discovered_states}.
          #       that way, we only compute the "ID" once.
          event_label = CommentHeader.start_position_label(row[:positions_before][1], row, **options)

            %(
# test: #{event_label}
ctx = assert_advance "#{event_label}", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
assert_exposes ctx, seq: [:revise, :revise], reader: :[]
)
          end
        end

        # Render a test plan JSON structure that can be checked in so the assertions
        # don't change with code modifications.
        module Structure
          module_function

          def serialize(discovered_states, **options)
            discovered_states.collect do |row|
              {
                event_label:            CommentHeader.start_position_label(row[:positions_before][1], row, **options),
                start_position:         serialize_position(*row[:positions_before][1].to_a, **options),
                start_configuration:    serialize_configuration(row[:positions_before][0], **options),
                suspend_configuration:  serialize_configuration(row[:suspend_configuration].lane_positions, **options),
                outcome:                row[:outcome],
              }
            end
          end

          def deserialize(id_structure, lanes_cfg:, **)
            # DISCUSS: don't unserialize the entire thing at once, presently we only allow "lookups".
            Deserialized.new(id_structure, lanes_cfg)
          end

          class Deserialized
            def initialize(id_structure, lanes_cfg)
              @id_structure = id_structure
              @lanes_cfg = lanes_cfg

              @lane_label_2_activity = lanes_cfg.values.collect { |cfg| [cfg[:label], cfg[:activity]] }.to_h
            end

            def [](event_label)
              @id_structure.find { |row| row[:event_label] == event_label } || raise
            end

            # "Deserialize" a {Position} from a serialized tuple.
            # Opposite of {#id_tuple_for}.
            def position_from_tuple(lane_label, task_id)
              lane_activity = @lane_label_2_activity[lane_label]
              task = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: task_id).task

              Collaboration::Position.new(lane_activity, task)
            end
          end

          def serialize_configuration(start_positions, **options)
            start_positions.collect do |activity, suspend|
              serialize_suspend_position(activity, suspend, **options)
            end
          end

          def id_tuple_for(activity, task, lanes_cfg:)
            activity_id = lanes_cfg.values.find { |cfg| cfg[:activity] == activity }[:label]
            task_id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

            return activity_id, task_id
          end

          # A lane position is always a {Suspend} (or a terminus).
          def self.serialize_suspend_position(activity, suspend, **options)
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

          # TODO: merge with serialize_suspend_position.
          def serialize_position(activity, catch_event, **options)
            position_tuple = id_tuple_for(activity, catch_event, **options)

            comment = [:before, Discovery::Present.readable_name_for_catch_event(activity, catch_event, **options)]

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
