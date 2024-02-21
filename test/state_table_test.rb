require "test_helper"

class StateTableTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, lanes_sorted, lanes_cfg, schema, message_flow = states()
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    puts output = Trailblazer::Workflow::Introspect::StateTable::Generate.(iteration_set, lanes_cfg: lanes_cfg)

    assert_equal output, %(
state_guards: {
  "⏸︎ Create form                " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Create                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Update                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Delete? form♦Publish       " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Revise form                " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Delete♦Cancel              " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Archive                    " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
  "⏸︎ Revise                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}
}
)
  end
end
