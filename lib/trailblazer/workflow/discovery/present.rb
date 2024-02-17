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

        # Each row represents a configuration of suspends aka "state".
        # The state knows its possible resume events.
        #   does the state know which state fields belong to it?
        #
        # TODO: move that to separate module {StateTable.call}.
        def render_cli_state_table(discovered_states, lanes_cfg:)
          # raise discovery_state_table.inspect
          start_position_to_catch = {}

          # Key by lane_positions, which represent a state.
          # State (lane_positions) => [events (start position)]
          states = {}

          # Collect the invoked start positions per Positions configuration.
          # This implies the possible "catch events" per configuration.
          discovered_states.each do |row|
            positions_before, start_position = row[:positions_before]

            # raise positions_before.inspect
            # puts positions_before.to_a.collect { |p|
            #   # puts "@@@@@ #{p.inspect}"
            #   next if p.task.to_h["resumes"].nil?
            #   resumes_from_suspend(*p).collect { |catch_event| readable_name_for_catch_event(p.activity, catch_event, lanes_cfg: lanes_cfg) }

            # }.inspect

            events = states[positions_before]
            events = [] if events.nil?

            events << start_position

            states[positions_before] = events
          end

          # render
          cli_rows = states.flat_map do |configuration, catch_events|
            suggested_state_name = suggested_state_name_for(catch_events)

            suggested_state_name = "⛊ #{suggested_state_name}"
              .inspect


            # triggerable_events = events
            #   .collect { |event_position| readable_name_for_catch_event(event_position, lanes_cfg: lanes_cfg).inspect }
            #   .uniq
            #   .join(", ")


            Hash[
              "state name",
              suggested_state_name,

              # "triggerable events",
              # triggerable_events
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

        # TODO: move to StateTable
        def suggested_state_name_for(catch_events)
          catch_events
            .collect { |event_position| label_for_next_task(*event_position.to_a) }
            .uniq
            .join("/")
        end
      end
    end
  end
end
