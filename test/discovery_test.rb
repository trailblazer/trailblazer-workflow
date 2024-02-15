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


    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)


    states, additional_state_data = Trailblazer::Workflow::Discovery.(
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

    pp states

    raise
  end
end
