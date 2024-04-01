$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/workflow"

require "minitest/autorun"
require "pp"
require "trailblazer/activity/testing"

class Minitest::Spec
  def assert_equal(expected, asserted, *args)
    super(asserted, expected, *args)
  end

  Posting = Struct.new(:id, :state, keyword_init: true) do
    def self.find_by(id:)
      new(id: id, state: "⏸︎ Update [00u]")
    end
  end
end

module BuildSchema
  class Create < Trailblazer::Activity::Railway
    step :create
    include Trailblazer::Activity::Testing.def_steps(:create)
  end

  # NOTE: this uses https://bpmn.trailblazer.to/9a6b39 "Workflow in moderation"
  #
  # Updating diagram:
  #   rails g trailblazer:pro:import 9a6b39 ../trailblazer-workflow/test/fixtures/v1/moderation.json
  def build_schema()
    implementing = Trailblazer::Activity::Testing.def_steps(:create, :update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete)

    implementing_ui = Trailblazer::Activity::Testing.def_steps(:create_form, :ui_create, :update_form, :ui_update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete, :delete_form, :cancel, :revise_form,
      :create_form_with_errors, :update_form_with_errors, :revise_form_with_errors)

    schema = Trailblazer::Workflow.Collaboration(
      json_file: "test/fixtures/v1/moderation.json",
      lanes: {
        "article moderation"    => {
          label: "lifecycle",
          icon:  "⛾",
          implementation: {
            "Create" => Trailblazer::Activity::Railway.Subprocess(Create),
            "Update" => implementing.method(:update),
            "Approve" => implementing.method(:approve),
            "Notify approver" => implementing.method(:notify_approver),
            "Revise" => implementing.method(:revise),
            "Reject" => implementing.method(:reject),
            "Publish" => implementing.method(:publish),
            "Archive" => implementing.method(:archive),
            "Delete" => implementing.method(:delete),
          }
        },
        "<ui> author workflow"  => {
          label: "UI",
          icon:  "☝",
          implementation: {
            "Create form" => implementing_ui.method(:create_form),
            "Create" => implementing_ui.method(:ui_create),
            "Update form" => implementing_ui.method(:update_form),
            "Update" => implementing_ui.method(:ui_update),
            "Notify approver" => implementing_ui.method(:notify_approver),
            "Publish" => implementing_ui.method(:publish),
            "Delete" => implementing_ui.method(:delete),
            "Delete? form" => implementing_ui.method(:delete_form),
            "Cancel" => implementing_ui.method(:cancel),
            "Revise" => implementing_ui.method(:revise),
            "Revise form" => implementing_ui.method(:revise_form),
            "Create form with errors" => implementing_ui.method(:create_form_with_errors),
            "Update form with errors" => implementing_ui.method(:update_form_with_errors),
            "Revise form with errors" => implementing_ui.method(:revise_form_with_errors),
            "Archive" => implementing_ui.method(:archive),

          }
        },
      }
    )

    lanes_cfg    = schema.to_h[:lanes]
    message_flow = schema.to_h[:message_flow]

    # It's possible to extend a collaboration manually.
    # DISCUSS: make this an officially documented/tested interface?
    approver_activity, extended_message_flow, extended_initial_lane_positions = build_custom_editor_lane(lanes_cfg, message_flow)

    lanes_cfg = lanes_cfg = Trailblazer::Workflow::Introspect::Lanes.new(
      lanes_cfg.to_h.collect { |_, cfg| [cfg[:json_id], cfg] }.to_h.merge(
        "approver" => {
          label: "approver",
          icon: "☑",
          activity: approver_activity
        }
      )
    )

    schema = Trailblazer::Workflow::Collaboration::Schema.new(
      lanes: lanes_cfg,
      message_flow: message_flow,
    )

    return schema, lanes_cfg, extended_message_flow, extended_initial_lane_positions
  end

  # DISCUSS: this is mostly to play around with the "API" of building a Collaboration.
  def build_custom_editor_lane(lanes, message_flow)
    approve_id = "Activity_1qrkaz0"
    reject_id = "Activity_0d9yewp"

    lifecycle_activity = lanes.(label: "lifecycle")[:activity]

    missing_throw_from_notify_approver = Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "throw-after-Activity_0wr78cv").task

    decision_is_approve_throw = nil
    decision_is_reject_throw  = nil

    approver_start_suspend = nil
    approver_activity = Class.new(Trailblazer::Activity::Railway) do
      terminus task: approver_start_suspend = Trailblazer::Workflow::Event::Suspend.new(semantic: "invented_semantic", "resumes" => ["catch-before-decider-xxx"]), id: "~suspend~"

      fail task: Trailblazer::Workflow::Event::Catch.new(semantic: "xxx --> decider"), id: "catch-before-decider-xxx", Output(:success) => Track(:failure)
      fail :decider, id: "xxx",
        Output(:failure) => Trailblazer::Activity::Railway.Id("xxx_reject")
      fail task: decision_is_approve_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_approve"), Output(:success) => Id("~suspend~")

      step task: decision_is_reject_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_reject"),
        magnetic_to: :reject, id: "xxx_reject", Output(:success) => Id("~suspend~")

      def decider(ctx, decision: true, **)
        # raise if !decision

        decision
      end
    end

    extended_message_flow = message_flow.merge(
      # "throw-after-Activity_0wr78cv"
      missing_throw_from_notify_approver => [approver_activity, Trailblazer::Activity::Introspect.Nodes(approver_activity, id: "catch-before-decider-xxx").task],
      decision_is_approve_throw => [lifecycle_activity, Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "catch-before-#{approve_id}").task],
      decision_is_reject_throw => [lifecycle_activity, Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "catch-before-#{reject_id}").task],
    )

    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(lanes) # we need to do this manually here, as initial_lane_positions isn't part of the {Schema.build} process.
    extended_initial_lane_positions = initial_lane_positions.merge(
      approver_activity => approver_start_suspend
    )
    extended_initial_lane_positions = Trailblazer::Workflow::Collaboration::Positions.new(extended_initial_lane_positions.collect { |activity, task| Trailblazer::Workflow::Collaboration::Position.new(activity, task) })

    return approver_activity, extended_message_flow, extended_initial_lane_positions
  end
