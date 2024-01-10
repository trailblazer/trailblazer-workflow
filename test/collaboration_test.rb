require "test_helper"

# TODO: how can we prevent users from triggering lifecycle.Create? only UI events allowed?
#
class CollaborationTest < Minitest::Spec
  it "what" do
    ui_create_form = "Activity_0wc2mcq" # TODO: this is from pro-rails tests.
    ui_create = "Activity_1psp91r"
    ui_create_valid = "Event_0km79t5"
    ui_create_invalid = "Event_0co8ygx"
    ui_update_form = 'Activity_1165bw9'
    ui_update = "Activity_0j78uzd"
    ui_update_valid = "Event_1vf88fn"
    ui_update_invalid = "Event_1nt0djb"
    ui_notify_approver = "Activity_1dt5di5"
    ui_accepted = "Event_1npw1tg"
    ui_delete_form = "Activity_0ha7224"
    ui_delete = "Activity_15nnysv"
    ui_cancel = "Activity_1uhozy1"
    ui_publish = "Activity_0bsjggk"
    ui_archive = "Activity_0fy41qq"
    ui_revise_form = "Activity_0zsock2"
    ui_revise = "Activity_1wiumzv"
    ui_revise_valid = "Event_1bz3ivj"
    ui_revise_invalid = "Event_1wly6jj"
    ui_revise_form_with_errors = "Activity_19m1lnz"
    ui_create_form_with_errors = "Activity_08p0cun"
    ui_update_form_with_errors = "Activity_00kfo8w"
    ui_rejected = "Event_1vb197y"

    # FIXME: redundant with {lane_test}.
    create_id = "Activity_0wwfenp"
    update_id = "Activity_0q9p56e"
    notify_id = "Activity_0wr78cv"
    reject_id = "Activity_0d9yewp"
    approve_id = "Activity_1qrkaz0"
    revise_id = "Activity_18qv6ob"
    publish_id = "Activity_1bjelgv"
    delete_id = "Activity_0cc4us9"
    archive_id = "Activity_1hgscu3"
    success_id = "Event_1p8873y"

    task_map = {
      "ui_create_form" => "Activity_0wc2mcq", # TODO: this is from pro-rails tests.
      "ui_create" => "Activity_1psp91r",
      "ui_create_valid" => "Event_0km79t5",
      "ui_create_invalid" => "Event_0co8ygx",
      "ui_update_form" => 'Activity_1165bw9',
      "ui_update" => "Activity_0j78uzd",
      "ui_update_valid" => "Event_1vf88fn",
      "ui_update_invalid" => "Event_1nt0djb",
      "ui_notify_approver" => "Activity_1dt5di5",
      "ui_accepted" => "Event_1npw1tg",
      "ui_delete_form" => "Activity_0ha7224",
      "ui_delete" => "Activity_15nnysv",
      "ui_cancel" => "Activity_1uhozy1",
      "ui_publish" => "Activity_0bsjggk",
      "ui_archive" => "Activity_0fy41qq",
      "ui_revise_form" => "Activity_0zsock2",
      "ui_revise" => "Activity_1wiumzv",
      "ui_revise_valid" => "Event_1bz3ivj",
      "ui_revise_invalid" => "Event_1wly6jj",
      "ui_revise_form_with_errors" => "Activity_19m1lnz",
      "ui_create_form_with_errors" => "Activity_08p0cun",
      "ui_update_form_with_errors" => "Activity_00kfo8w",
      "ui_rejected" => "Event_1vb197y",
    }


    moderation_json = File.read("test/fixtures/v1/moderation.json")
    signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: moderation_json}, {}])

    article_moderation_intermediate = ctx[:intermediates]["article moderation"]
    # pp article_moderation_intermediate

    implementing = Trailblazer::Activity::Testing.def_steps(:create, :update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete)

    lane_activity = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create" => implementing.method(:create),
      "Update" => implementing.method(:update),
      "Approve" => implementing.method(:approve),
      "Notify approver" => implementing.method(:notify_approver),
      "Revise" => implementing.method(:revise),
      "Reject" => implementing.method(:reject),
      "Publish" => implementing.method(:publish),
      "Archive" => implementing.method(:archive),
      "Delete" => implementing.method(:delete),
    )


    article_moderation_intermediate = ctx[:intermediates]["<ui> author workflow"]
    # pp article_moderation_intermediate

    implementing = Trailblazer::Activity::Testing.def_steps(:create_form, :ui_create, :update_form, :ui_update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete, :delete_form, :cancel, :revise_form,
      :create_form_with_errors, :update_form_with_errors, :revise_form_with_errors)

    lane_activity_ui = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create form" => implementing.method(:create_form),
      "Create" => implementing.method(:ui_create),
      "Update form" => implementing.method(:update_form),
      "Update" => implementing.method(:ui_update),
      "Notify approver" => implementing.method(:notify_approver),
      "Publish" => implementing.method(:publish),
      "Delete" => implementing.method(:delete),
      "Delete? form" => implementing.method(:delete_form),
      "Cancel" => implementing.method(:cancel),
      "Revise" => implementing.method(:revise),
      "Revise form" => implementing.method(:revise_form),
      "Create form with errors" => implementing.method(:create_form_with_errors),
      "Update form with errors" => implementing.method(:update_form_with_errors),
      "Revise form with errors" => implementing.method(:revise_form_with_errors),
      "Archive" => implementing.method(:archive),
      # "Approve" => implementing.method(:approve),
      # "Reject" => implementing.method(:reject),
    )

    id_to_lane = {
      "article moderation"    => lane_activity,
      "<ui> author workflow"  => lane_activity_ui,
    }

    # pp ctx[:structure].lanes
    message_flow = Trailblazer::Workflow::Collaboration.Messages(
      ctx[:structure].messages,
      id_to_lane
    )

    schema = Trailblazer::Workflow::Collaboration::Schema.new(
      lanes: {
        lifecycle:  lane_activity,
        ui:         lane_activity_ui
      },
      message_flow: message_flow,
    )

    schema_hash = schema.to_h

    # raise schema_hash.keys.inspect


    missing_throw_from_notify_approver = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: "throw-after-Activity_0wr78cv").task

    decision_is_approve_throw = nil
    decision_is_reject_throw  = nil

    approver_start_suspend = nil
    approver_activity = Class.new(Trailblazer::Activity::Railway) do
      step task: approver_start_suspend = Trailblazer::Workflow::Event::Suspend.new(semantic: "invented_semantic", "resumes" => ["xxx"])

      fail :decider, id: "xxx",
        Output(:failure) => Trailblazer::Activity::Railway.Id("xxx_reject")
      fail task: decision_is_approve_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_approve")

      step task: decision_is_reject_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_reject"),
        magnetic_to: :reject, id: "xxx_reject"

      def decider(ctx, decision: true, **)
        # raise if !decision

        decision
      end
    end

    extended_message_flow = message_flow.merge(
      # "throw-after-Activity_0wr78cv"
      missing_throw_from_notify_approver => [approver_activity, Trailblazer::Activity::Introspect.Nodes(approver_activity, id: "xxx").task],
      decision_is_approve_throw => [lane_activity, Trailblazer::Activity::Introspect.Nodes(lane_activity, id: "catch-before-#{approve_id}").task],
      decision_is_reject_throw => [lane_activity, Trailblazer::Activity::Introspect.Nodes(lane_activity, id: "catch-before-#{reject_id}").task],
    )

    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(schema_hash[:lanes].values)
    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)

    extended_initial_lane_positions = initial_lane_positions.merge(
      approver_activity => approver_start_suspend
    )

