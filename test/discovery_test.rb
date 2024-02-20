require "test_helper"

class DiscoveryTest < Minitest::Spec
  extend BuildSchema

  def self.states
    ui_create_form = "Activity_0wc2mcq" # TODO: this is from pro-rails tests.
    ui_create = "Activity_1psp91r"
    ui_update = "Activity_0j78uzd"
    ui_notify_approver = "Activity_1dt5di5"

    # TODO: either {lanes} or {lanes_cfg}.
    schema, lanes, message_flow, initial_lane_positions, lanes_cfg = build_schema()

    lane_activity = lanes[:lifecycle]
    lane_activity_ui = lanes[:ui]
    approver_activity = lanes[:approver]

    lanes_sorted = [lane_activity, lane_activity_ui, approver_activity]


    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)


    states = Trailblazer::Workflow::Discovery.(
      schema,
      initial_lane_positions: initial_lane_positions,
      start_position: start_position,
      message_flow: message_flow,

      # TODO: allow translating the original "id" (?) to the stubbed.
      run_multiple_times: {
         # We're "clicking" the [Notify_approver] button again, this time to get rejected.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_notify_approver}").task => {ctx_merge: {
              # decision: false, # TODO: this is how it should be.
              :"approver:xxx" => Trailblazer::Activity::Left, # FIXME: {:decision} must be translated to {:"approver:xxx"}
            }, config_payload: {outcome: :failure}},

          # Click [UI Create] again, with invalid data.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create}").task => {ctx_merge: {
              # create: false
              :"lifecycle:Create" => Trailblazer::Activity::Left,
            }, config_payload: {outcome: :failure}}, # lifecycle create is supposed to fail.

          # Click [UI Update] again, with invalid data.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_update}").task => {ctx_merge: {
              # update: false
              :"lifecycle:Update" => Trailblazer::Activity::Left,
            }, config_payload: {outcome: :failure}}, # lifecycle create is supposed to fail.
      }
    )

    return states, lanes_sorted, lanes_cfg, schema, message_flow
  end

  it "Discovery.call" do
    states, lanes_sorted, lanes_cfg = self.class.states

    # pp states
    # TODO: should we really assert the state table manually?
    assert_equal states.size, 15

    assert_position_before states[0][:positions_before],
      ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-gw-to-catch-before-Activity_0wc2mcq", "~suspend~"],
      start_id: "catch-before-Activity_0wc2mcq",
      lanes: lanes_sorted

    assert_position_after states[0][:suspend_configuration],
      ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[1][:positions_before],
      ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      start_id: "catch-before-Activity_1psp91r",
      lanes: lanes_sorted

    assert_position_after states[1][:suspend_configuration],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[2][:positions_before],
      ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      start_id: "catch-before-Activity_1psp91r",
      lanes: lanes_sorted

    assert_position_after states[2][:suspend_configuration],
      ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[3][:positions_before],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"],
      start_id: "catch-before-Activity_1165bw9",
      lanes: lanes_sorted

    assert_position_after states[3][:suspend_configuration],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[4][:positions_before],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"],
      start_id: "catch-before-Activity_1dt5di5",
      lanes: lanes_sorted

    assert_position_after states[4][:suspend_configuration],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[5][:positions_before],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      start_id: "catch-before-Activity_0j78uzd",
      lanes: lanes_sorted

    assert_position_after states[5][:suspend_configuration],
      ["suspend-Gateway_1wzosup", "suspend-Gateway_1g3fhu2", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[6][:positions_before],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"],
      start_id: "catch-before-Activity_1dt5di5",
      lanes: lanes_sorted

    assert_position_after states[6][:suspend_configuration],
      ["suspend-Gateway_01p7uj7", "suspend-gw-to-catch-before-Activity_0zsock2", "End.success"],
      lanes: lanes_sorted

    assert_position_before states[7][:positions_before],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "End.failure"],
      start_id: "catch-before-Activity_0ha7224",
      lanes: lanes_sorted

    assert_position_after states[7][:suspend_configuration],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[8][:positions_before],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "End.failure"],
      start_id: "catch-before-Activity_0bsjggk",
      lanes: lanes_sorted

    assert_position_after states[8][:suspend_configuration],
      ["suspend-gw-to-catch-before-Activity_1hgscu3", "suspend-gw-to-catch-before-Activity_0fy41qq", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[9][:positions_before],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      start_id: "catch-before-Activity_0j78uzd",
      lanes: lanes_sorted

    assert_position_after states[9][:suspend_configuration],
      ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      lanes: lanes_sorted

    assert_position_before states[10][:positions_before],
      ["suspend-Gateway_01p7uj7", "suspend-gw-to-catch-before-Activity_0zsock2", "End.success"],
      start_id: "catch-before-Activity_0zsock2",
      lanes: lanes_sorted

    assert_position_after states[10][:suspend_configuration],
      ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "End.success"],
      lanes: lanes_sorted

    assert_position_before states[11][:positions_before],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "End.failure"],
      start_id: "catch-before-Activity_15nnysv",
      lanes: lanes_sorted

    assert_position_after states[11][:suspend_configuration],
      ["Event_1p8873y", "Event_0h6yhq6", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[12][:positions_before],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "End.failure"],
      start_id: "catch-before-Activity_1uhozy1",
      lanes: lanes_sorted

    assert_position_after states[12][:suspend_configuration],
      ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[13][:positions_before],
      ["suspend-gw-to-catch-before-Activity_1hgscu3", "suspend-gw-to-catch-before-Activity_0fy41qq", "End.failure"],
      start_id: "catch-before-Activity_0fy41qq",
      lanes: lanes_sorted

    assert_position_after states[13][:suspend_configuration],
      ["Event_1p8873y", "Event_0h6yhq6", "End.failure"],
      lanes: lanes_sorted

    assert_position_before states[14][:positions_before],
      ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "End.success"],
      start_id: "catch-before-Activity_1wiumzv",
      lanes: lanes_sorted

    assert_position_after states[14][:suspend_configuration],
      ["suspend-Gateway_1kl7pnm", "suspend-Gateway_1g3fhu2", "End.success"],
      lanes: lanes_sorted

    assert_nil states[15]
  end

  it "Iteration::Set" do
    states, lanes_sorted, lanes_cfg = self.class.states

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    testing_json = JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))
    # File.write "test/iteration_json.json",  testing_json
    assert_equal testing_json, File.read("test/iteration_json.json")

    iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(testing_json), lanes_cfg: lanes_cfg)

    assert_equal JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg)), JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set_from_json, lanes_cfg: lanes_cfg))

    # assert_equal iteration_set_from_json.to_a.collect { |iteration| iteration.to_h }, iteration_set.to_a.collect { |iteration| iteration.to_h }

    # pp iteration_set_from_json.to_a.collect { |iteration| iteration.to_h }[0]

    # TODO: test {Set#to_a}
    assert_equal iteration_set_from_json.to_a.size, 15
  end

  # Asserts
  #   * that positions are always sorted by activity.
  def assert_position_before(actual_positions, expected_ids, start_id:, lanes:)
    actual_lane_positions, actual_start_position = actual_positions

    assert_positions_for(actual_lane_positions, expected_ids, lanes: lanes)

    assert_equal Trailblazer::Activity::Introspect.Nodes(actual_start_position.activity, task: actual_start_position.task).id, start_id, "start task mismatch"
  end

  def assert_positions_for(actual_lane_positions, expected_ids, lanes:)
    # puts actual_lane_positions.collect { |(a, t)| Trailblazer::Activity::Introspect.Nodes(a, task: t).id }.inspect

    actual_lane_positions.collect.with_index do |actual_position, index|
      actual_activity, actual_task = actual_position.to_a

      expected_activity = lanes[index]

      assert_equal [actual_activity, Trailblazer::Activity::Introspect.Nodes(actual_activity, task: actual_task).id],
        [expected_activity, expected_ids[index]]
    end
  end

  def assert_position_after(actual_configuration, expected_ids, lanes:)
    actual_positions = actual_configuration.lane_positions

    assert_positions_for(actual_positions, expected_ids, lanes: lanes)
  end

  it "{#render_cli_state_table}" do
    states, lanes_sorted, lanes_cfg = self.class.states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    cli_state_table = Trailblazer::Workflow::Introspect::StateTable.(iteration_set, lanes_cfg: lanes_cfg)
    puts cli_state_table
    assert_equal cli_state_table,