end

module DiscoveredStates
  def states
    ui_create_form = "Activity_0wc2mcq" # TODO: this is from pro-rails tests.
    ui_create = "Activity_1psp91r"
    ui_update = "Activity_0j78uzd"
    ui_notify_approver = "Activity_1dt5di5"

    # TODO: either {lanes} or {lanes_cfg}.
    schema, lanes_cfg, message_flow, initial_lane_positions = build_schema()

    lane_activity_ui = lanes_cfg.(label: "UI")[:activity]


    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_task_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)


    states = Trailblazer::Workflow::Discovery.(
      schema,
      initial_lane_positions: initial_lane_positions,
      start_task_position: start_task_position,
      message_flow: message_flow,

      # TODO: allow translating the original "id" (?) to the stubbed.
      run_multiple_times: {
         # We're "clicking" the [Notify_approver] button again, this time to get rejected.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_notify_approver}").task => {ctx_merge: {
              # decision: false, # TODO: this is how it should be.
              :"approver:xxx" => Trailblazer::Activity::Left, # FIXME: {:decision} must be translated to {:"approver:xxx"}
            }, config_payload: {outcome: :failure}},

        **Trailblazer::Workflow::Discovery::DSL.configuration_for_branching_from_user_hash(
          {
            # Click [UI Create] again, with invalid data.
            ["UI", "Create"] => {ctx_merge: {:"lifecycle:Create" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
            # Click [UI Update] again, with invalid data.
            ["UI", "Update"] => {ctx_merge: {:"lifecycle:Update" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
            ["UI", "Revise"] => {ctx_merge: {:"lifecycle:Revise" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
          },
          **schema.to_h
        )
      }
    )

    return states, schema, lanes_cfg, message_flow
  end

  def state_guards
    state_guards_from_user = {state_guards: {
        "⏸︎ Archive [10u]"                          => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Archive [10u]" }},
        "⏸︎ Create [01u]"                           => {guard: ->(ctx, model: nil, **) { model.nil? }},
        "⏸︎ Create form [00u]"                      => {guard: ->(ctx, model: nil, **) { model.nil? }},
        "⏸︎ Delete♦Cancel [11u]"                    => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Delete♦Cancel [11u]" }},
        "⏸︎ Revise [01u]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise [01u]" }},
        "⏸︎ Revise form [00u]"                      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise form [00u]" }},
        "⏸︎ Revise form♦Notify approver [10u]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise form♦Notify approver [10u]" }},
        "⏸︎ Update [00u]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update [00u]" }},
        "⏸︎ Update form♦Delete? form♦Publish [11u]" => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Delete? form♦Publish [11u]" }},
        "⏸︎ Update form♦Notify approver [00u]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [00u]" }},
        "⏸︎ Update form♦Notify approver [11u]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [11u]" }},
    }}[:state_guards]

    # auto-generated. this structure could also hold alternative state names, etc.
    state_table = {
    "⏸︎ Archive [10u]"                          => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_1hgscu3"], ["UI", "suspend-gw-to-catch-before-Activity_0fy41qq"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_0fy41qq"]]},
    "⏸︎ Create [01u]"                           => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-Gateway_14h0q7a"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_1psp91r"]]},
    "⏸︎ Create form [00u]"                      => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-gw-to-catch-before-Activity_0wc2mcq"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_0wc2mcq"]]},
    "⏸︎ Delete♦Cancel [11u]"                    => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_100g9dn"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_15nnysv"], ["UI", "catch-before-Activity_1uhozy1"]]},
    "⏸︎ Revise [01u]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-Gateway_1xs96ik"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_1wiumzv"]]},
    "⏸︎ Revise form [00u]"                      => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-gw-to-catch-before-Activity_0zsock2"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_0zsock2"]]},
    "⏸︎ Revise form♦Notify approver [10u]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_1kl7pnm"], ["UI", "suspend-Gateway_00n4dsm"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_0zsock2"], ["UI", "catch-before-Activity_1dt5di5"]]},
    "⏸︎ Update [00u]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0nxerxv"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_0j78uzd"]]},
    "⏸︎ Update form♦Delete? form♦Publish [11u]" => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_1sq41iq"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_0ha7224"], ["UI", "catch-before-Activity_0bsjggk"]]},
    "⏸︎ Update form♦Notify approver [00u]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0kknfje"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
    "⏸︎ Update form♦Notify approver [11u]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_1wzosup"], ["UI", "suspend-Gateway_1g3fhu2"], ["approver", "~suspend~"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
    }

    state_guards = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash( # TODO: unify naming, DSL.state_guards_from_user or something like that.
      state_guards_from_user,
      # iteration_set: iteration_set,
      state_table: state_table,
    )
  end
end

Minitest::Spec.class_eval do
  include BuildSchema
  include DiscoveredStates

  def fixtures
    return @fixtures if @fixtures

    states, lanes_sorted, lanes_cfg, schema, message_flow = states()
    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    @fixtures = [iteration_set, lanes_cfg]
  end
end
