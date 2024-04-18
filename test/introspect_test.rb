require "test_helper"

class IntrospectStateTableTest < Minitest::Spec
  it "StateTable.call produces {:rows}" do
    iteration_set, lanes_cfg = fixtures()

    signal, (ctx, _) = Trailblazer::Workflow::Introspect::StateTable.invoke([{iteration_set: iteration_set, lanes_cfg: lanes_cfg}, {}])

    assert_equal ctx[:rows].collect { |row| row["state name"] }.inspect,
      %([\"⏸︎ Approve♦Reject [000]\", \"⏸︎ Archive [100]\", \"⏸︎ Create [010]\", \"⏸︎ Create form [000]\", \"⏸︎ Delete♦Cancel [110]\", \"⏸︎ Revise [010]\", \"⏸︎ Revise form [000]\", \"⏸︎ Revise form♦Notify approver [110]\", \"⏸︎ Update [000]\", \"⏸︎ Update form♦Delete? form♦Publish [110]\", \"⏸︎ Update form♦Notify approver [000]\", \"⏸︎ Update form♦Notify approver [110]\"])

    assert_equal ctx[:rows].collect { |row| row["Suspend IDs"] }, [
      "⛾ 0y3f ☝ 063k ☑ 02ve", "⛾ 1hgs ☝ 0fy4 ☑ 05zi", "⛾ 0wwf ☝ 14h0 ☑ 05zi", "⛾ 0wwf ☝ 0wc2 ☑ 05zi", "⛾ 1hp2 ☝ 100g ☑ 05zi", "⛾ 01p7 ☝ 1xs9 ☑ 05zi", "⛾ 01p7 ☝ 0zso ☑ 05zi", "⛾ 1kl7 ☝ 1xns ☑ 05zi", "⛾ 0fnb ☝ 0nxe ☑ 05zi", "⛾ 1hp2 ☝ 1sq4 ☑ 05zi", "⛾ 0fnb ☝ 0kkn ☑ 05zi", "⛾ 1wzo ☝ 1g3f ☑ 05zi"
    ]

    # required in {StateTable::Generate}
    assert_equal ctx[:rows].collect { |row| row[:suspend_tuples] }, [
[["lifecycle", "suspend-Gateway_0y3f8tz"], ["UI", "suspend-Gateway_063k28q"], ["editor", "suspend-Gateway_02veylj"]], [["lifecycle", "suspend-gw-to-catch-before-Activity_1hgscu3"], ["UI", "suspend-gw-to-catch-before-Activity_0fy41qq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-Gateway_14h0q7a"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-gw-to-catch-before-Activity_0wwfenp"], ["UI", "suspend-gw-to-catch-before-Activity_0wc2mcq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_100g9dn"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-Gateway_1xs96ik"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_01p7uj7"], ["UI", "suspend-gw-to-catch-before-Activity_0zsock2"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_1kl7pnm"], ["UI", "suspend-Gateway_1xnsssa"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0nxerxv"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_1hp2ssj"], ["UI", "suspend-Gateway_1sq41iq"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_0fnbg3r"], ["UI", "suspend-Gateway_0kknfje"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]], [["lifecycle", "suspend-Gateway_1wzosup"], ["UI", "suspend-Gateway_1g3fhu2"], ["editor", "suspend-gw-to-catch-before-Activity_05zip3u"]]
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
| "⏸︎ Approve♦Reject [000]"                   | "☑ ⏵︎Approve", "☑ ⏵︎Reject"                         | ⛾ 0y3f ☝ 063k ☑ 02ve |
| "⏸︎ Archive [100]"                          | "☝ ⏵︎Archive"                                      | ⛾ 1hgs ☝ 0fy4 ☑ 05zi |
| "⏸︎ Create [010]"                           | "☝ ⏵︎Create"                                       | ⛾ 0wwf ☝ 14h0 ☑ 05zi |
| "⏸︎ Create form [000]"                      | "☝ ⏵︎Create form"                                  | ⛾ 0wwf ☝ 0wc2 ☑ 05zi |
| "⏸︎ Delete♦Cancel [110]"                    | "☝ ⏵︎Delete", "☝ ⏵︎Cancel"                          | ⛾ 1hp2 ☝ 100g ☑ 05zi |
| "⏸︎ Revise [010]"                           | "☝ ⏵︎Revise"                                       | ⛾ 01p7 ☝ 1xs9 ☑ 05zi |
| "⏸︎ Revise form [000]"                      | "☝ ⏵︎Revise form"                                  | ⛾ 01p7 ☝ 0zso ☑ 05zi |
| "⏸︎ Revise form♦Notify approver [110]"      | "☝ ⏵︎Revise form", "☝ ⏵︎Notify approver"            | ⛾ 1kl7 ☝ 1xns ☑ 05zi |
| "⏸︎ Update [000]"                           | "☝ ⏵︎Update"                                       | ⛾ 0fnb ☝ 0nxe ☑ 05zi |
| "⏸︎ Update form♦Delete? form♦Publish [110]" | "☝ ⏵︎Update form", "☝ ⏵︎Delete? form", "☝ ⏵︎Publish" | ⛾ 1hp2 ☝ 1sq4 ☑ 05zi |
| "⏸︎ Update form♦Notify approver [000]"      | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            | ⛾ 0fnb ☝ 0kkn ☑ 05zi |
| "⏸︎ Update form♦Notify approver [110]"      | "☝ ⏵︎Update form", "☝ ⏵︎Notify approver"            | ⛾ 1wzo ☝ 1g3f ☑ 05zi |
+--------------------------------------------+---------------------------------------------------+----------------------+)
  end
end