%(+---------------------------------+----------------------------------------+
| state name                      | triggerable events                     |
+---------------------------------+----------------------------------------+
| "⏸︎ Create form"                 | "☝ ⏵︎Create form"                       |
| "⏸︎ Create"                      | "☝ ⏵︎Create"                            |
| "⏸︎ Update form/Notify approver" | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver" |
| "⏸︎ Update"                      | "☝ ⏵︎Update"                            |
| "⏸︎ Delete? form/Publish"        | "☝ ⏵︎Delete? form", "☝ ⏵︎Publish"        |
| "⏸︎ Revise form"                 | "☝ ⏵︎Revise form"                       |
| "⏸︎ Delete/Cancel"               | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"               |
| "⏸︎ Archive"                     | "☝ ⏵︎Archive"                           |
| "⏸︎ Revise"                      | "☝ ⏵︎Revise"                            |
+---------------------------------+----------------------------------------+)

  end

  # DISCUSS: currently, this event table doesn't make a lot of sense.
  it "{Present::EventTable.call}" do
    states, lanes_sorted, lanes_cfg = self.class.states()

    cli_state_table_with_ids = Trailblazer::Workflow::Discovery::Present::EventTable.(states, render_ids: true, hide_lanes: ["approver"], lanes_cfg: lanes_cfg)