# State discovery:
# The idea is that we collect suspend events and follow up on all their resumes (catch) events.
# We can't see into {Collaboration.call}, meaning we can really only collect public entry points,
# just like a user (like a controller) of our process.
# 1. one problem is, when a decision is involved in the run ahead of us we need to invoke the same
#    catch multiple times, with different input data.
#    DISCUSS: could we figure out the two different suspend termini that way, to make it easier for users to define
#    which outcome is "success"?
    resumes_to_invoke = [
      [
        start_position,
        extended_initial_lane_positions,
        {} # ctx_merge
      ]
    ]

    states = []
    additional_state_data = {}

    already_visited_catch_events = {}
    already_visited_catch_events_again = {} # FIXME: well, yeah.

    # DISCUSS: We could probably figure out "binary" paths automatically? That would
    #          imply we start from a public resume and discover the path?
    run_multiple_times = {
      # suspend after Notify approver in lifecycle
      # We're "clicking" the [Notify_approver] button again, this time to get rejected.
      Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_notify_approver}").task => {ctx_merge: {decision: false}},

      # Click [UI Create] again, with invalid data.
      Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create}").task => {ctx_merge: {create: false}}, # lifecycle create is supposed to fail.

      # Click [UI Update] again, with invalid data.
      Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_update}").task => {ctx_merge: {update: false}}, # lifecycle create is supposed to fail.
    }

    while resumes_to_invoke.any?
      (start_position, lane_positions, ctx_merge) = resumes_to_invoke.shift
      puts "~~~~~~~~~"

      ctx = {seq: []}.merge(ctx_merge)
      start_task = start_position.to_h[:task]
      if (do_again_config = run_multiple_times[start_task]) && !already_visited_catch_events_again[start_task] # TODO: do this by keying by resume event and ctx variable(s).

        resumes_to_invoke << [
          start_position,
          lane_positions, # same positions as the original situation.
          do_again_config[:ctx_merge]
        ]

        already_visited_catch_events_again[start_task] = true
      end

      # register new state.
      # Note that we do that before anything is invoked.
      states << state = [lane_positions, start_position]

      state_data = [ctx.inspect]

      configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
        schema,
        [ctx, {throw: []}],
        {}, # circuit_options

        start_position: start_position,
        lane_positions: lane_positions, # current position/"state"

        message_flow: extended_message_flow,
      )

      state_data << ctx.inspect # context after. DISCUSS: use tracing?

      additional_state_data[state.object_id] = state_data

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
            {}
          ]
        end

        already_visited_catch_events[resume_event] = true
      end
    end

    # {states} is compile-time relevant
    #  {additional_state_data} is runtime

    # DISCUSS: {states} should probably be named {reached_states} as some states appear multiple times in the list.
    def render_states(states, lanes:, additional_state_data:, task_map:)
      present_states = Trailblazer::Workflow::State::Discovery.generate_from(states) # returns rows with [{activity, suspend, resumes}]

      rows = present_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}
        # raise state.inspect

        start_position, lane_positions, discovery_state_fixme = state.to_a

        triggered_catch_event_id = Trailblazer::Activity::Introspect.Nodes(start_position.activity, task: start_position.task).id

        # Go through each lane.
        row = lane_positions.flat_map do |lane_position|
          next if lane_position.nil? # FIXME: why do we have that?

          activity, suspend, resumes = lane_position[:activity], lane_position[:suspend], lane_position[:resumes]
          # next if suspend.to_h["resumes"].nil?

        # Compute the task name that follows a particular catch event.
          resumes_labels = resumes.collect do |catch_event|

            task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]
            # raise task_after_catch.inspect

            Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
          end

          [
            lanes[activity],
            resumes_labels.inspect,

            "#{lanes[activity]} suspend",
            suspend.to_h[:semantic][1],
          ]
        end

        ctx_before, ctx_after = additional_state_data[discovery_state_fixme.object_id]
        # raise data.inspect

        triggered_catch_event_label = nil
        task_map.invert.each do |id, label|
          if triggered_catch_event_id =~ /#{id}$/
            triggered_catch_event_label = "--> #{label}" and break
          end
        end


        row = Hash[*row.compact, "ctx before", ctx_before, "ctx after", ctx_after, "triggered catch", triggered_catch_event_label]
      end
      # .uniq # comment me if you want to see all reached configurations


      puts Hirb::Helpers::Table.render(rows, fields: [
        "triggered catch",
        "UI",
        # "UI suspend",
        "lifecycle",
        # "lifecycle suspend",
        "ctx before",
        "ctx after",
      ], max_width: 186) # 186 for laptop 13"
    end

    render_states(states, lanes: {lane_activity => "lifecycle", lane_activity_ui => "UI", approver_activity => "approver"}, additional_state_data: additional_state_data, task_map: task_map)
