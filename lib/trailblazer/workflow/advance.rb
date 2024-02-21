# Runtime
module Trailblazer
  module Workflow
    module Advance
      module_function

      def call(ctx, event_label:, iteration_set:, message_flow:, **)
        planned_iteration = iteration_set.to_a.find { |iteration| iteration.event_label == event_label }

        # TODO: run the state guard here.

        # TODO: those positions could also be passed in manually, without using an Iteration::Set.
        position_options = position_options_from_iteration(planned_iteration) # :start_task_position and :start_positions


        configuration, (ctx, flow_options) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            [ctx, {throw: []}],
            {}, # circuit_options

            **position_options,
            message_flow: message_flow,
          )

        signal = return_signal_for(configuration, iteration_set, **position_options,)

        return signal, [ctx, flow_options]
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