puts cli_state_table_with_ids
assert_equal cli_state_table_with_ids,
%(+-------------------------------+---------------------------------------------+---------------------------------------------+
| triggered event               | lifecycle                                   | UI                                          |
+-------------------------------+---------------------------------------------+---------------------------------------------+
| ☝ ⏵︎Create form                | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create form                              |
| catch-before-Activity_0wc2mcq | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-gw-to-catch-before-Activity_0wc2mcq |
| ☝ ⏵︎Create                     | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create                                   |
| catch-before-Activity_1psp91r | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| ☝ ⏵︎Create                     | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create                                   |
| catch-before-Activity_1psp91r | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| ☝ ⏵︎Update form                | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1165bw9 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Update                     | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update                                   |
| catch-before-Activity_0j78uzd | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Delete? form               | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish       |
| catch-before-Activity_0ha7224 | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| ☝ ⏵︎Publish                    | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish       |
| catch-before-Activity_0bsjggk | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| ☝ ⏵︎Update                     | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update                                   |
| catch-before-Activity_0j78uzd | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| ☝ ⏵︎Revise form                | ⛾ ⏵︎Revise                                   | ☝ ⏵︎Revise form                              |
| catch-before-Activity_0zsock2 | suspend-Gateway_01p7uj7                     | suspend-gw-to-catch-before-Activity_0zsock2 |
| ☝ ⏵︎Delete                     | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Delete ⏵︎Cancel                           |
| catch-before-Activity_15nnysv | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| ☝ ⏵︎Cancel                     | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Delete ⏵︎Cancel                           |
| catch-before-Activity_1uhozy1 | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| ☝ ⏵︎Archive                    | ⛾ ⏵︎Archive                                  | ☝ ⏵︎Archive                                  |
| catch-before-Activity_0fy41qq | suspend-gw-to-catch-before-Activity_1hgscu3 | suspend-gw-to-catch-before-Activity_0fy41qq |
| ☝ ⏵︎Revise                     | ⛾ ⏵︎Revise                                   | ☝ ⏵︎Revise                                   |
| catch-before-Activity_1wiumzv | suspend-Gateway_01p7uj7                     | suspend-Gateway_1xs96ik                     |
+-------------------------------+---------------------------------------------+---------------------------------------------+)
  end
