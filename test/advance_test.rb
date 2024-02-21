require "test_helper"

# high-level unit test that shows the user's interface.
class AdvanceTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    schema, lanes, message_flow, initial_lane_positions, lanes_cfg = build_schema()

    # TODO: this is something that shouldn't be done every time.
    states, lanes_sorted, lanes_cfg = states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)
    # "states"
    position_to_iterations_table = Trailblazer::Workflow::Introspect::StateTable.aggregate_by_state(iteration_set)

    ctx = {params: [], seq: []}

    # TODO: this should be suitable to be dropped into an endpoint.

    signal, (ctx, flow_options) = Trailblazer::Workflow::Advance.(
      schema,
      ctx,
      event_label: "☝ ⏵︎Update",
      lanes_cfg: lanes_cfg, # TODO: make this part of {schema}.

      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: {} # TODO: design/implement this.
    )
  end
end
