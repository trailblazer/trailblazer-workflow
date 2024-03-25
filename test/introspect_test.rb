require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable.call produces {:rows}" do
    iteration_set, lanes_cfg = fixtures()

    signal, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])

    assert_equal ctx[:rows].collect { |row| row["state name"] }.inspect,
      %(["⏸︎ Archive", "⏸︎ Create", "⏸︎ Create form", "⏸︎ Delete♦Cancel", "⏸︎ Revise", "⏸︎ Revise form", "⏸︎ Revise form♦Notify approver", "⏸︎ Update", "⏸︎ Update form♦Delete? form♦Publish", "⏸︎ Update form♦Notify approver", "⏸︎ Update form♦Notify approver (_1g3fhu2)"])
  end

  it "StateTable.render" do
    iteration_set, lanes_cfg = fixtures()

    _, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable::Render.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])
    puts ctx[:table]
    assert_equal ctx[:table],
%(+--------------------------------------------+---------------------------------------------------+
| state name                                 | triggerable events                                |
+--------------------------------------------+---------------------------------------------------+
| "⏸︎ Archive"                                | "☝ ⏵︎Archive"                                      |
| "⏸︎ Create"                                 | "☝ ⏵︎Create"                                       |
| "⏸︎ Create form"                            | "☝ ⏵︎Create form"                                  |
| "⏸︎ Delete♦Cancel"                          | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"                          |
| "⏸︎ Revise"                                 | "☝ ⏵︎Revise"                                       |
| "⏸︎ Revise form"                            | "☝ ⏵︎Revise form"                                  |
| "⏸︎ Revise form♦Notify approver"            | "☝ ⏵︎Revise form", "☝ ⏵︎Notify approver"            |
| "⏸︎ Update"                                 | "☝ ⏵︎Update"                                       |
| "⏸︎ Update form♦Delete? form♦Publish"       | "☝ ⏵︎Update form", "☝ ⏵︎Delete? form", "☝ ⏵︎Publish" |
| "⏸︎ Update form♦Notify approver"            | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            |
| "⏸︎ Update form♦Notify approver (_1g3fhu2)" | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            |
+--------------------------------------------+---------------------------------------------------+)
  end
end