end

class DiscoveryTestPlanTest < Minitest::Spec
  it "render comment header for test plan" do
    states, lanes_sorted, lanes_cfg = DiscoveryTest.states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    # this usually happens straight after discovery:
    test_plan_comment_header = Trailblazer::Workflow::Test::Plan.render_comment_header(iteration_set, lanes_cfg: lanes_cfg)
    puts test_plan_comment_header
    assert_equal test_plan_comment_header,
%(+----------------------+---------------------------------------------------------------------------------+---------------------------------------------------------------------------------+
| triggered catch      | start configuration                                                             | expected reached configuration                                                  |
+----------------------+---------------------------------------------------------------------------------+---------------------------------------------------------------------------------+
| ☝ ⏵︎Create form       | ⛾ ⏵︎Create                  ☝ ⏵︎Create form                        ☑ ⏵︎xxx         | ⛾ ⏵︎Create                  ☝ ⏵︎Create                             ☑ ⏵︎xxx         |
| ☝ ⏵︎Create            | ⛾ ⏵︎Create                  ☝ ⏵︎Create                             ☑ ⏵︎xxx         | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx         |
| ☝ ⏵︎Create ⛞          | ⛾ ⏵︎Create                  ☝ ⏵︎Create                             ☑ ⏵︎xxx         | ⛾ ⏵︎Create                  ☝ ⏵︎Create                             ☑ ⏵︎xxx         |
| ☝ ⏵︎Update form       | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx         | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update                             ☑ ⏵︎xxx         |
| ☝ ⏵︎Notify approver   | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx         | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish ☑ ◉End.failure |
| ☝ ⏵︎Update            | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update                             ☑ ⏵︎xxx         | ⛾ ⏵︎Notify approver ⏵︎Update ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx         |
| ☝ ⏵︎Notify approver ⛞ | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ⏵︎xxx         | ⛾ ⏵︎Revise                  ☝ ⏵︎Revise form                        ☑ ◉End.success |
| ☝ ⏵︎Delete? form      | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish ☑ ◉End.failure | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Delete ⏵︎Cancel                     ☑ ◉End.failure |
| ☝ ⏵︎Publish           | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish ☑ ◉End.failure | ⛾ ⏵︎Archive                 ☝ ⏵︎Archive                            ☑ ◉End.failure |
| ☝ ⏵︎Update ⛞          | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update                             ☑ ⏵︎xxx         | ⛾ ⏵︎Update ⏵︎Notify approver ☝ ⏵︎Update                             ☑ ⏵︎xxx         |
| ☝ ⏵︎Revise form       | ⛾ ⏵︎Revise                  ☝ ⏵︎Revise form                        ☑ ◉End.success | ⛾ ⏵︎Revise                  ☝ ⏵︎Revise                             ☑ ◉End.success |
| ☝ ⏵︎Delete            | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Delete ⏵︎Cancel                     ☑ ◉End.failure | ⛾ ◉End.success             ☝ ◉End.success                        ☑ ◉End.failure |
| ☝ ⏵︎Cancel            | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Delete ⏵︎Cancel                     ☑ ◉End.failure | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish ☑ ◉End.failure |
| ☝ ⏵︎Archive           | ⛾ ⏵︎Archive                 ☝ ⏵︎Archive                            ☑ ◉End.failure | ⛾ ◉End.success             ☝ ◉End.success                        ☑ ◉End.failure |
| ☝ ⏵︎Revise            | ⛾ ⏵︎Revise                  ☝ ⏵︎Revise                             ☑ ◉End.success | ⛾ ⏵︎Revise ⏵︎Notify approver ☝ ⏵︎Update form ⏵︎Notify approver       ☑ ◉End.success |
+----------------------+---------------------------------------------------------------------------------+---------------------------------------------------------------------------------+)
  end
