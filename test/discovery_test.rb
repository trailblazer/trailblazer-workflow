require "test_helper"

class DiscoveryTest < Minitest::Spec
  include BuildSchema

  it "Discovery.call" do
    ui_create_form = "Activity_0wc2mcq" # TODO: this is from pro-rails tests.
    ui_create = "Activity_1psp91r"
    ui_update = "Activity_0j78uzd"
    ui_notify_approver = "Activity_1dt5di5"

    schema, lanes, message_flow, initial_lane_positions = build_schema()

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

  # Asserts
  #   * that positions are always sorted by activity.
  def assert_position_before(actual_positions, expected_ids, start_id:, lanes:)
    actual_lane_positions, actual_start_position = actual_positions

    assert_positions_for(actual_lane_positions, expected_ids, lanes: lanes)

    assert_equal Trailblazer::Activity::Introspect.Nodes(actual_start_position.activity, task: actual_start_position.task).id, start_id, "start task mismatch"
  end

  def assert_positions_for(actual_lane_positions, expected_ids, lanes:)
    # puts actual_lane_positions.collect { |(a, t)| Trailblazer::Activity::Introspect.Nodes(a, task: t).id }.inspect

    # FIXME: always use Positions -> Position
    actual_lane_positions.collect.with_index do |actual_position, index|
      raise actual_position.inspect if actual_position.class == Array # FIXME: remove me.
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
end
