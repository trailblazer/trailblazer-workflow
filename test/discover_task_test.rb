require "test_helper"

# TODO: test when {start_activity_json_id} is wrong

class DiscoverTaskTest < Minitest::Spec
  after { `rm -r test/tmp/app/concepts/posting/collaboration/generated` }
  after { `rm test/tmp/test/bla_test.rb` }

  def build_schema()
    implementing = Trailblazer::Activity::Testing.def_steps(:create, :update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete)

    implementing_ui = Trailblazer::Activity::Testing.def_steps(:create_form, :ui_create, :update_form, :ui_update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete, :delete_form, :cancel, :revise_form,
      :create_form_with_errors, :update_form_with_errors, :revise_form_with_errors, :Approve, :Notify, :Reject)

    schema = Trailblazer::Workflow.Collaboration(
      json_file: "test/fixtures/v1/posting-3-lanes.json",
      lanes: {
        "article moderation"    => {
          label: "lifecycle",
          icon:  "⛾",
          implementation: {
            "Create" => implementing.method(:create),
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
        "reviewer" => { # TODO: no warning about missing config, yet.
          label: "reviewer",
          icon: "☑",
          implementation: {
            "Approve" => implementing_ui.method(:Approve),
            "Notify" => implementing_ui.method(:Notify),
            "Reject" => implementing_ui.method(:Reject),
          }
        }
      }
    )
  end

  TEST_ROOT = "test/tmp"

  it "Discovery task: discover, serialize, create test plan, create state table/state guards" do
    # states, schema, lanes_cfg = self.class.states
    schema = build_schema()

    Dir.chdir(TEST_ROOT) do
      Trailblazer::Workflow::Task::Discover.(
        schema: schema,
        namespace: "Posting::Collaboration",
        target_dir: "app/concepts/posting/collaboration",
        start_activity_json_id: "<ui> author workflow",
        test_filename: "test/bla_test.rb",
      )
    end

    #@ We serialized the discovered iterations, so we don't need to run discovery on every startup.
    assert_equal (serialized_iteration_set = File.read("#{TEST_ROOT}/app/concepts/posting/collaboration/generated/iteration_set.json")).size, 28706

# raise
#     iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)


    iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(serialized_iteration_set), lanes_cfg: schema.to_h[:lanes])

    # TODO: test {Set#to_a}
    assert_equal iteration_set_from_json.to_a.size, 17

    #@ Assert test plan

    #@ Assert {state_guards.rb}
    assert_equal File.read("#{TEST_ROOT}/app/concepts/posting/collaboration/state_guards.rb"),
%(module Posting::Collaboration
  module StateGuards
    Decider = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash(
      {
        "⏸︎ Approve♦Reject [000]"                   => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Approve♦Reject [000]" }},
        "⏸︎ Archive [100]"                          => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Archive [100]" }},
        "⏸︎ Create [010]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Create [010]" }},
        "⏸︎ Create form [000]"                      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Create form [000]" }},
        "⏸︎ Delete♦Cancel [110]"                    => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Delete♦Cancel [110]" }},
        "⏸︎ Revise [010]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise [010]" }},
        "⏸︎ Revise form [000]"                      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Revise form [000]" }},
        "⏸︎ Update [000]"                           => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update [000]" }},
        "⏸︎ Update form♦Delete? form♦Publish [110]" => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Delete? form♦Publish [110]" }},
        "⏸︎ Update form♦Notify approver [000]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [000]" }},
        "⏸︎ Update form♦Notify approver [110]"      => {guard: ->(ctx, model:, **) { model.state == "⏸︎ Update form♦Notify approver [110]" }},
      },
      state_table: Generated::StateTable,
    )
  end
end
)

    assert_equal File.read("#{TEST_ROOT}/app/concepts/posting/collaboration/generated/state_table.rb"),
%(# This file is generated by trailblazer-workflow.
module Posting::Collaboration::Generated
  StateTable = {
    "⏸︎ Approve♦Reject [000]"                   => {suspend_tuples: [["lifecycle", "suspend-Gateway_0y3f8tz"], ["UI", "suspend-Gateway_063k28q"], ["reviewer", "suspend-Gateway_02veylj"]], catch_tuples: [["reviewer", "catch-before-Activity_13fw5nm"], ["reviewer", "catch-before-Activity_1j7d8sd"]]},
    "⏸︎ Archive [100]"                          => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_1hgscu3"], ["UI", "suspend-gw-to-catch-before-Activity_0fy41qq"], ["reviewer", "Event_0g5plbq"]], catch_tuples: [["UI", "catch-before-Activity_0fy41qq"]]},
    "⏸︎ Create [010]"                           => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-Gateway_14h0q7a"], ["reviewer", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1psp91r"]]},
    "⏸︎ Create form [000]"                      => {suspend_tuples: [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-gw-to-catch-before-Activity_0wc2mcq"], ["reviewer", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0wc2mcq"]]},
    "⏸︎ Delete♦Cancel [110]"                    => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_100g9dn"], ["reviewer", "Event_0g5plbq"]], catch_tuples: [["UI", "catch-before-Activity_15nnysv"], ["UI", "catch-before-Activity_1uhozy1"]]},
    "⏸︎ Revise [010]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-Gateway_1xs96ik"], ["reviewer", "Event_0g5plbq"]], catch_tuples: [["UI", "catch-before-Activity_1wiumzv"]]},
    "⏸︎ Revise form [000]"                      => {suspend_tuples: [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-gw-to-catch-before-Activity_0zsock2"], ["reviewer", "Event_0g5plbq"]], catch_tuples: [["UI", "catch-before-Activity_0zsock2"]]},
    "⏸︎ Update [000]"                           => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0nxerxv"], ["reviewer", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_0j78uzd"]]},
    "⏸︎ Update form♦Delete? form♦Publish [110]" => {suspend_tuples: [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_1sq41iq"], ["reviewer", "Event_0g5plbq"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_0ha7224"], ["UI", "catch-before-Activity_0bsjggk"]]},
    "⏸︎ Update form♦Notify approver [000]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0kknfje"], ["reviewer", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
    "⏸︎ Update form♦Notify approver [110]"      => {suspend_tuples: [["lifecycle", "suspend-Gateway_1wzosup"], ["UI", "suspend-Gateway_1g3fhu2"], ["reviewer", "suspend-gw-to-catch-before-Activity_05zip3u"]], catch_tuples: [["UI", "catch-before-Activity_1165bw9"], ["UI", "catch-before-Activity_1dt5di5"]]},
  }
end
)

  end

  it "Test plan " do
    # schema = build_schema()

    # Trailblazer::Workflow::Task::Discover::RenderTestPlan.(iteration_set: "test/tmp/bla.json")

  end
end
