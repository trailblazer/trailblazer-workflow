# Runtime
module Trailblazer
  module Workflow
    class Advance <  Trailblazer::Activity::Railway
      # UNAUTHORIZED_SIGNAL = "unauthorized"
      step task: :find_position_options
      step task: :event_valid?, Output(:failure) => End(:not_authorized)
      step task: :advance

      def find_position_options((ctx, flow_options), **)
        iteration_set, event_label = flow_options[:iteration_set], flow_options[:event_label]

        planned_iteration = iteration_set.to_a.find { |iteration| iteration.event_label == event_label }

        # TODO: those positions could also be passed in manually, without using an Iteration::Set.
        flow_options[:position_options] = position_options_from_iteration(planned_iteration) # :start_task_position and :start_positions

        return Activity::Right, [ctx, flow_options]
      end

      def event_valid?((ctx, flow_options), **)
        position_options = flow_options[:position_options]
        state_guards = flow_options[:state_guards]

        result = state_guards.(ctx, start_task_position: position_options[:start_task_position])

        return result ? Activity::Right : Activity::Left, [ctx, flow_options]
      end

      # Needs Iteration::Set and an {event_label}.
      def advance((ctx, flow_options), **circuit_options)
        message_flow, position_options, iteration_set = flow_options[:message_flow], flow_options[:position_options], flow_options[:iteration_set]

        # FIXME: fix flow_options!

        configuration, (ctx, flow_options) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            [ctx, {throw: []}.merge(flow_options)], # FIXME: allow circuit_options?
            circuit_options, # circuit_options

            **position_options,
            message_flow: message_flow,
          )

        signal = return_signal_for(configuration, iteration_set, **position_options,)

        flow_options[:configuration] = configuration

        return signal, [ctx, flow_options]#, configuration
      end

      # Computes {:start_task_position} and {:start_positions}.
      def position_options_from_iteration(iteration)
        {
          start_task_position: iteration.start_task_position, # which event to trigger
          lane_positions:     iteration.start_positions       # current position/"state"
        }
      end

      def return_signal_for(configuration, iteration_set, start_task_position:, **)
        collaboration_signal = configuration.signal

        # TODO: "prepare" this in a "state table"?
        # Find all recorded iterations that started with our {start_task_position}.
        iterations = iteration_set.to_a.find_all { |iteration| iteration.start_task_position == start_task_position }

        # raise state_table[start_task_position].inspect

        travelled_iteration = iterations.find { |iteration| configuration.lane_positions == iteration.suspend_positions } or raise "no matching travelled path found"

        possible_signals = {
          success: Trailblazer::Activity::Right,
          failure: Trailblazer::Activity::Left,
        }

        possible_signals.fetch(travelled_iteration.outcome)
      end
    end
  end
end
