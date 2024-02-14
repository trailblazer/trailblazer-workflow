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

        collaboration, message_flow, start_position, initial_lane_positions = stub_tasks_for(collaboration, message_flow: message_flow, start_position: start_position, initial_lane_positions: initial_lane_positions)

        # pp collaboration.to_h[:lanes][:ui].to_h
        # raise

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

      def stub_tasks_for(collaboration, ignore_class: Trailblazer::Activity::End, message_flow:, start_position:, initial_lane_positions:)
        stubbed_lanes = collaboration.to_h[:lanes].collect do |lane_id, activity|
          circuit  = activity.to_h[:circuit]
          lane_map = circuit.to_h[:map].clone

          # Filter out all termini and events.
          tasks_to_stub = lane_map.reject { |task, links| task.is_a?(ignore_class) }

          replaced_tasks = tasks_to_stub.collect do |task, links|
            node  = Activity::Introspect.Nodes(activity, task: task)
            label = node.data[:label]

            stub_task_name = "#{lane_id}:#{label}".to_sym
            stub_task = Activity::Testing.def_steps(stub_task_name).method(stub_task_name)

            # raise label.inspect
            [task, stub_task]
          end.to_h

          # Now, "replace" (rather: "add") the original task with the stub.
          replaced_tasks.each do |task, stub_task|
            lane_map[stub_task] = lane_map[task]

            # lane_map.delete(task) # FIXME: hating this. not really necessary
          end

          # Then, replace connections pointing to the original task.
          new_circuit_map = lane_map.collect do |task, links|
            new_links = links.collect do |signal, target|
              (new_target = replaced_tasks[target]) ? [signal, new_target] : [signal, target]
            end.to_h

            [task, new_links]
          end.to_h

          new_circuit = Activity::Circuit.new(new_circuit_map, circuit.to_h[:end_events], start_task: circuit.to_h[:start_task])

          lane = Activity.new(Activity::Schema.new(new_circuit, activity.to_h[:outputs], activity.to_h[:nodes], activity.to_h[:config])) # FIXME: breaking taskWrap here (which is no problem, actually).

          # [lane_id, lane, replaced_tasks]
          [lane_id, lane]
        end.to_h

        old_activity_2_new_activity = collaboration.to_h[:lanes].collect { |lane_id, activity| [activity, stubbed_lanes[lane_id]] }.to_h

        puts "@@@@@@@@@ activity mapping @@@@@@@@@"
        pp old_activity_2_new_activity

        # stubbed_tasks = stubbed_lanes.flat_map { |id, lane, replaced_tasks| replaced_tasks.to_a }.to_h # DISCUSS: do we need this?

        # message_flow = collaboration.to_h[:message_flow]
        new_message_flow = message_flow.collect { |throw_evt, (activity, catch_evt)| [throw_evt, [old_activity_2_new_activity[activity], catch_evt]] }.to_h

        new_start_position = Collaboration::Position.new(old_activity_2_new_activity.fetch(start_position.activity), start_position.task)
        # raise start_position.inspect

        new_initial_lane_positions = initial_lane_positions.collect do |position|
          # TODO: make lane_positions {Position} instances, too.

          raise position.inspect
        end

        return Collaboration::Schema.new(lanes: stubbed_lanes, message_flow: new_message_flow), new_message_flow, new_start_position, new_initial_lane_positions
      end
    end
  end
end
