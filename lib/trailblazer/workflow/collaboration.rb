module Trailblazer
  module Workflow
    # User-friendly builder.
    def self.Collaboration(json_file:, lanes:, state_guards: nil)
      ctx = Collaboration.structure_from_filename(json_file)

      lanes_options = lanes.collect do |json_id, user_options|
        lane_options = normalize_lane_options(**user_options)

        activity = build_lane_for(**ctx, **user_options, json_id: json_id)

        [json_id, lane_options.merge(activity: activity)]
      end.to_h

      lanes_cfg = Introspect::Lanes.new(lanes_options)

       message_flow = Trailblazer::Workflow::Collaboration.Messages(
        ctx[:structure].messages,
        lanes_cfg
      )

      Trailblazer::Workflow::Collaboration::Schema.new(
        lanes: lanes_cfg,
        message_flow: message_flow,
        state_guards: state_guards
      )
    end

    # DISCUSS: use Activity here?
    def self.normalize_lane_options(label:, icon:, **)
      {label: label, icon: icon}
    end

    def self.build_lane_for(intermediates:, implementation:, json_id:, **)
      intermediate = intermediates.fetch(json_id)

      _lane_activity = Trailblazer::Workflow::Collaboration.Lane(
        intermediate,
        **implementation
      )
    end

    class Collaboration
      def self.structure_from_filename(json_file)
        json_from_pro = File.read(json_file)
        signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: json_from_pro}, {}])
        ctx
      end

      class Schema
        def initialize(lanes:, message_flow:, state_guards: {}, options:{})
          @lanes        = lanes
          @message_flow = message_flow
          @state_guards = state_guards

          # TODO: define what we need here, for runtime.
          #    1. a Collaboration doesn't mandatorily need its initial_lane_positions, that's only relevant for state discovery or State layer.
        end

        def to_h
          {
            message_flow: @message_flow,
            lanes:        @lanes,
            state_guards: @state_guards,
          }
        end
      end # Schema

      class Position < Struct.new(:activity, :task)
        def to_h
          {
            activity: activity,
            task:     task
          }
        end

        def to_a
          [
            activity,
            task
          ]
        end
      end

      # DISCUSS: is lane_positions same as Configuration?
      class Positions
        def initialize(positions)
          @positions = positions.sort { |a, b| a.activity.object_id <=> b.activity.object_id } # TODO: allow other orders?

          @activity_to_task = positions.collect { |position| [position.activity, position.task] }.to_h
          freeze
        end

        def [](activity) # TODO: do that mapping in constructor.
          @activity_to_task[activity]
        end

        def replace(activity, task)
          replaced_position = @positions.find { |position| position.activity == activity }

          new_positions = @positions - [replaced_position] + [Position.new(activity, task)]

          Positions.new(new_positions)
        end

        def to_a
          @positions
        end

        # Iterate [activity, task] directly, without the {Position} instance.
        def collect(&block)
          @positions
            .collect { |position| position.to_a }
            .collect(&block)
        end

        def ==(b) # DISCUSS: needed?
          eql?(b)
        end

        def eql?(b)
          hash == b.hash
        end

        def hash
          @positions.flat_map { |position| position.to_a }.hash
        end
      end



      # DISCUSS: rename to State or something better matching?
      # Keeps the collaboration lane positions after running, it's a "state"
      class Configuration < Struct.new(:lane_positions, :signal, :ctx, :flow_options, :last_lane, keyword_init: true) # DISCUSS: should we keep ctx/flow_options?
      end

      module Synchronous # DISCUSS: (file) location.
        module_function

        def initial_lane_positions(lanes_cfg)
          lanes_cfg.to_h.keys.collect do |activity|
            # start_catch_event_task = activity.to_h[:circuit].to_h[:start_task]
            # FIXME: in the next pro version, the "start suspend" will be here instead of its catch event.
            start_catch_event_id = Trailblazer::Activity::Introspect.Nodes(activity, task: activity.to_h[:circuit].to_h[:start_task]).id # DISCUSS: store IDs or the actual catch event in {:resumes}?

            # FIXME: set the suspend that leads to the "start catch event" as the circuit's start_task, then we don't need this here.
            # Find the suspend that resumes the actual start_catch_event
            suspend_task, _ = activity.to_h[:circuit].to_h[:map].find { |task, _| task.is_a?(Trailblazer::Workflow::Event::Suspend) && task.to_h["resumes"].include?(start_catch_event_id) }

            [
              activity,
              suspend_task # We deliberately have *one* position per lane, we're Synchronous.
            ]
          end
          .to_h
        end

        # Triggers the {start_task} event and runs the entire collaboration until message is sent and
        # the throwing activity stops in a suspend or End terminus.
        # @private
        def advance((ctx, flow), circuit_options, lane_positions:, start_task_position:, message_flow:, **)
          signal = nil

          # start_task, activity,
          loop do
            start_task_position = start_task_position.to_h

            Synchronous.validate_targeted_position(lane_positions, **start_task_position)

            circuit_options = circuit_options.merge(start_task: start_task_position[:task])

            # signal, (ctx, flow) = Activity::TaskWrap.invoke(start_task_position[:activity], [ctx, flow], **circuit_options)
            signal, (ctx, flow) = Trailblazer::Developer.wtf?(start_task_position[:activity], [ctx, flow],
              exec_context: nil, # FIXME: this is needed for Proc tasks. since we don't use Strategy.call, we never inject {:exec_context}. TODO: test with a ->(*) { snippet } task in Lane().
              **circuit_options
            )

            # now we have :throw, or not
            # @returns Event::Throw::Queued

            # now, "log" the collaboration's state.
            lane_positions = advance_position(lane_positions, start_task_position[:activity], signal)

            break unless flow[:throw].any?
            # break if (@options[:skip_message_from] || []).include?(flow[:throw][-1][0]) # FIXME: untested!

            debug_points_to = start_task_position[:activity].to_h[:circuit].to_h[:map][start_task_position[:task]]
            # Trailblazer::Activity::Introspect.Nodes(start_task_position[:activity], task: start_task_position[:task]).data
            puts "