# raise "figure out how to build a generated state table"



    testing_json = Trailblazer::Workflow::State::Discovery::Testing.render_json(
      states,
      lanes: {lane_activity => "lifecycle", lane_activity_ui => "UI", approver_activity => "approver"},
      initial_lane_positions: extended_initial_lane_positions, # DISCUSS: so we know what not to find via Introspect.
      task_map: task_map,
      additional_state_data: additional_state_data,
    )


    testing_json = JSON.pretty_generate(testing_json)
    # puts testing_json
    assert_equal testing_json, %([
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0wc2mcq"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          null
        ]
      },
      {
        "tuple": [
          "UI",
          null
        ]
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1psp91r"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          null
        ]
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_14h0q7a"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1psp91r"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          null
        ]
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_14h0q7a"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1165bw9"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_0fnbg3r"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_0kknfje"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1dt5di5"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_0fnbg3r"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_0kknfje"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0j78uzd"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_0fnbg3r"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_0nxerxv"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1dt5di5"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_0fnbg3r"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_0kknfje"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0ha7224"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_1hp2ssj"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_1sq41iq"
        ],
        "comment": null
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0bsjggk"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_1hp2ssj"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_1sq41iq"
        ],
        "comment": null
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0j78uzd"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_0fnbg3r"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_0nxerxv"
        ],
        "comment": null
      },
      {
        "tuple": [
          "approver",
          null
        ]
      }
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0zsock2"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_01p7uj7"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-gw-to-catch-before-Activity_0zsock2"
        ],
        "comment": "--> ui_revise_form"
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_15nnysv"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_1hp2ssj"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_100g9dn"
        ],
        "comment": null
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1uhozy1"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_1hp2ssj"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_100g9dn"
        ],
        "comment": null
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_0fy41qq"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-gw-to-catch-before-Activity_1hgscu3"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-gw-to-catch-before-Activity_0fy41qq"
        ],
        "comment": "--> ui_archive"
      },
      null
    ]
  },
  {
    "start_position": [
      "UI",
      "catch-before-Activity_1wiumzv"
    ],
    "expected_lane_positions": [
      {
        "tuple": [
          "lifecycle",
          "suspend-Gateway_01p7uj7"
        ],
        "comment": null
      },
      {
        "tuple": [
          "UI",
          "suspend-Gateway_1xs96ik"
        ],
        "comment": null
      },
      null
    ]
  }
])



    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(schema_hash[:lanes].values)



    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)

    configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
      schema,
      [{seq: []}, {throw: []}],
      {}, # circuit_options

      start_position: start_position,
      lane_positions: initial_lane_positions, # current position/"state"

      message_flow: schema_hash[:message_flow],
    )

