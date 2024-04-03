# Runtime
module Trailblazer
  module Workflow
    # * Advance knows if an iteration was executed successfully or not (=> iteration set),
    #   hence the success/failure return signal.

    # TODO:
    # * wire the event_valid? step to {invalid_state} terminus and handle that differently in the endpoint.
    class Advance <  Trailblazer::Activity::Railway
      terminus :invalid_event

      step task: :compute_catch_event_tuple, Output(:failure) => Track(:invalid_event)
      step task: :find_position_options
      step task: :advance

      def compute_catch_event_tuple((ctx, flow_options), **)
        iteration_set, event_label = flow_options[:iteration_set], flow_options[:event_label]

        # DISCUSS: maybe it's not a future-compatible idea to use the {iteration_set} for the state label lookup?
        #          it's probably cleaner to have a dedicated state_table.
        #          it should compute activity/start_task (catch event ID) from the event label.
        planned_iteration = iteration_set.to_a.find { |iteration| iteration.event_label == event_label }
        return Activity::Left, [ctx, flow_options] unless planned_iteration

        # TODO: those positions could also be passed in manually, without using an Iteration::Set.
        position_options_FIXME = position_options_from_iteration(planned_iteration) # :start_task_position and :start_positions
        catch_event_tuple = Introspect::Iteration::Set::Serialize.id_tuple_for(*position_options_FIXME[:start_task_position].to_a, lanes_cfg: flow_options[:lanes]) # TODO: this should be done via state_table.

       flow_options[:catch_event_tuple] = catch_event_tuple

        return Activity::Right, [ctx, flow_options]
      end

      # Computes {:start_task_position} and {:start_positions}.
      def position_options_from_iteration(iteration)
        {
          start_task_position: iteration.start_task_position, # which event to trigger
          lane_positions:     iteration.start_positions       # current position/"state"
        }
      end

      # TODO: Position object with "tuple", resolved activity/task, comment, lane label, etc. Instead of recomputing it continuously.


      # TODO: this should be done in the StateGuard realm.
      def find_position_options((ctx, flow_options), **)
        state_resolver = flow_options[:state_guards]

        _, state_options = state_resolver.(*flow_options[:catch_event_tuple], [ctx], **ctx.to_hash)

        # raise unless state_options # FIXME.

        lanes_cfg = flow_options[:lanes]
        fixme_tuples = state_options[:suspend_tuples].collect { |tuple| {"tuple" => tuple} }
        fixme_label_2_activity = lanes_cfg.to_h.values.collect { |cfg| [cfg[:label], cfg[:activity]] }.to_h

        flow_options[:position_options] = {
          start_task_position: Introspect::Iteration::Set::Deserialize.position_from_tuple(*flow_options[:catch_event_tuple].to_a, label_2_activity: fixme_label_2_activity), # FIXME: we're doing the literal opposite one step before this.
          lane_positions: Introspect::Iteration::Set::Deserialize.positions_from(fixme_tuples, label_2_activity: fixme_label_2_activity)
        }

        # raise flow_options[:position_options].inspect

        return Activity::Right, [ctx, flow_options]
      end

      # Needs Iteration::Set and an {event_label}.
      def advance((ctx, flow_options), **circuit_options)
        message_flow, position_options, iteration_set = flow_options[:message_flow], flow_options[:position_options], flow_options[:iteration_set]

        # FIXME: fix flow_options!

        configuration, (ctx, flow_options) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            [ctx, {throw: []}.merge(flow_options)], # FIXME: allow circuit_options? test?
            circuit_options,

            **position_options,
            message_flow: message_flow,
          )

        signal = return_signal_for(configuration, iteration_set, **position_options,)

        flow_options[:configuration] = configuration

        return signal, [ctx, flow_options]#, configuration
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
