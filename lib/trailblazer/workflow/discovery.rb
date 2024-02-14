module Trailblazer
  module Workflow
    # DISCUSS: move to state discovery.
    module Discovery
      module_function

      # Find all possible configurations for a {collaboration} by replacing
      # its tasks with mocks, and run through all possible paths.
      def call(collaboration, start_position:, run_multiple_times: {}, initial_lane_positions: Collaboration::Synchronous.initial_lane_positions(collaboration), message_flow:)
        # State discovery:
    # The idea is that we collect suspend events and follow up on all their resumes (catch) events.
    # We can't see into {Collaboration.call}, meaning we can really only collect public entry points,
    # just like a user (like a controller) of our process.
    # 1. one problem is, when a decision is involved in the run ahead of us we need to invoke the same
    #    catch multiple times, with different input data.
    #    DISCUSS: could we figure out the two different suspend termini that way, to make it easier for users to define
    #    which outcome is "success"?
    #
    ## DISCUSS: We could probably figure out "binary" paths automatically? That would
        #          imply we start from a public resume and discover the path?
        # we could save work on {run_multiple_times} with this.

        resumes_to_invoke = [
          [
            start_position,
            initial_lane_positions,
            {}, # ctx_merge
            {outcome: :success} # config_payload
          ]
        ]

        states = []
        additional_state_data = {}

        already_visited_catch_events = {}
        already_visited_catch_events_again = {} # FIXME: well, yeah.

        while resumes_to_invoke.any?
          (start_position, lane_positions, ctx_merge, config_payload) = resumes_to_invoke.shift
          puts "~~~~~~~~~"

          ctx = {seq: []}.merge(ctx_merge)
          start_task = start_position.to_h[:task]
          if (do_again_config = run_multiple_times[start_task]) && !already_visited_catch_events_again[start_task] # TODO: do this by keying by resume event and ctx variable(s).

            resumes_to_invoke << [
              start_position,
              lane_positions, # same positions as the original situation.
              do_again_config[:ctx_merge],
              do_again_config[:config_payload]
            ]

            already_visited_catch_events_again[start_task] = true
          end

          # register new state.
          # Note that we do that before anything is invoked.
          states << state = [lane_positions, start_position] # FIXME: we need to add {configuration} here!

          state_data = [ctx.inspect]

          configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            collaboration,
            [ctx, {throw: []}],
            {}, # circuit_options

            start_position: start_position,
            lane_positions: lane_positions, # current position/"state"

            message_flow: message_flow,
          )

        # 3. optional feature: outcome marking
          additional_state_data[[state.object_id, :outcome]] = config_payload[:outcome]


        # 1. optional feature: tracing
          state_data << ctx.inspect # context after. DISCUSS: use tracing?
          additional_state_data[[state.object_id, :ctx]] = state_data

        # 2. optional feature: remember stop configuration so we can use that in a test.
          # raise configuration.inspect
          suspend_configuration = configuration
          additional_state_data[[state.object_id, :suspend_configuration]] = suspend_configuration

          # figure out possible next resumes/catchs:
          last_lane        = configuration.last_lane
          suspend_terminus = configuration.lane_positions[last_lane]

          next if suspend_terminus.instance_of?(Trailblazer::Activity::End) # a real end event!
          # elsif suspend_terminus.is_a?(Trailblazer::Activity::Railway::End) # a real end event!

          #   raise suspend_terminus.inspect

          # Go through all possible resume/catch events and "remember" them
          suspend_terminus.to_h["resumes"].each do |resume_event_id|
            resume_event = Trailblazer::Activity::Introspect.Nodes(last_lane, id: resume_event_id).task

            unless already_visited_catch_events[resume_event]
              resumes_to_invoke << [
                Trailblazer::Workflow::Collaboration::Position.new(last_lane, resume_event),
                configuration.lane_positions,
                {},
                {outcome: :success}
              ]
            end

            already_visited_catch_events[resume_event] = true
          end
        end

        # {states} is compile-time relevant
        #  {additional_state_data} is runtime

        return states, additional_state_data
      end
    end
  end
end