>>>>>>>>> FROM \033[1msuspend ---> #{debug_points_to}\033[0m"
    puts "message from #{flow[:throw].last}"
            flow, start_task_position = receiver_task(flow, message_flow)
            # every time we "deliver" a message, we should check if it's allowed (meaning the receiving activity is actually in the targeted catch event)
          end

          return Configuration.new(
            lane_positions: lane_positions,
            signal:         signal,
            last_lane:      start_task_position[:activity], # DISCUSS: do we need that, or should we infer that using {signal}?
          ),
          [ctx, flow]
        end

        # @private
        # every time we "deliver" a message, we should check if it's allowed (meaning the receiving activity is actually in the targeted catch event)
        # {:activity} and {:task} are the targeted position.
        def validate_targeted_position(lane_positions, activity:, task:)
          # the *actual* receiver position, where we're currently.
          actual_receiver_task = lane_positions[activity] # receiver should always be in a suspend task/event gateway.

          puts "######### | #{task}
>>>>>>>>> #{actual_receiver_task}"
#           puts

          reachable_catch_events = actual_receiver_task.to_h["resumes"]
            .collect { |catch_id| Trailblazer::Activity::Introspect.Nodes(activity, id: catch_id).task }

          # if possible_catch_event_ids =
          return true if reachable_catch_events.include?(task)
          # end

          raise "Message can't be passed to #{task} because #{activity} is not in appropriate position"
        end

        # @private
        # @param signal Workflow::Event::Suspend
        def advance_position(lane_positions, activity, suspend_event)
          lane_positions.replace(activity, suspend_event)
        end

        # @private
        def receiver_task(flow, message_flow)
          next_throw, *remaining = flow[:throw]

          throwing_event  = next_throw[0] # DISCUSS: why array in Synchronous?
          flow = flow.merge(throw: remaining)

          return flow, receiver_position_for(message_flow, throwing_event)
        end

        # @private
        def receiver_position_for(message_flow, throwing_event)
          receiver_activity, catch_task = message_flow.fetch(throwing_event)

          Position.new(receiver_activity, catch_task)
        end
      end # Synchronous
    end
  end
end
