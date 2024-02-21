# Runtime
module Trailblazer
  module Workflow
    module Advance
      module_function

      def call(schema, ctx, event_label:, iteration_set:, **)
        planned_iteration = iteration_set.to_a.find { |iteration| iteration.event_label == event_label }

        # TODO: run the state guard here.

        position_options = position_options_from_iteration(planned_iteration) # :start_task_position and :start_positions


        configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            schema,
            [ctx, {throw: []}],
            {}, # circuit_options

            **position_options,
            message_flow: message_flow,
          )

      end

      # Computes {:start_task_position} and {:start_positions}.
      def position_options_from_iteration(iteration)
        {
          start_task_position: iteration.start_task_position, # which event to trigger
          lane_positions:     iteration.start_positions       # current position/"state"
        }
      end
    end
  end
end
