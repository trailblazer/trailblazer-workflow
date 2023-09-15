require "test_helper"

class LaneTest < Minitest::Spec
  T = Trailblazer::Activity::Testing

  class NotifyApprover < Trailblazer::Activity::Railway
    step :notify_approver

    include T.def_steps(:notify_approver)
  end

  def approve_with_circuit_interface((ctx, flow_options), **)
    ctx[:seq] << :approve

    return Module, [ctx, flow_options]
  end

  def update_with_circuit_interface((ctx, flow_options), **)
    ctx[:seq] << :update

    return Trailblazer::Activity::Right, [ctx, flow_options]
  end

  include T::Assertions

  it "produces a runnable Activity with (Collaboration.Lane)" do
    implementing = T.def_steps(:create, :notify_approver, :reject, :accept, :revise, :publish, :archive, :delete)

    moderation_json = File.read("test/fixtures/v1/moderation.json")

    signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: moderation_json}, {}])

    article_moderation_intermediate = ctx[:intermediates]["article moderation"]
    # pp article_moderation_intermediate

    lane_activity = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create" => implementing.method(:create),
      "Update" => {task: method(:update_with_circuit_interface)},
      "Approve" => {task: method(:approve_with_circuit_interface), outputs: {success: Trailblazer::Activity::Output(Module, :success)}},
      "Notify approver" => Trailblazer::Activity::Railway.Subprocess(NotifyApprover),
      "Revise" => implementing.method(:revise),
      "Reject" => implementing.method(:reject),
      "Publish" => implementing.method(:publish),
      "Archive" => implementing.method(:archive),
      "Delete" => implementing.method(:delete),
    )

    # circuit = Trailblazer::Activity::Introspect::Render.(lane_activity, inspect_end: method(:render_lane_task))
    circuit = Trailblazer::Activity::Introspect::Render.(lane_activity)

