module Trailblazer
  module Workflow
    class Collaboration
      class Schema
        def initialize(lanes:, message_flow:, options:{})
          @lanes                  = lanes
          @message_flow           = message_flow
          # @initial_lane_positions = Synchronous.initial_lane_positions(lanes.values)
          # @options = options # FIXME: test me!!!
        end

        # attr_reader :initial_lane_positions
        # attr_reader :message_flow
        # attr_reader :lanes # @private

        def to_h
          {
            message_flow: @message_flow,
            # initial_lane_positions: @initial_lane_positions, # DISCUSS: do we really nee
            lanes: @lanes,
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
      end

      # DISCUSS: rename to State or something better matching?
      # Keeps the collaboration lane positions after running, it's a "state"
      class Configuration < Struct.new(:lane_positions, :signal, :ctx, :flow_options, keyword_init: true) # DISCUSS: should we keep ctx/flow_options?
      end

      module Synchronous # DISCUSS: (file) location.
        module_function

        # @private
        def initial_lane_positions(lanes)
          lanes.collect do |activity|
            [
              activity,
              {resume_events: [activity.to_h[:circuit].to_h[:start_task]]} # We deliberately have *one* position per lane, we're Synchronous.
            ]
          end
          .to_h
        end

        # Triggers the {start_task} event and runs the entire collaboration until message is sent and
        # the throwing activity stops in a suspend or End terminus.
        # @private
        def advance(collaboration, (ctx, flow), circuit_options, lane_positions:, start_position:, message_flow:)
          signal = nil

          # start_task, activity,
          loop do
            start_position = start_position.to_h

            Synchronous.validate_targeted_position(lane_positions, **start_position)

            circuit_options = circuit_options.merge(start_task: start_position[:task])

            signal, (ctx, flow) = Activity::TaskWrap.invoke(start_position[:activity], [ctx, flow], **circuit_options)

            # now we have :throw, or not
            # @returns Event::Throw::Queued

            # now, "log" the collaboration's state.
            lane_positions = advance_position(lane_positions, start_position[:activity], signal)

            break unless flow[:throw].any?
            break if (@options[:skip_message_from] || []).include?(flow[:throw][-1][0]) # FIXME: untested!

            flow, start_position = receiver_task(flow, message_flow)
            # every time we "deliver" a message, we should check if it's allow (meaning the receiving activity is actually in the targeted catch event)
          end

          return Configuration.new(
            lane_positions: lane_positions,
            signal:         signal,
          ),
          [ctx, flow]
        end

        # @private
        # every time we "deliver" a message, we should check if it's allowed (meaning the receiving activity is actually in the targeted catch event)
        # {:activity} and {:task} are the targeted position.
        def validate_targeted_position(lane_positions, activity:, task:)
          receiver_position = lane_positions[activity] # receiver should always be in a suspend task/event gateway.
          # puts "@@@@@ #{start_task} ? #{receiver_position.inspect}"

          if possible_catch_events = receiver_position.to_h[:resume_events]
            return true if possible_catch_events.include?(task)
          end

          raise "Message can't be passed to #{task} because #{activity} is not in appropriate position"
        end

        # @private
        # @param signal Workflow::Event::Suspend
        def advance_position(lane_positions, activity, suspend_event)
          lane_positions.merge(activity => suspend_event)
        end
      end # Synchronous
    end
  end
end
