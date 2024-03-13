require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable.call produces {:rows}" do
    iteration_set, lanes_cfg = fixtures()

    signal, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])

    assert_equal ctx[:rows].collect { |row| row["state name"] }.inspect,
      %(["⏸︎ Create form", "⏸︎ Create", "⏸︎ Update form♦Notify approver", "⏸︎ Update", "⏸︎ Delete? form♦Publish", "⏸︎ Revise form", "⏸︎ Delete♦Cancel", "⏸︎ Archive", "⏸︎ Revise"])
  end

  it "StateTable.render" do
    iteration_set, lanes_cfg = fixtures()

    _, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable::Render.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])
    # puts cli_state_table
    assert_equal ctx[:table],
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
