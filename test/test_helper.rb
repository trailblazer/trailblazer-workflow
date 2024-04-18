$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/workflow"

require "minitest/autorun"
require "trailblazer/activity/testing"
require "pp" # Object#pretty_inspect

class Minitest::Spec
  def assert_equal(expected, asserted, *args)
    super(asserted, expected, *args)
  end

  Posting = Struct.new(:id, :state, keyword_init: true) do
    def self.find_by(id:)
      new(id: id, state: "⏸︎ Update [000]")
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

    implementing_editor = Trailblazer::Activity::Testing.def_steps(:Notify, :Reject, :Approve)

    schema = Trailblazer::Workflow.Collaboration(
      json_file: "test/fixtures/v1/posting-v10.json",
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
        "reviewer"=> {
          label: "editor",
          icon: "☑",
          implementation: {
            "Notify" => implementing_editor.method(:Notify),
            "Reject" => implementing_editor.method(:Reject),
            "Approve" => implementing_editor.method(:Approve),
          }
        }
      }, # :lanes
      state_guards: state_guards(),
    )

    lanes_cfg    = schema.to_h[:lanes]

    return schema, lanes_cfg
  end
end

module DiscoveredStates
  def states
    states, stub_schema = Trailblazer::Workflow::Discovery.(
      json_filename: "test/fixtures/v1/posting-v10.json",
      start_lane: "<ui> author workflow",

      # TODO: allow translating the original "id" (?) to the stubbed.
      dsl_options_for_run_multiple_times: {
         # We're "clicking" the [Notify_approver] button again, this time to get rejected.
          # Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_notify_approver}").task => {ctx_merge: {
          #     decision: false, # TODO: this is how it should be.
          #     # :"approver:xxx" => Trailblazer::Activity::Left, # FIXME: {:decision} must be translated to {:"approver:xxx"}
          #   }, config_payload: {outcome: :failure}},

        # Click [UI Create] again, with invalid data.
        ["<ui> author workflow", "Create"] => {ctx_merge: {:"article moderation:Create" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
        # Click [UI Update] again, with invalid data.
        ["<ui> author workflow", "Update"] => {ctx_merge: {:"article moderation:Update" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
        ["<ui> author workflow", "Revise"] => {ctx_merge: {:"article moderation:Revise" => Trailblazer::Activity::Left}, config_payload: {outcome: :failure}},
      },

      # DISCUSS: compute this automatically/from diagram?
      lane_hints: {
        "<ui> author workflow"  => {label: "UI", icon: "☝"},
        "article moderation"    => {label: "lifecycle", icon: "⛾"},
        "reviewer"              => {label: "editor", icon: "☑"},
      }
    )

    return states, stub_schema, stub_schema.to_h[:lanes]
  end

  def state_guards
    state_guards_from_user = {state_guards: {
        "⏸︎ Archive [100]"                          => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Archive [100]" }},
        "⏸︎ Create [010]"                           => {guard: ->(ctx, model: nil, **) { model.nil? }},
        "⏸︎ Create form [000]"                      => {guard: ->(ctx, model: nil, **) { model.nil? }},
        "⏸︎ Approve♦Reject [000]"                   => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Approve♦Reject [000]" }},
        "⏸︎ Delete♦Cancel [110]"                    => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Delete♦Cancel [110]" }},
        "⏸︎ Revise [010]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise [010]" }},
        "⏸︎ Revise form [000]"                      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise form [000]" }},
        "⏸︎ Revise form♦Notify approver [110]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise form♦Notify approver [110]" }},
        "⏸︎ Update [000]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update [000]" }},
        "⏸︎ Update form♦Delete? form♦Publish [110]" => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Delete? form♦Publish [110]" }},
        "⏸︎ Update form♦Notify approver [000]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [000]" }},
        "⏸︎ Update form♦Notify approver [110]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [110]" }},

    }}[:state_guards]

    # auto-generated. this structure could also hold alternative state names, etc.
    state_table = {
    "⏸︎ Approve♦Reject [000]"                   => {suspend_tuples: [["lifecycle", "suspend-Gateway_0y3f8tz"], ["UI", "suspend-Gateway_063k28q"], ["editor", "suspend-Gateway_02veylj"]], catch_tuples: [["editor", "catch-before-Activity_13fw5nm"], ["editor", "catch-before-Activity_1j7d8sd"]]},
    "⏸︎ Archive [100]"                          => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_1hgscu3"], ["UI", "suspend-gw-to-catch-before-Activity_0fy41qq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0fy41qq"]]},
    "⏸︎ Create [010]"                           => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-Gateway_14h0q7a"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1psp91r"]]},
    "⏸︎ Create form [000]"                      => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-gw-to-catch-before-Activity_0wc2mcq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0wc2mcq"]]},
    "⏸︎ Delete♦Cancel [110]"                    => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_100g9dn"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_15nnysv"], ["UI", "catch-before-Activity_1uhozy1"]]},
    "⏸︎ Revise [010]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-Gateway_1xs96ik"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1wiumzv"]]},
    "⏸︎ Revise form [000]"                      => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-gw-to-catch-before-Activity_0zsock2"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0zsock2"]]},
    "⏸︎ Revise form♦Notify approver [110]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_1kl7pnm"], ["UI", "suspend-Gateway_1xnsssa"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0zsock2"], ["UI", "catch-before-Activity_1dt5di5"]]},
    "⏸︎ Update [000]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0nxerxv"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0j78uzd"]]},
    "⏸︎ Update form♦Delete? form♦Publish [110]" => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_1sq41iq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_0ha7224"], ["UI", "catch-before-Activity_0bsjggk"]]},
    "⏸︎ Update form♦Notify approver [000]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0kknfje"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
    "⏸︎ Update form♦Notify approver [110]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_1wzosup"], ["UI", "suspend-Gateway_1g3fhu2"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
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

    @fixtures = [iteration_set, lanes_cfg, schema]
  end
end