end

class TestPlanExecutionTest < Minitest::Spec
  include Trailblazer::Workflow::Test::Assertions
  require "trailblazer/test/assertions"
  include Trailblazer::Test::Assertions # DISCUSS: this is for assert_advance and friends.

  it "run test plan" do
    states, lanes_sorted, lanes_cfg, schema, message_flow = DiscoveryTest.states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    #@ Test plan
    # FIXME: properly test this output!
    puts Trailblazer::Workflow::Test::Plan.for(iteration_set, lanes_cfg: lanes_cfg, input: {})


    # TODO: encapsulate
    # plan_structure = Trailblazer::Workflow::Test::Plan::Structure.serialize(states, lanes_cfg: lanes_cfg)
    # testing_json = JSON.pretty_generate(plan_structure)
    # test_plan_structure = Trailblazer::Workflow::Test::Plan::Structure.deserialize(plan_structure, lanes_cfg: lanes_cfg)
    test_plan_structure = iteration_set

    # test: ☝ ⏵︎Create form
    ctx = assert_advance "☝ ⏵︎Create form", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:create_form], reader: :[]

    # test: ☝ ⏵︎Create
    ctx = assert_advance "☝ ⏵︎Create", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:ui_create, :create], reader: :[]

    # test: ☝ ⏵︎Create ⛞
    ctx = assert_advance "☝ ⏵︎Create ⛞", ctx: {create: false, seq: []}, expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:ui_create, :create, :create_form_with_errors], reader: :[]

    # test: ☝ ⏵︎Update form
    ctx = assert_advance "☝ ⏵︎Update form", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:update_form], reader: :[]

    # test: ☝ ⏵︎Notify approver
    ctx = assert_advance "☝ ⏵︎Notify approver", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:notify_approver, :notify_approver, :approve], reader: :[]

    # test: ☝ ⏵︎Update
    ctx = assert_advance "☝ ⏵︎Update", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:ui_update, :update], reader: :[]

    # test: ☝ ⏵︎Notify approver ⛞
    ctx = assert_advance "☝ ⏵︎Notify approver ⛞", ctx: {decision: false, seq: []}, expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:notify_approver, :notify_approver, :reject], reader: :[]

    # test: ☝ ⏵︎Delete? form
    ctx = assert_advance "☝ ⏵︎Delete? form", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:delete_form], reader: :[]

    # test: ☝ ⏵︎Publish
    ctx = assert_advance "☝ ⏵︎Publish", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:publish, :publish], reader: :[]

    # test: ☝ ⏵︎Update ⛞
    ctx = assert_advance "☝ ⏵︎Update ⛞", ctx: {update: false, seq: []}, expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:ui_update, :update, :update_form_with_errors], reader: :[]

    # test: ☝ ⏵︎Revise form
    ctx = assert_advance "☝ ⏵︎Revise form", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:revise_form], reader: :[]

    # test: ☝ ⏵︎Delete
    ctx = assert_advance "☝ ⏵︎Delete", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:delete, :delete], reader: :[]

    # test: ☝ ⏵︎Cancel
    ctx = assert_advance "☝ ⏵︎Cancel", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:cancel], reader: :[]

    # test: ☝ ⏵︎Archive
    ctx = assert_advance "☝ ⏵︎Archive", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:archive, :archive], reader: :[]

    # test: ☝ ⏵︎Revise
    ctx = assert_advance "☝ ⏵︎Revise", expected_ctx: {}, test_plan: test_plan_structure, lanes_cfg: lanes_cfg, schema: schema, message_flow: message_flow
    assert_exposes ctx, seq: [:revise, :revise], reader: :[]

  end
end
