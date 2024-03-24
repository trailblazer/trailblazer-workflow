require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable.call produces {:rows}" do
    iteration_set, lanes_cfg = fixtures()

    signal, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])

    assert_equal ctx[:rows].collect { |row| row["state name"] }.inspect,
      %(["⏸︎ Archive", "⏸︎ Create", "⏸︎ Create form", "⏸︎ Delete? form♦Publish", "⏸︎ Delete♦Cancel", "⏸︎ Revise", "⏸︎ Revise form", "⏸︎ Update", "⏸︎ Update form♦Notify approver"])
  end

  it "StateTable.render" do
    iteration_set, lanes_cfg = fixtures()

    _, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable::Render.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])
    # puts ctx[:table]
    assert_equal ctx[:table],
%(+---------------------------------+----------------------------------------+
| state name                      | triggerable events                     |
+---------------------------------+----------------------------------------+
| "⏸︎ Archive"                     | "☝ ⏵︎Archive"                           |
| "⏸︎ Create"                      | "☝ ⏵︎Create"                            |
| "⏸︎ Create form"                 | "☝ ⏵︎Create form"                       |
| "⏸︎ Delete? form♦Publish"        | "☝ ⏵︎Delete? form", "☝ ⏵︎Publish"        |
| "⏸︎ Delete♦Cancel"               | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"               |
| "⏸︎ Revise"                      | "☝ ⏵︎Revise"                            |
| "⏸︎ Revise form"                 | "☝ ⏵︎Revise form"                       |
| "⏸︎ Update"                      | "☝ ⏵︎Update"                            |
| "⏸︎ Update form♦Notify approver" | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver" |
+---------------------------------+----------------------------------------+)
  end
end
