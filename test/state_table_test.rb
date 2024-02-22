require "test_helper"

class StateTableTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, lanes_sorted, lanes_cfg, schema, message_flow = states()
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    puts output = Trailblazer::Workflow::Introspect::StateTable::Generate.(iteration_set, lanes_cfg: lanes_cfg)

    # TODO: we could store the {:id} field in a serialized doc, and grab positions from iteration_set when deserializing.
    assert_equal output, %(
state_guards: {
  "⏸︎ Create form                " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_0wc2mcq"]
  "⏸︎ Create                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_1psp91r"]
  "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"]
  "⏸︎ Update                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_0j78uzd"]
  "⏸︎ Delete? form♦Publish       " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_0bsjggk", "catch-before-Activity_0ha7224"]
  "⏸︎ Revise form                " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_0zsock2"]
  "⏸︎ Delete♦Cancel              " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_15nnysv", "catch-before-Activity_1uhozy1"]
  "⏸︎ Archive                    " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_0fy41qq"]
  "⏸︎ Revise                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }}, id: ["catch-before-Activity_1wiumzv"]
}
)
  end
end
