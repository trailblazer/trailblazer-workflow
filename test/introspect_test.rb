require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable.call produces {:rows}" do
    iteration_set, lanes_cfg = fixtures()

    signal, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])

    assert_equal ctx[:rows].collect { |row| row["state name"] }.inspect,
      %(["⏸︎ Archive [10u]", "⏸︎ Create [01u]", "⏸︎ Create form [00u]", "⏸︎ Delete♦Cancel [11u]", "⏸︎ Revise [01u]", "⏸︎ Revise form [00u]", "⏸︎ Revise form♦Notify approver [10u]", "⏸︎ Update [00u]", "⏸︎ Update form♦Delete? form♦Publish [11u]", "⏸︎ Update form♦Notify approver [00u]", "⏸︎ Update form♦Notify approver [11u]"])

    assert_equal ctx[:rows].collect { |row| row["Suspend IDs"] }, [
      "⛾ 1hgs ☝ 0fy4 ☑ uspe", "⛾ 0wwf ☝ 14h0 ☑ uspe", "⛾ 0wwf ☝ 0wc2 ☑ uspe", "⛾ 1hp2 ☝ 100g ☑ uspe", "⛾ 01p7 ☝ 1xs9 ☑ uspe", "⛾ 01p7 ☝ 0zso ☑ uspe", "⛾ 1kl7 ☝ 00n4 ☑ uspe", "⛾ 0fnb ☝ 0nxe ☑ uspe", "⛾ 1hp2 ☝ 1sq4 ☑ uspe", "⛾ 0fnb ☝ 0kkn ☑ uspe", "⛾ 1wzo ☝ 1g3f ☑ uspe"
    ]

    # required in {StateTable::Generate}
    assert_equal ctx[:rows].collect { |row| row[:suspend_tuples] }, [
[["lifecycle", "suspend-gw-to-catch-before-Activity_1hgscu3"], ["UI", "suspend-gw-to-catch-before-Activity_0fy41qq"], ["approver", "~suspend~"]], [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-Gateway_14h0q7a"], ["approver", "~suspend~"]], [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-gw-to-catch-before-Activity_0wc2mcq"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_100g9dn"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-Gateway_1xs96ik"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-gw-to-catch-before-Activity_0zsock2"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_1kl7pnm"], ["UI", "suspend-Gateway_00n4dsm"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0nxerxv"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_1sq41iq"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0kknfje"], ["approver", "~suspend~"]], [["lifecycle", "suspend-Gateway_1wzosup"], ["UI", "suspend-Gateway_1g3fhu2"], ["approver", "~suspend~"]]
    ]
  end

  it "StateTable.render" do
    iteration_set, lanes_cfg = fixtures()

    _, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable::Render.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])
    # puts ctx[:table]
    assert_equal ctx[:table],
%(+--------------------------------------------+---------------------------------------------------+----------------------+
| state name                                 | triggerable events                                | Suspend IDs          |
+--------------------------------------------+---------------------------------------------------+----------------------+
| "⏸︎ Archive [10u]"                          | "☝ ⏵︎Archive"                                      | ⛾ 1hgs ☝ 0fy4 ☑ uspe |
| "⏸︎ Create [01u]"                           | "☝ ⏵︎Create"                                       | ⛾ 0wwf ☝ 14h0 ☑ uspe |
| "⏸︎ Create form [00u]"                      | "☝ ⏵︎Create form"                                  | ⛾ 0wwf ☝ 0wc2 ☑ uspe |
| "⏸︎ Delete♦Cancel [11u]"                    | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"                          | ⛾ 1hp2 ☝ 100g ☑ uspe |
| "⏸︎ Revise [01u]"                           | "☝ ⏵︎Revise"                                       | ⛾ 01p7 ☝ 1xs9 ☑ uspe |
| "⏸︎ Revise form [00u]"                      | "☝ ⏵︎Revise form"                                  | ⛾ 01p7 ☝ 0zso ☑ uspe |
| "⏸︎ Revise form♦Notify approver [10u]"      | "☝ ⏵︎Revise form", "☝ ⏵︎Notify approver"            | ⛾ 1kl7 ☝ 00n4 ☑ uspe |
| "⏸︎ Update [00u]"                           | "☝ ⏵︎Update"                                       | ⛾ 0fnb ☝ 0nxe ☑ uspe |
| "⏸︎ Update form♦Delete? form♦Publish [11u]" | "☝ ⏵︎Update form", "☝ ⏵︎Delete? form", "☝ ⏵︎Publish" | ⛾ 1hp2 ☝ 1sq4 ☑ uspe |
| "⏸︎ Update form♦Notify approver [00u]"      | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            | ⛾ 0fnb ☝ 0kkn ☑ uspe |
| "⏸︎ Update form♦Notify approver [11u]"      | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            | ⛾ 1wzo ☝ 1g3f ☑ uspe |
+--------------------------------------------+---------------------------------------------------+----------------------+)
  end
end
