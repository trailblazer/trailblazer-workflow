require "test_helper"

class StateTableTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, lanes_sorted, lanes_cfg, schema, message_flow = states()
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    puts output = Trailblazer::Workflow::Introspect::StateTable::Generate.(iteration_set, lanes_cfg: lanes_cfg, namespace: "App::Posting")

    # TODO: we could store the {:id} field in a serialized doc, and grab positions from iteration_set when deserializing.

    assert_equal output, File.read("test/expected/posting.state_guards.rb")
  end
end
