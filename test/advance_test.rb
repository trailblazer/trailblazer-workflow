require "test_helper"

# high-level unit test that shows the user's interface.
class AdvanceTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, lanes_sorted, lanes_cfg, schema, message_flow = states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)
    # "states"
    positions_to_iteration_table = Trailblazer::Workflow::Introspect::StateTable.aggregate_by_state(iteration_set)

    ctx = {params: [], seq: []}

    # TODO: this should be suitable to be dropped into an endpoint.
    signal, (ctx, flow_options) = Trailblazer::Workflow::Advance.(
      ctx,
      **schema.to_h,
      message_flow: message_flow,
      event_label: "☝ ⏵︎Update",
      # lanes_cfg: lanes_cfg, # TODO: make this part of {schema}.

      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: {}, # TODO: design/implement this.

      positions_to_iteration_table: positions_to_iteration_table,
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Right)

    #@ update invalid
    signal, (ctx, flow_options) = Trailblazer::Workflow::Advance.(
      {update: false, seq: []},
      **schema.to_h,
      message_flow: message_flow,
      event_label: "☝ ⏵︎Update",
      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: {}, # TODO: design/implement this.
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Left)
  end
end
