module Trailblazer::Workflow
  module Test
    module Plan
      # Build a Test::Plan from {Iteration::Set}.
      module Introspect
        module_function

        def call(iteration_set, **options)
          start_position_combined_column    = render_combined_column_labels(iteration_set.collect { |iteration| iteration.start_positions }, **options)
          expected_position_combined_column = render_combined_column_labels(iteration_set.collect { |iteration| iteration.suspend_positions }, **options)

          rows = iteration_set.collect.with_index do |iteration, index|
            Hash[
              "triggered catch",
              start_position_label(iteration.start_task_position, iteration, **options),

              "start configuration",
              start_position_combined_column[index],

              "expected reached configuration",
              expected_position_combined_column[index],
            ]
          end

          Trailblazer::Workflow::Introspect::Present::Table.render(["triggered catch", "start configuration", "expected reached configuration"], rows)
        end

        def start_position_label(start_position, row, **options)
          outcome = row[:outcome]

          start_position_label_for(start_position, expected_outcome: outcome, **options)
        end

        def start_position_label_for(position, expected_outcome:, **options)
          event_label = Trailblazer::Workflow::Introspect::Present.readable_name_for_catch_event(*position.to_a, **options)

          event_label += " #{Trailblazer::Workflow::Introspect::Present::ICONS[:failure]}" if expected_outcome == :failure # FIXME: what happens to :symbol after serialization?

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
                Trailblazer::Workflow::Introspect::Present.readable_name_for_suspend_or_terminus(activity, task, **options)  +
                " <#{id_hint_for_suspend_position(activity, task)}>" # TODO: make this optional.
              ]
            end
          end

          position_combined_column = format_positions_column(all_position_labels, **options)
        end

        # TODO: this is a quite pathetic way to show the native JSON ID, or part of it. We should store
        # the native ID on the Generate level.
        def id_hint_for_suspend_position(activity, task)
          id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id # TODO: use {Introspect.id_for_position}
          id_part = id[-7..-4]
        end

        def compute_combined_column_widths(position_rows, lanes_cfg:, **)
          chars_to_filter = Trailblazer::Workflow::Introspect::Present::ICONS.values + lanes_cfg.to_h.collect { |_, cfg| cfg[:icon] } # TODO: do this way up in the code path.

          # Find out the longest entry per lane.
          columns = lanes_cfg.to_h.collect { |_, cfg| [cfg[:activity], []] }.to_h # {<lifecycle> => [], ...}

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
  end
end
