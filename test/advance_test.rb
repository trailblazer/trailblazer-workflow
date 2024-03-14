require "test_helper"

# high-level unit test that shows the user's interface.
class AdvanceTest < Minitest::Spec
  include BuildSchema
  include DiscoveredStates

  it "what" do
    # TODO: this is something that shouldn't be done every time.
    states, schema, lanes_cfg, message_flow = states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)
    # Serialize/deserialize the Set, as this will always be the case in a real environment.
    serialized_iteration_set = JSON.dump(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(serialized_iteration_set), lanes_cfg: lanes_cfg)

    state_guards_from_user = {state_guards: {
  "⏸︎ Create form                " => {guard: ->(ctx, process_model:, **) { true }, id: ["catch-before-Activity_0wc2mcq"]},
  "⏸︎ Create                     " => {guard: ->(ctx, process_model:, **) { true }, id: ["catch-before-Activity_1psp91r"]},
  "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"]},
  "⏸︎ Update                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0j78uzd"]},
  "⏸︎ Delete? form♦Publish       " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0bsjggk", "catch-before-Activity_0ha7224"]},
  "⏸︎ Revise form                " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0zsock2"]},
  "⏸︎ Delete♦Cancel              " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_15nnysv", "catch-before-Activity_1uhozy1"]},
  "⏸︎ Archive                    " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0fy41qq"]},
  "⏸︎ Revise                     " => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1wiumzv"]},
}}[:state_guards]

    # auto-generated. this structure could also hold alternative state names, etc.
    state_table = {
  "⏸︎ Create form                " => {id: ["catch-before-Activity_0wc2mcq"]},
  "⏸︎ Create                     " => {id: ["catch-before-Activity_1psp91r"]},
  "⏸︎ Update form♦Notify approver" => {id: ["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"]},
  "⏸︎ Update                     " => {id: ["catch-before-Activity_0j78uzd"]},
  "⏸︎ Delete? form♦Publish       " => {id: ["catch-before-Activity_0bsjggk", "catch-before-Activity_0ha7224"]},
  "⏸︎ Revise form                " => {id: ["catch-before-Activity_0zsock2"]},
  "⏸︎ Delete♦Cancel              " => {id: ["catch-before-Activity_15nnysv", "catch-before-Activity_1uhozy1"]},
  "⏸︎ Archive                    " => {id: ["catch-before-Activity_0fy41qq"]},
  "⏸︎ Revise                     " => {id: ["catch-before-Activity_1wiumzv"]},
    }

    state_guards = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash( # TODO: unify naming, DSL.state_guards_from_user or something like that.
      state_guards_from_user,
      # iteration_set: iteration_set,
      state_table: state_table,
    )






    ctx = {params: [], seq: [], process_model: nil}

    # TODO: this should be suitable to be dropped into an endpoint.
    signal, (ctx, flow_options), configuration = Trailblazer::Workflow::Advance.(
      ctx,
      **schema.to_h,
      event_label: "☝ ⏵︎Create",
      # lanes_cfg: lanes_cfg, # TODO: make this part of {schema}.

      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: state_guards,
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Right)
    assert_equal configuration.class, Trailblazer::Workflow::Collaboration::Configuration # FIXME: better test.

    #@ update invalid
    signal, (ctx, flow_options) = Trailblazer::Workflow::Advance.(
      {create: false, seq: [], process_model: nil},
      **schema.to_h,
      event_label: "☝ ⏵︎Create",
      iteration_set: iteration_set, # this is basically the "dictionary" for lookups of positions.
      state_guards: state_guards,
    )

    assert_equal signal.inspect, %(Trailblazer::Activity::Left)
  end
end
