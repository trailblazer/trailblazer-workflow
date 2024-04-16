module Trailblazer
  module Workflow
    # DISCUSS: move to state discovery.
    module Discovery
      module_function

      module Stub
        module_function

        require "trailblazer/activity/testing"
        def stub_task(lane_label, task_label)
          stub_task_name = "#{lane_label}:#{task_label}".to_sym # name of the method.
          # puts "@@@@@ ^^^^^^^^^ #{stub_task_name.inspect}"
          stub_task = Trailblazer::Activity::Testing.def_tasks(stub_task_name).method(stub_task_name)
        end

        def call(json_filename:)
          ctx = Trailblazer::Workflow::Collaboration.structure_from_filename(json_filename)

          stubbed_lanes = ctx[:intermediates].collect do |json_id, intermediate|
            lane_task_2_wiring = intermediate.wiring.find_all { |task_ref, _| task_ref.data[:type] == :task }

            stubbed_tasks = lane_task_2_wiring.collect do |task_ref, wiring|
              [
                task_label = task_ref.data[:label],
                stub_task(json_id, task_label)
              ]
            end.to_h

            [
              json_id,
              {label: rand, icon: rand, implementation: stubbed_tasks}
            ]
          end.to_h

          # TODO: add outputs

          _schema = Trailblazer::Workflow::Collaboration(json_file: json_filename, lanes: stubbed_lanes) # FIXME: we're re-parsing JSON.
        end
      end

      # Find all possible configurations for a {collaboration} by replacing
      # its tasks with mocks, and run through all possible paths.
      # FIXME: initial_lane_positions defaulting is not tested.
      def call(json_filename:, start_lane:, dsl_options_for_run_multiple_times: {})
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

        collaboration = Stub.(json_filename: json_filename)

        initial_lane_positions = Collaboration::Synchronous.initial_lane_positions(collaboration.to_h[:lanes])
        initial_lane_positions = Collaboration::Positions.new(initial_lane_positions.collect { |activity, task| Trailblazer::Workflow::Collaboration::Position.new(activity, task) }) # FIXME: initial_lane_positions should return {Collaboration::Positions}

        start_activity = collaboration.to_h[:lanes].(json_id: start_lane)[:activity]
        start_task = start_activity.to_h[:circuit].to_h[:start_task]
        start_task_position = Collaboration::Position.new(start_activity, start_task)

        message_flow = collaboration.to_h[:message_flow]

        original_lanes = collaboration.to_h[:lanes] # this dictates the order within created Positions.



        run_multiple_times = Trailblazer::Workflow::Discovery::DSL.configuration_for_branching_from_user_hash(
          dsl_options_for_run_multiple_times,
          **collaboration.to_h
        )



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
        already_visited_catch_events_again = {} # FIXME: well, yeah. TODO: implement this

        while resumes_to_invoke.any?

          (start_task_position, lane_positions, ctx_merge, config_payload) = resumes_to_invoke.shift
          puts "~~~~~~~~~"

          debug = "invoking #{catch_label = Introspect::Present.readable_name_for_catch_event(*start_task_position.to_a, lanes_cfg: original_lanes, show_lane_icon: false)}"
          puts "\u001b[44m#{debug}\u001b[0m #{config_payload}" # invoking ⏵︎Notify approver {:outcome=>:failure} {:"approver:xxx"=>Trailblazer::Activity::Left}

          # raise if catch_label =~ /evise/
          # puts "@@@@@ #{start_task_position.inspect} (#{lane_positions.to_a[0]})"

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
            positions_before:         [lane_positions, start_task_position]
          )

          discovered_state = discovered_state.merge(ctx_before: [ctx.inspect])
puts "@@@@@ #{ctx.inspect}"
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
            suspend_configuration: suspend_configuration
          )

          # figure out possible next resumes/catchs:
          last_lane        = configuration.last_lane
          suspend_terminus = configuration.lane_positions[last_lane]

          discovered_states << discovered_state

          next if suspend_terminus.instance_of?(Trailblazer::Activity::End) # a real end event!
          # elsif suspend_terminus.is_a?(Trailblazer::Activity::Railway::End) # a real end event!

          # Go through all possible resume/catch events and "remember" them
          suspend_terminus.to_h["resumes"].each do |catch_event_id|
            catch_event = Trailblazer::Activity::Introspect.Nodes(last_lane, id: catch_event_id).task

            # Key by catch event *and* the suspend gateway. Why? Because just because you're seeing the same
            # catch event from a suspend doesn't mean it's the same suspend! Remember: after reject?&Revise
            suspend_catch_tuple = [suspend_terminus, catch_event]

            unless already_visited_catch_events[suspend_catch_tuple]
              # puts "queueing #{Introspect::Present.readable_name_for_catch_event(last_lane, catch_event, lanes_cfg: original_lanes, show_lane_icon: false)} #{catch_event.inspect} "

              resumes_to_invoke << [
                Trailblazer::Workflow::Collaboration::Position.new(last_lane, catch_event),
                configuration.lane_positions,
                {},
                {outcome: :success}
              ]
            end

            already_visited_catch_events[suspend_catch_tuple] = true
          end
        end

        return discovered_states, collaboration
      end

      module DSL
        module_function

        def configuration_for_branching_from_user_hash(branch_cfg, lanes:, **)
          branch_cfg.collect do |(json_id, cdt_task_label), cfg|
            activity = lanes.(json_id: json_id)[:activity]

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
