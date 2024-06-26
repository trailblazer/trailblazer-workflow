module Trailblazer
  module Workflow
    module Introspect
      class Lanes
        def initialize(lanes_cfg)
          ary = lanes_cfg.collect { |json_id, cfg| cfg.merge(json_id: json_id) }

          @ary = ary
        end

        def call(**options)
          key, value = options.keys[0], options.values[0]

          @ary.find { |options| options[key] == value } or raise "#{key.inspect} == #{value.inspect} not found"
        end

        def to_h
          @ary.collect { |cfg| [cfg[:activity], cfg] }.to_h
        end
      end

      # Rendering-specific code using {Discovery:states}.
      # https://stackoverflow.com/questions/22885702/html-for-the-pause-symbol-in-audio-and-video-control
      module Present
        ICONS = {
          catch_event:  "⏵︎",
          terminus:     "◉",
          failure:      "⛞",
          state:        "⏸︎",
        }
        module_function

        # Find the next connected task, usually outgoing from a catch event.
        def label_for_next_task(activity, catch_event)
          task_after_catch  = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]
          next_node = node_for_task(activity, task_after_catch)

          next_node.data[:label] || next_node.id
        end

        def node_for_task(activity, task)
          Trailblazer::Activity::Introspect.Nodes(activity, task: task)
        end

        def readable_name_for_catch_event(activity, catch_event, show_lane_icon: true, lanes_cfg: {})
          envelope_icon = "(✉)➔" # TODO: implement {envelope_icon} flag.
          envelope_icon = ICONS[:catch_event]

          lane_label = if show_lane_icon
            _lane_label = lane_label_for(activity, catch_event, lanes_cfg: lanes_cfg)
            "#{_lane_label} "
          else
            ""
          end

          if label = node_for_task(activity, catch_event).data[:label] # for named catch events such as {accepted?}.
            event_label = label
          else
            event_label = label_for_next_task(activity, catch_event)
          end

          "#{lane_label}#{envelope_icon}#{event_label}"
        end

        # Compute real catch events from the ID for a particular resume.
        def resumes_from_suspend(activity, suspend)
          suspend.to_h["resumes"].collect do |catch_event_id|
            _catch_event = Trailblazer::Activity::Introspect.Nodes(activity, id: catch_event_id).task
          end
        end

        def readable_name_for_suspend_or_terminus(activity, event, **options)
          lane_icon = lane_label_for(activity, event, **options)

          if event.to_h["resumes"].nil? # Terminus.
            readable_lane_position = "#{lane_icon} #{ICONS[:terminus]}End.#{event.to_h[:semantic]}"
          else
            catch_labels = Present.resumes_from_suspend(activity, event).collect do |catch_event|
              Present.readable_name_for_catch_event(activity, catch_event, show_lane_icon: false, **options)
            end.join(" ")
            "#{lane_icon} #{catch_labels}"
          end
        end

        #if lane_icons.key?(lane_name) # TODO: handle default!
        def lane_label_for(activity, task, lanes_cfg:, show_icon: true)
          lanes_cfg.(activity: activity)[:icon]
        end

        def lane_options_for_position(position, lanes_cfg:, **)
          activity, _ = position.to_a
          lanes_cfg.(activity: activity)
        end

        def id_for_position(lane_position)
          Trailblazer::Activity::Introspect.Nodes(lane_position.activity, task: lane_position.task).id
        end

        # def readable_id_label(activity, task, **options)
        #   id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id
        #   lane_label = lane_label_for(activity, task, **options)

        #   %(#{lane_label} #{id})
        # end

        module Table
          module_function

          # {rows} are [{column_name => content}]
          def rows_for_terminal_table(columns, rows)
            rows.collect do |row|
              columns.collect { |column_name| row[column_name] }
            end
          end

          def render(columns, rows)
            rows_for_terminal_table = Present::Table.rows_for_terminal_table(columns, rows)
            # pp rows_for_terminal_table

            Terminal::Table.new(headings: columns, rows: rows_for_terminal_table).to_s
          end
        end
      end
    end
  end
end
