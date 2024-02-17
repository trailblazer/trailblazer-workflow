module Trailblazer
  module Workflow
    module Discovery
      # Rendering-specific code using {Discovery:states}.
      module Present
        module_function

        # Find the next connected task, usually outgoing from a catch event.
        def label_for_next_task(activity, catch_event)
          task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]

          Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
        end

        def readable_name_for_catch_event(activity, catch_event, lanes_cfg: {})
          envelope_icon = "(✉)➔" # TODO: implement {envelope_icon} flag.
          envelope_icon = "▶"

          lane_options = lane_options_for(activity, catch_event, lanes_cfg: lanes_cfg)
          lane_name  = lane_options[:label]
          lane_label = lane_options[:icon] #if lane_icons.key?(lane_name) # TODO: handle default!

          event_label = label_for_next_task(activity, catch_event)

          "#{lane_label} #{envelope_icon}#{event_label}"
        end

        # Compute real catch events from the ID for a particular resume.
        def resumes_from_suspend(activity, suspend)
          suspend.to_h["resumes"].collect do |catch_event_id|
            _catch_event = Trailblazer::Activity::Introspect.Nodes(activity, id: catch_event_id).task
          end
        end

        def lane_options_for(activity, task, lanes_cfg:)
          lanes_cfg.values.find { |options| options[:activity] == activity } or raise
        end


      end
    end
  end
end
