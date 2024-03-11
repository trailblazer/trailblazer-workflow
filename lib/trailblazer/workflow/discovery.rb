module Trailblazer
  module Workflow
    # DISCUSS: move to state discovery.
    module Discovery
      module_function

      # Find all possible configurations for a {collaboration} by replacing
      # its tasks with mocks, and run through all possible paths.
      def call(collaboration, start_task_position:, run_multiple_times: {}, initial_lane_positions: Collaboration::Synchronous.initial_lane_positions(collaboration), message_flow:)
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

        original_lanes = collaboration.to_h[:lanes] # this dictates the order within created Positions.

        collaboration, message_flow, start_task_position, initial_lane_positions, activity_2_stub, original_task_2_stub_task = stub_tasks_for(collaboration, message_flow: message_flow, start_task_position: start_task_position, initial_lane_positions: initial_lane_positions)


        resumes_to_invoke = [
          [
            start_task_position,
            initial_lane_positions,
            {}, # ctx_merge
            {outcome: :success} # config_payload
          ]
        ]

        discovered_states = []

        already_visited_catch_events = {}
        already_visited_catch_events_again = {} # FIXME: well, yeah.

        while resumes_to_invoke.any?

          (start_task_position, lane_positions, ctx_merge, config_payload) = resumes_to_invoke.shift
          puts "~~~~~~~~~"

          ctx = {seq: []}.merge(ctx_merge)
          start_task = start_task_position.to_h[:task]
          if (do_again_config = run_multiple_times[start_task]) && !already_visited_catch_events_again[start_task] # TODO: do this by keying by resume event and ctx variable(s).

            resumes_to_invoke << [
              start_task_position,
              lane_positions, # same positions as the original situation.
              do_again_config[:ctx_merge],
              do_again_config[:config_payload]
            ]

            already_visited_catch_events_again[start_task] = true
          end

          # register new state.
          # Note that we do that before anything is invoked.
          discovered_state = {}

          discovered_state = discovered_state.merge(
            stubbed_positions_before: [lane_positions, start_task_position],
            positions_before:         [unstub_positions(activity_2_stub, original_task_2_stub_task, lane_positions, lanes: original_lanes), *unstub_positions(activity_2_stub, original_task_2_stub_task, [start_task_position], lanes: Hash.new(0))]
          )

          discovered_state = discovered_state.merge(ctx_before: [ctx.inspect])

          configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
            [ctx, {throw: []}],
            {}, # circuit_options

            start_task_position: start_task_position,
            lane_positions: lane_positions, # current position/"state"

            message_flow: message_flow,
          )

        # 3. optional feature: outcome marking
          discovered_state = discovered_state.merge(outcome: config_payload[:outcome])


        # 1. optional feature: tracing
          discovered_state = discovered_state.merge(ctx_after: ctx.inspect) # context after. DISCUSS: use tracing?

        # 2. optional feature: remember stop configuration so we can use that in a test.
          # raise configuration.inspect
          suspend_configuration = configuration
          discovered_state = discovered_state.merge(
            stubbed_suspend_configuration: suspend_configuration,
            suspend_configuration: unstub_configuration(activity_2_stub, configuration, lanes: original_lanes)
          )

          # figure out possible next resumes/catchs:
          last_lane        = configuration.last_lane
          suspend_terminus = configuration.lane_positions[last_lane]

          discovered_states << discovered_state

          next if suspend_terminus.instance_of?(Trailblazer::Activity::End) # a real end event!
          # elsif suspend_terminus.is_a?(Trailblazer::Activity::Railway::End) # a real end event!

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

        return discovered_states
      end

      def stub_task(activity, task, lane_cfg:)
        node  = Activity::Introspect.Nodes(activity, task: task)
        label = node.data[:label] || node.id # TODO: test this case, when there's no {:label}.

        stub_task_name = "#{lane_cfg[:label]}:#{label}".to_sym
        stub_task = Activity::Testing.def_tasks(stub_task_name).method(stub_task_name)

        signal_2_semantic = {
          Trailblazer::Activity::Right => :success,
          Trailblazer::Activity::Left => :failure,
        }

        stubbed_task = ->(args, **circuit_options) do
          signal, (ctx, flow_options) = stub_task.(args, **circuit_options)

          # Translate signal.
          # The now stubbed task of the activity might be a nested operation, so we need to return the original signal, e.g. the Success end.
          original_signal =
            if returned_semantic = signal_2_semantic[signal]
              node.outputs.find { |output| output.to_h[:semantic] == returned_semantic }.signal
            else
              signal # FIXME: test more than two outputs.
            end

          return original_signal, [ctx, flow_options]
        end
      end

      def stub_tasks_for(collaboration, ignore_class: Trailblazer::Activity::End, message_flow:, start_task_position:, initial_lane_positions:)
        lanes = collaboration.to_h[:lanes].to_h.values # FIXME: don't use {collaboration} here!

        collected = lanes.collect do |lane_cfg|
          activity = lane_cfg[:activity]
          circuit  = activity.to_h[:circuit]
          lane_map = circuit.to_h[:map].clone

          # Filter out all termini and events.
          tasks_to_stub = lane_map.reject { |task, _| task.is_a?(ignore_class) }

          replaced_tasks = tasks_to_stub.collect do |task, _|
            stubbed_task = stub_task(activity, task, lane_cfg: lane_cfg)

            # raise label.inspect
            [task, stubbed_task]
          end.to_h

          # TODO: really remove original tasks from the circuit, as this causes confusion.
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

          # Add nodes for introspection
          new_nodes = replaced_tasks.collect do |task, stub_task|
            node = Activity::Introspect.Nodes(activity, task: task)
            new_node_attributes = Activity::Schema::Nodes::Attributes.new(node.id, stub_task, node.data, node.outputs)

            [stub_task, new_node_attributes]
          end.to_h

          existing_nodes = activity.to_h[:nodes]
          new_nodes = existing_nodes.merge(new_nodes) # DISCUSS: Nodes#merge is not official.

          new_circuit = Activity::Circuit.new(new_circuit_map, circuit.to_h[:end_events], start_task: circuit.to_h[:start_task])

          lane = Activity.new(Activity::Schema.new(new_circuit, activity.to_h[:outputs], new_nodes, activity.to_h[:config])) # FIXME: breaking taskWrap here (which is no problem, actually).

          [[lane_cfg[:label], lane], replaced_tasks]
        end

        # DISCUSS: interestingly, we don't need this map as all stubbed tasks are user tasks, and positions always reference suspends or catch events, which arent' stubbed.
        original_task_2_stub_task = collected.inject({}) { |memo, (_, replaced_tasks)| memo.merge(replaced_tasks) }

        stubbed_lanes = collected.collect { |lane_label_2_activity, _| lane_label_2_activity }.to_h

        activity_2_stub = lanes.collect { |lane_cfg| [lane_cfg[:activity], stubbed_lanes[lane_cfg[:label]]] }.to_h

        new_message_flow = message_flow.collect { |throw_evt, (activity, catch_evt)| [throw_evt, [activity_2_stub[activity], catch_evt]] }.to_h

        new_start_task_position = Collaboration::Position.new(activity_2_stub.fetch(start_task_position.activity), start_task_position.task)

        new_initial_lane_positions = initial_lane_positions.collect do |position|
          # TODO: make lane_positions {Position} instances, too.
          Collaboration::Position.new(activity_2_stub[position[0]], position[1])
        end

        new_initial_lane_positions = Collaboration::Positions.new(new_initial_lane_positions)

        return Collaboration::Schema.new(lanes: stubbed_lanes, message_flow: new_message_flow), new_message_flow, new_start_task_position, new_initial_lane_positions, activity_2_stub, original_task_2_stub_task
      end

      # Get the original lane activity and tasks for a {Positions} set from the stubbed ones.
      def unstub_positions(activity_2_stub, original_task_2_stub_task, positions, lanes: {})
        lane_activities = lanes.to_h.values

        real_positions = positions.to_a.collect do |position|
          Collaboration::Position.new(
            activity_2_stub.invert.fetch(position.activity),
            position.task # since the task will always be a suspend, a resume or terminus, we can safely use the stubbed one, which is identical to the original.
          )
        end.sort { |a, b| lane_activities.index(a.activity) <=> lane_activities.index(b.activity) }

        Collaboration::Positions.new(real_positions)
      end

      def unstub_configuration(activity_2_stub, configuration, lanes:)
        real_lane_positions = unstub_positions(activity_2_stub, nil, configuration.lane_positions, lanes: lanes)

        real_last_lane = activity_2_stub[configuration.last_lane]

        Collaboration::Configuration.new(
          **configuration.to_h,
          lane_positions: real_lane_positions,
          last_lane: real_last_lane
        )
      end

      module DSL
        module_function

        def configuration_for_branching_from_user_hash(branch_cfg, lanes:, **)
          branch_cfg.collect do |(lane_label, cdt_task_label), cfg|
            activity = lanes.(label: lane_label)[:activity]

            # Find the catch event for the CDT task.
            # TODO: in workflow, we should have an abstraction for label search.
            cdt_task, _ = Activity::Introspect.Nodes(activity).find { |task, node| node.data[:label] == cdt_task_label }

            # FIXME: what if there are more than one incoming link into {cdt_task}? do we even have something like that after exporting?
            catch_event, _ = activity.to_h[:circuit].to_h[:map].find { |task, links| links.find { |_, target| target == cdt_task } }

            [catch_event, cfg]
          end.to_h
        end
      end
    end
  end
end