# TODO: test {:last_lane}.
    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]
    assert_equal configuration.lane_positions.values.inspect, %([{"resumes"=>["catch-before-#{create_id}"], :semantic=>[:suspend, "from initial_lane_positions"]}, \
#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{ui_create}"] type=:suspend semantic=[:suspend, "suspend-Gateway_14h0q7a"]>])
    assert_equal ctx.inspect, %({:seq=>[:create_form]})

# create_form <submit>
    start_task_id = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "suspend-Gateway_14h0q7a").data["resumes"].first # "catch-before-Activity_1psp91r"
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: start_task_id).task)

    configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
      schema,
      [{seq: []}, {throw: []}],
      {}, # circuit_options

      start_position: start_position,
      lane_positions: configuration.lane_positions, # current position/"state"

      message_flow: schema_hash[:message_flow],
    )

    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]

    assert_equal configuration.lane_positions.values.inspect, %([#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{update_id}", "catch-before-#{notify_id}"] type=:suspend semantic=[:suspend, "suspend-Gateway_0fnbg3r"]>, \
#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{ui_update_form}", "catch-before-#{ui_notify_approver}"] type=:suspend semantic=[:suspend, "suspend-Gateway_0kknfje"]>])
    assert_equal ctx.inspect, %({:seq=>[:ui_create, :create]})
    # we can actually see the last signal and its semantic is {[:suspend, "suspend-Gateway_0kknfje"]}
    assert_equal configuration.signal.inspect, %(#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"] type=:suspend semantic=[:suspend, "suspend-Gateway_0kknfje"]>)
  end
end
