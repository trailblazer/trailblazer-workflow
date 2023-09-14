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

  it "produces a runnable Activity with (Collaboration.Lane)" do
    implementing = T.def_steps(:create, :notify_approver, :reject, :accept, :revise, :publish, :archive, :delete)

    moderation_json = File.read("test/fixtures/v1/moderation.json")

    signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: moderation_json}, {}])

    article_moderation_intermediate = ctx[:intermediates]["article moderation"]

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
#<End/"Event_1p8873y">

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
 {Trailblazer::Activity::Right} => #<End/"Event_1p8873y">
#<Trailblazer::Workflow::Event::Catch/[:catch, "catch-before-Activity_0cc4us9"]>
 {Trailblazer::Activity::Right} => #<Trailblazer::Activity::TaskBuilder::Task user_proc=#<Method: #<Module:0x>.delete>>
#<Trailblazer::Workflow::Event::Throw/[:throw, "throw-after-Activity_0cc4us9"]>
 {Trailblazer::Activity::Right} => #<End/"Event_1p8873y">
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

  end
end
