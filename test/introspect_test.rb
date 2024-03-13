require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable" do
    iteration_set, lanes_cfg = fixtures()

    cli_state_table = Trailblazer::Workflow::Introspect::StateTable.(iteration_set, lanes_cfg: lanes_cfg)
    # puts cli_state_table
    assert_equal cli_state_table,
%(+---------------------------------+----------------------------------------+
| state name                      | triggerable events                     |
+---------------------------------+----------------------------------------+
| "⏸︎ Create form"                 | "☝ ⏵︎Create form"                       |
| "⏸︎ Create"                      | "☝ ⏵︎Create"                            |
| "⏸︎ Update form♦Notify approver" | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver" |
| "⏸︎ Update"                      | "☝ ⏵︎Update"                            |
| "⏸︎ Delete? form♦Publish"        | "☝ ⏵︎Delete? form", "☝ ⏵︎Publish"        |
| "⏸︎ Revise form"                 | "☝ ⏵︎Revise form"                       |
| "⏸︎ Delete♦Cancel"               | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"               |
| "⏸︎ Archive"                     | "☝ ⏵︎Archive"                           |
| "⏸︎ Revise"                      | "☝ ⏵︎Revise"                            |
+---------------------------------+----------------------------------------+)
  end
end