# puts circuit

    assert_equal circuit, %(
#<Trailblazer::Workflow::Event::Throw/[:throw, "Event_0odjl3c"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-gw-to-catch-before-Activity_0wwfenp"]>
#<Trailblazer::Workflow::Event::Throw/[:throw, "Event_0txlti3"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_0fnbg3r"]>
#<End/"success">

#<Trailblazer::Workflow::Event::Throw/[:throw, "Event_1oucl4z"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_01p7uj7"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.create>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0wwfenp"]>
 {Trailblazer::Activity::Left} => #<Trailblazer::Workflow::Event::Throw/[:throw, "Event_0odjl3c"]>
#<Method: LaneTest#update_with_circuit_interface(_, **) test/lane_test.rb:18>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0q9p56e"]>
 {Trailblazer::Activity::Left} => #<Trailblazer::Workflow::Event::Throw/[:throw, "Event_0txlti3"]>
LaneTest::NotifyApprover
 {#<Trailblazer::Activity::End semantic=:success>} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0wr78cv"]>
#<Method: LaneTest#approve_with_circuit_interface(_, **) test/lane_test.rb:12>
 {Module} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1qrkaz0"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.publish>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1bjelgv"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.archive>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1hgscu3"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.delete>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0cc4us9"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.revise>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_18qv6ob"]>
 {Trailblazer::Activity::Left} => #<Trailblazer::Workflow::Event::Throw/[:throw, "Event_1oucl4z"]>
#<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.reject>>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0d9yewp"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0wwfenp"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.create>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0wwfenp"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_0fnbg3r"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0q9p56e"]>
 {Trailblazer::Activity::Right} => #<Method: LaneTest#update_with_circuit_interface(_, **) test/lane_test.rb:18>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0q9p56e"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1wzosup"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0wr78cv"]>
 {Trailblazer::Activity::Right} => LaneTest::NotifyApprover
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0wr78cv"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_0y3f8tz"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_1qrkaz0"]>
 {Trailblazer::Activity::Right} => #<Method: LaneTest#approve_with_circuit_interface(_, **) test/lane_test.rb:12>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1qrkaz0"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1hp2ssj"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_1bjelgv"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.publish>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1bjelgv"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-gw-to-catch-before-Activity_1hgscu3"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_1hgscu3"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.archive>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_1hgscu3"]>
 {Trailblazer::Activity::Right} => #<End/"success">
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0cc4us9"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.delete>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0cc4us9"]>
 {Trailblazer::Activity::Right} => #<End/"success">
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_18qv6ob"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.revise>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_18qv6ob"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1kl7pnm"]>
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0d9yewp"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.reject>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0d9yewp"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_01p7uj7"]>
#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_0fnbg3r"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1wzosup"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_0y3f8tz"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1hp2ssj"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_01p7uj7"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-Gateway_1kl7pnm"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-gw-to-catch-before-Activity_0wwfenp"]>

#<Trailblazer::Workflow::Event::Suspend/[:suspend, "suspend-gw-to-catch-before-Activity_1hgscu3"]>
)

  # it "runs as expected" do

      # start_from: ["catch-before-Create"]

  #   # We need a language to find/specify suspends.
  #   # Explict, but too redundant:
  #   suspend = Suspend("Create" => ["Update", "Notify approver"])
  #   # Better
  #   suspend = Suspend(after: "Create")

    # We need a "table" of suspends cause that's where we stop and start.

    # Event is a string pointing to a particular catch event: "catch-before-Create".
    #       Along with it comes user data, e.g. from a form submission
    #


    # First pseudo "moment":
    # terminating_suspend: {suspend_id: "Start.default", catch_ids: ["catch-before-Create"]}, # suspend we terminated in.

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

    # create
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{create_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{create_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_0fnbg3r", catch_ids: ["catch-before-#{update_id}", "catch-before-#{notify_id}"]}, # suspend we terminated in.
      seq:                  "[:create]"

    # update
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{update_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{update_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_1wzosup", catch_ids: ["catch-before-#{update_id}", "catch-before-#{notify_id}"]}, # suspend we terminated in.
      seq:                  "[:update]"

    # notify_approver
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{notify_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{notify_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_0y3f8tz", catch_ids: ["catch-before-#{reject_id}", "catch-before-#{approve_id}"]}, # suspend we terminated in.
      seq:                  "[:notify_approver]"

    # reject
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{reject_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{reject_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_01p7uj7", catch_ids: ["catch-before-#{revise_id}"]}, # suspend we terminated in.
      seq:                  "[:reject]"

    # revise, invalid
    assert_advance lane_activity,
      revise:               false,
      catch_event_id:       "catch-before-#{revise_id}", # this is what we want to trigger.
      throw_id:             "Event_1oucl4z", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_01p7uj7", catch_ids: ["catch-before-#{revise_id}"]}, # suspend we terminated in.
      seq:                  "[:revise]"

    # revise, valid
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{revise_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{revise_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_1kl7pnm", catch_ids: ["catch-before-#{revise_id}", "catch-before-#{notify_id}"]}, # suspend we terminated in.
      seq:                  "[:revise]"

    # approve
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{approve_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{approve_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-Gateway_1hp2ssj", catch_ids: ["catch-before-#{delete_id}", "catch-before-#{update_id}", "catch-before-#{publish_id}"]}, # suspend we terminated in.
      seq:                  "[:approve]"

    # publish
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{publish_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{publish_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: "suspend-gw-to-catch-before-#{archive_id}", catch_ids: ["catch-before-#{archive_id}"]}, # suspend we terminated in.
      seq:                  "[:publish]"

    # archive_id
    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{archive_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{archive_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: success_id, catch_ids: []}, # suspend we terminated in.
      seq:                  "[:archive]",
      terminus: "success"

    assert_advance lane_activity,
      catch_event_id:       "catch-before-#{delete_id}", # this is what we want to trigger.
      throw_id:             "throw-after-#{delete_id}", # expected throw(s).
      terminating_suspend:  {suspend_id: success_id, catch_ids: []}, # suspend we terminated in.
      seq:                  "[:delete]",
      terminus: "success"
  end

  def assert_advance(lane_activity, catch_event_id:, index: 0, throw_id:, terminating_suspend:, terminus: [:suspend, terminating_suspend[:suspend_id]], **options)
    # suspend_before_create = Trailblazer::Workflow::Moment.suspend_before(lane_activity, last_position)
    # catch_id = suspend_before_create.to_h["resumes"][index]

    catch_before_create = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: catch_event_id).task

    signal, (ctx, flow_options) = assert_invoke lane_activity,
      terminus: terminus,
      flow_options: {throw: []},
      circuit_options: {start_task: catch_before_create}, **options

    # Make sure we threw {:throw_event}.
    throw_event = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: throw_id).task

    assert_equal flow_options[:throw], [[throw_event, "message"]]

    assert_suspend(lane_activity, signal: signal, **terminating_suspend)
  end

  # Assert that we terminate in a particular suspend.
  def assert_suspend(lane_activity, signal:, suspend_id:, catch_ids:)
    suspend = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: suspend_id).task

    # Make sure we hit {:suspend_id}.
    assert_equal signal, suspend, "suspends not equal"
    assert_equal (suspend.to_h["resumes"] || []).sort, catch_ids.sort
  end
end
