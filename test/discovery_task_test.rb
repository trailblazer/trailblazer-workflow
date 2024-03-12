require "test_helper"

# TODO: test when {start_activity_json_id} is wrong

class DiscoveryTaskTest < Minitest::Spec
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

  it "Discovery task: discover, serialize, create test plan, create state table/state guards" do
    # states, schema, lanes_cfg = self.class.states
    schema = build_schema()

    Dir.chdir("test/tmp") do
      Trailblazer::Workflow::Task::Discover.(
        schema: schema,
        namespace: "Posting::Collaboration",
        target_dir: "app/concepts/posting/collaboration",
        start_activity_json_id: "<ui> author workflow",
        # iteration_set_filename: "test/tmp/bla.json",
        test_filename: "test/bla_test.rb",
      )
    end

    #@ We serialized the discovered iterations, so we don't need to run discovery on every startup.
    assert_equal (serialized_iteration_set = File.read("test/tmp/bla.json")).size, 20925

# raise
#     iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)


    iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(serialized_iteration_set), lanes_cfg: schema.to_h[:lanes])

    # TODO: test {Set#to_a}
    assert_equal iteration_set_from_json.to_a.size, 14

    #@ Assert test plan

    #@ Assert {state_guards.rb}
    assert_equal File.read("test/tmp/state_guards.rb"),
%(App::Bla::StateGuards = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash({
  "⏸︎ Create form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0wc2mcq"]},
  "⏸︎ Create"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1psp91r"]},
  "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"]},
  "⏸︎ Update"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0j78uzd"]},
  "⏸︎ Approve♦Reject"              => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_13fw5nm", "catch-before-Activity_1j7d8sd"]},
  "⏸︎ Delete? form♦Publish"        => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0bsjggk", "catch-before-Activity_0ha7224"]},
  "⏸︎ Revise form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0zsock2"]},
  "⏸︎ Delete♦Cancel"               => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_15nnysv", "catch-before-Activity_1uhozy1"]},
  "⏸︎ Archive"                     => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0fy41qq"]},
  "⏸︎ Revise"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1wiumzv"]},
})
)

  end

  it "Test plan " do
    # schema = build_schema()

    # Trailblazer::Workflow::Task::Discover::RenderTestPlan.(iteration_set: "test/tmp/bla.json")

  end
end
