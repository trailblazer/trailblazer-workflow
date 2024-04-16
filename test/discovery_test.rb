require "test_helper"

class DiscoveryTest < Minitest::Spec
  extend BuildSchema
  extend DiscoveredStates

  def render_assert_data_for_iteration_set(states, lanes:, **)
    output = states.collect do |iteration|
      actual_lane_positions, actual_start_position = iteration[:positions_before]

      positions_before_readable = actual_lane_positions.collect { |(a, t)| Trailblazer::Workflow::Introspect::Present.readable_name_for_suspend_or_terminus(a, t, lanes_cfg: lanes) }
      positions_before = actual_lane_positions.collect { |(a, t)| Trailblazer::Activity::Introspect.Nodes(a, task: t).id }
      start_id = Trailblazer::Activity::Introspect.Nodes(actual_start_position.activity, task: actual_start_position.task).id
      start_id_readable = Trailblazer::Workflow::Introspect::Present.readable_name_for_catch_event(*actual_start_position.to_a, lanes_cfg: lanes)

      actual_lane_positions = iteration[:suspend_configuration].lane_positions

      positions_after = actual_lane_positions.collect { |(a, t)| Trailblazer::Activity::Introspect.Nodes(a, task: t).id }
      positions_after_readable = actual_lane_positions.collect { |(a, t)| Trailblazer::Workflow::Introspect::Present.readable_name_for_suspend_or_terminus(a, t, lanes_cfg: lanes) }

%(      [
        # before: #{positions_before_readable} start:#{start_id_readable}
        #{positions_before.inspect}, {start_id: #{start_id.inspect}},
        # after: #{positions_after_readable}
        #{positions_after.inspect},
      ],
)
    end.join("\n")
  end

  def stub_task(lane_label, task_label)
    stub_task_name = "#{lane_label}:#{task_label}".to_sym # name of the method.
    stub_task = Trailblazer::Activity::Testing.def_tasks(stub_task_name).method(stub_task_name)
  end

  it "Discovery.call" do
    states, schema = Trailblazer::Workflow::Discovery.(
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
      }
    )



    # pp states
    # TODO: should we really assert the state table manually?
    assert_equal states.size, 22

    # Uncomment next line to render the test below! Hahaha
    puts render_assert_data_for_iteration_set(states, **schema.to_h)
    assert_data_for_iteration_set = [
      [
        # before: ["⛾ ⏵︎Create", "☝ ⏵︎Create form", "☑ ⏵︎xxx"] start:☝ ⏵︎Create form
        ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-gw-to-catch-before-Activity_0wc2mcq", "~suspend~"], {start_id: "catch-before-Activity_0wc2mcq"},
        # after: ["⛾ ⏵︎Create", "☝ ⏵︎Create", "☑ ⏵︎xxx"]
        ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Create", "☝ ⏵︎Create", "☑ ⏵︎xxx"] start:☝ ⏵︎Create
        ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"], {start_id: "catch-before-Activity_1psp91r"},
        # after: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"]
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Create", "☝ ⏵︎Create", "☑ ⏵︎xxx"] start:☝ ⏵︎Create
        ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"], {start_id: "catch-before-Activity_1psp91r"},
        # after: ["⛾ ⏵︎Create", "☝ ⏵︎Create", "☑ ⏵︎xxx"]
        ["suspend-gw-to-catch-before-Activity_0wwfenp", "suspend-Gateway_14h0q7a", "~suspend~"],
      ],
      [
        # before: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update", "☑ ⏵︎xxx"] start:☝ ⏵︎Update
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"], {start_id: "catch-before-Activity_0j78uzd"},
        # after: ["⛾ ⏵︎Notify approver ⏵︎Update", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1wzosup", "suspend-Gateway_1g3fhu2", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Notify approver
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"], {start_id: "catch-before-Activity_1dt5di5"},
        # after: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise form", "☑ ⏵︎xxx"]
        ["suspend-Gateway_01p7uj7", "suspend-gw-to-catch-before-Activity_0zsock2", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Notify approver
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"], {start_id: "catch-before-Activity_1dt5di5"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Update form
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0kknfje", "~suspend~"], {start_id: "catch-before-Activity_1165bw9"},
        # after: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update", "☑ ⏵︎xxx"]
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      ],


      [
        # before: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"] start:☝ ⏵︎Update form
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"], {start_id: "catch-before-Activity_1165bw9"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_0nxerxv", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"] start:☝ ⏵︎Delete? form
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"], {start_id: "catch-before-Activity_0ha7224"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Delete ⏵︎Cancel", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"] start:☝ ⏵︎Publish
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"], {start_id: "catch-before-Activity_0bsjggk"},
        # after: ["⛾ ⏵︎Archive", "☝ ⏵︎Archive", "☑ ⏵︎xxx"]
        ["suspend-gw-to-catch-before-Activity_1hgscu3", "suspend-gw-to-catch-before-Activity_0fy41qq", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update", "☑ ⏵︎xxx"] start:☝ ⏵︎Update
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"], {start_id: "catch-before-Activity_0j78uzd"},
        # after: ["⛾ ⏵︎Update ⏵︎Notify approver", "☝ ⏵︎Update", "☑ ⏵︎xxx"]
        ["suspend-Gateway_0fnbg3r", "suspend-Gateway_0nxerxv", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Notify approver ⏵︎Update", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Update form
        ["suspend-Gateway_1wzosup", "suspend-Gateway_1g3fhu2", "~suspend~"], {start_id: "catch-before-Activity_1165bw9"},
        # after: ["⛾ ⏵︎Notify approver ⏵︎Update", "☝ ⏵︎Update", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1wzosup", "suspend-Gateway_0nxerxv", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Notify approver ⏵︎Update", "☝ ⏵︎Update form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Notify approver
        ["suspend-Gateway_1wzosup", "suspend-Gateway_1g3fhu2", "~suspend~"], {start_id: "catch-before-Activity_1dt5di5"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise form", "☑ ⏵︎xxx"] start:☝ ⏵︎Revise form
        ["suspend-Gateway_01p7uj7", "suspend-gw-to-catch-before-Activity_0zsock2", "~suspend~"], {start_id: "catch-before-Activity_0zsock2"},
        # after: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise", "☑ ⏵︎xxx"]
        ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Delete ⏵︎Cancel", "☑ ⏵︎xxx"] start:☝ ⏵︎Delete
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "~suspend~"], {start_id: "catch-before-Activity_15nnysv"},
        # after: ["⛾ ◉End.success", "☝ ◉End.success", "☑ ⏵︎xxx"]
        ["Event_1p8873y", "Event_0h6yhq6", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Delete ⏵︎Cancel", "☑ ⏵︎xxx"] start:☝ ⏵︎Cancel
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_100g9dn", "~suspend~"], {start_id: "catch-before-Activity_1uhozy1"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Archive", "☝ ⏵︎Archive", "☑ ⏵︎xxx"] start:☝ ⏵︎Archive
        ["suspend-gw-to-catch-before-Activity_1hgscu3", "suspend-gw-to-catch-before-Activity_0fy41qq", "~suspend~"], {start_id: "catch-before-Activity_0fy41qq"},
        # after: ["⛾ ◉End.success", "☝ ◉End.success", "☑ ⏵︎xxx"]
        ["Event_1p8873y", "Event_0h6yhq6", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise", "☑ ⏵︎xxx"] start:☝ ⏵︎Revise
        ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "~suspend~"], {start_id: "catch-before-Activity_1wiumzv"},
        # after: ["⛾ ⏵︎Revise ⏵︎Notify approver", "☝ ⏵︎Revise form ⏵︎Notify approver", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1kl7pnm", "suspend-Gateway_00n4dsm", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise", "☑ ⏵︎xxx"] start:☝ ⏵︎Revise
        ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "~suspend~"], {start_id: "catch-before-Activity_1wiumzv"},
        # after: ["⛾ ⏵︎Revise", "☝ ⏵︎Revise", "☑ ⏵︎xxx"]
        ["suspend-Gateway_01p7uj7", "suspend-Gateway_1xs96ik", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Revise ⏵︎Notify approver", "☝ ⏵︎Revise form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Revise form
        ["suspend-Gateway_1kl7pnm", "suspend-Gateway_00n4dsm", "~suspend~"], {start_id: "catch-before-Activity_0zsock2"},
        # after: ["⛾ ⏵︎Revise ⏵︎Notify approver", "☝ ⏵︎Revise", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1kl7pnm", "suspend-Gateway_1xs96ik", "~suspend~"],
      ],

      [
        # before: ["⛾ ⏵︎Revise ⏵︎Notify approver", "☝ ⏵︎Revise form ⏵︎Notify approver", "☑ ⏵︎xxx"] start:☝ ⏵︎Notify approver
        ["suspend-Gateway_1kl7pnm", "suspend-Gateway_00n4dsm", "~suspend~"], {start_id: "catch-before-Activity_1dt5di5"},
        # after: ["⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update", "☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish", "☑ ⏵︎xxx"]
        ["suspend-Gateway_1hp2ssj", "suspend-Gateway_1sq41iq", "~suspend~"],
      ],
    ]

    # order = ->((_, start_cfg_a), (_, start_cfg_b)) { raise start_cfg_a.inspect }
    # assert_data_for_iteration_set_sorted = assert_data_for_iteration_set.sort(&order)

    lanes_cfg = schema.to_h[:lanes]

    assert_data_for_iteration_set.each.with_index do |(start_position_ids, start_cfg, suspend_ids), index|
      puts "@@@@@ #{index.inspect} #{states[index][:positions_before][1]}"
      # raise index.inspect
      assert_position_before states[index][:positions_before],
        start_position_ids,
        start_id: start_cfg[:start_id],
        lanes: lanes_cfg

      assert_position_after states[index][:suspend_configuration],
        suspend_ids,
        lanes: lanes_cfg
    end

  end

  it "Iteration::Set" do
    states, schema, lanes_cfg = self.class.states

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    testing_json = JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg))
    # File.write("test/iteration_json.json", testing_json)
    assert_equal testing_json, File.read("test/iteration_json.json")

    iteration_set_from_json = Trailblazer::Workflow::Introspect::Iteration::Set::Deserialize.(JSON.parse(testing_json), lanes_cfg: lanes_cfg)


# Deserialized iteration set test.
    # pp iteration_set_from_json.to_a[0]
    # raise






    assert_equal JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set, lanes_cfg: lanes_cfg)), JSON.pretty_generate(Trailblazer::Workflow::Introspect::Iteration::Set::Serialize.(iteration_set_from_json, lanes_cfg: lanes_cfg))

    # assert_equal iteration_set_from_json.to_a.collect { |iteration| iteration.to_h }, iteration_set.to_a.collect { |iteration| iteration.to_h }

    # pp iteration_set_from_json.to_a.collect { |iteration| iteration.to_h }[0]

    # TODO: test {Set#to_a}
    assert_equal iteration_set_from_json.to_a.size, 21
  end

  # Asserts
  #   * that positions are always sorted by activity.
  def assert_position_before(actual_positions, expected_ids, start_id:, lanes:)
    actual_lane_positions, actual_start_position = actual_positions

    assert_positions_for(actual_lane_positions, expected_ids, lanes: lanes)

    assert_equal Trailblazer::Activity::Introspect.Nodes(actual_start_position.activity, task: actual_start_position.task).id, start_id, "start task mismatch"
  end

  def assert_positions_for(actual_lane_positions, expected_ids, lanes:)
    lanes = lanes.to_h.keys

    actual_lane_positions.collect.with_index do |actual_position, index|
      actual_activity, actual_task = actual_position.to_a

      expected_activity = lanes[index]

      assert_equal [actual_activity, Trailblazer::Activity::Introspect.Nodes(actual_activity, task: actual_task).id],
        [expected_activity, expected_ids[index]]
    end
  end

  def assert_position_after(actual_configuration, expected_ids, lanes:)
    actual_positions = actual_configuration.lane_positions

    assert_positions_for(actual_positions, expected_ids, lanes: lanes)
  end

  # DISCUSS: currently, this event table doesn't make a lot of sense.
  it "{Present::EventTable.call}" do
    states, schema, lanes_cfg = self.class.states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    # DISCUSS: this table shows redundant events, is that from success/failure discovery?
    cli_state_table_with_ids = Trailblazer::Workflow::Introspect::EventTable.(iteration_set, render_ids: true, hide_lanes: ["approver"], lanes_cfg: lanes_cfg)
puts cli_state_table_with_ids
assert_equal cli_state_table_with_ids,
%(+-------------------------------+---------------------------------------------+---------------------------------------------+
| triggered event               | lifecycle                                   | UI                                          |
+-------------------------------+---------------------------------------------+---------------------------------------------+
| ☝ ⏵︎Create form                | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create form                              |
| catch-before-Activity_0wc2mcq | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-gw-to-catch-before-Activity_0wc2mcq |
| ☝ ⏵︎Create                     | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create                                   |
| catch-before-Activity_1psp91r | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| ☝ ⏵︎Create                     | ⛾ ⏵︎Create                                   | ☝ ⏵︎Create                                   |
| catch-before-Activity_1psp91r | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| ☝ ⏵︎Update form                | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1165bw9 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Update                     | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update                                   |
| catch-before-Activity_0j78uzd | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| ☝ ⏵︎Update form                | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish       |
| catch-before-Activity_1165bw9 | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| ☝ ⏵︎Delete? form               | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish       |
| catch-before-Activity_0ha7224 | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| ☝ ⏵︎Publish                    | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish       |
| catch-before-Activity_0bsjggk | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| ☝ ⏵︎Update                     | ⛾ ⏵︎Update ⏵︎Notify approver                  | ☝ ⏵︎Update                                   |
| catch-before-Activity_0j78uzd | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| ☝ ⏵︎Update form                | ⛾ ⏵︎Notify approver ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1165bw9 | suspend-Gateway_1wzosup                     | suspend-Gateway_1g3fhu2                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Notify approver ⏵︎Update                  | ☝ ⏵︎Update form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_1wzosup                     | suspend-Gateway_1g3fhu2                     |
| ☝ ⏵︎Revise form                | ⛾ ⏵︎Revise                                   | ☝ ⏵︎Revise form                              |
| catch-before-Activity_0zsock2 | suspend-Gateway_01p7uj7                     | suspend-gw-to-catch-before-Activity_0zsock2 |
| ☝ ⏵︎Delete                     | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Delete ⏵︎Cancel                           |
| catch-before-Activity_15nnysv | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| ☝ ⏵︎Cancel                     | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update                  | ☝ ⏵︎Delete ⏵︎Cancel                           |
| catch-before-Activity_1uhozy1 | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| ☝ ⏵︎Archive                    | ⛾ ⏵︎Archive                                  | ☝ ⏵︎Archive                                  |
| catch-before-Activity_0fy41qq | suspend-gw-to-catch-before-Activity_1hgscu3 | suspend-gw-to-catch-before-Activity_0fy41qq |
| ☝ ⏵︎Revise                     | ⛾ ⏵︎Revise                                   | ☝ ⏵︎Revise                                   |
| catch-before-Activity_1wiumzv | suspend-Gateway_01p7uj7                     | suspend-Gateway_1xs96ik                     |
| ☝ ⏵︎Revise                     | ⛾ ⏵︎Revise                                   | ☝ ⏵︎Revise                                   |
| catch-before-Activity_1wiumzv | suspend-Gateway_01p7uj7                     | suspend-Gateway_1xs96ik                     |
| ☝ ⏵︎Revise form                | ⛾ ⏵︎Revise ⏵︎Notify approver                  | ☝ ⏵︎Revise form ⏵︎Notify approver             |
| catch-before-Activity_0zsock2 | suspend-Gateway_1kl7pnm                     | suspend-Gateway_00n4dsm                     |
| ☝ ⏵︎Notify approver            | ⛾ ⏵︎Revise ⏵︎Notify approver                  | ☝ ⏵︎Revise form ⏵︎Notify approver             |
| catch-before-Activity_1dt5di5 | suspend-Gateway_1kl7pnm                     | suspend-Gateway_00n4dsm                     |
+-------------------------------+---------------------------------------------+---------------------------------------------+)
  end
end

class DiscoveryTestPlanTest < Minitest::Spec
  it "render comment header for test plan" do
    states, schema, lanes_cfg = DiscoveryTest.states()

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    # this usually happens straight after discovery:
    test_plan_comment_header = Trailblazer::Workflow::Test::Plan::Introspect.(iteration_set, lanes_cfg: lanes_cfg)
    puts test_plan_comment_header
    assert_equal test_plan_comment_header,
%(+----------------------+----------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------+
| triggered catch      | start configuration                                                                          | expected reached configuration                                                               |
+----------------------+----------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------+
| ☝ ⏵︎Create form       | ⛾ ⏵︎Create <0wwf>                  ☝ ⏵︎Create form <0wc2>                        ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Create <0wwf>                  ☝ ⏵︎Create <14h0>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Create            | ⛾ ⏵︎Create <0wwf>                  ☝ ⏵︎Create <14h0>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update form ⏵︎Notify approver <0kkn>       ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Create ⛞          | ⛾ ⏵︎Create <0wwf>                  ☝ ⏵︎Create <14h0>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Create <0wwf>                  ☝ ⏵︎Create <14h0>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Update form       | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update form ⏵︎Notify approver <0kkn>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Notify approver   | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update form ⏵︎Notify approver <0kkn>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Update            | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Notify approver ⏵︎Update <1wzo> ☝ ⏵︎Update form ⏵︎Notify approver <1g3f>       ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Notify approver ⛞ | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update form ⏵︎Notify approver <0kkn>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise form <0zso>                        ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Update form       | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Delete? form      | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Delete ⏵︎Cancel <100g>                     ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Publish           | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Archive <1hgs>                 ☝ ⏵︎Archive <0fy4>                            ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Update ⛞          | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Update ⏵︎Notify approver <0fnb> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Update form       | ⛾ ⏵︎Notify approver ⏵︎Update <1wzo> ☝ ⏵︎Update form ⏵︎Notify approver <1g3f>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Notify approver ⏵︎Update <1wzo> ☝ ⏵︎Update <0nxe>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Notify approver   | ⛾ ⏵︎Notify approver ⏵︎Update <1wzo> ☝ ⏵︎Update form ⏵︎Notify approver <1g3f>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Revise form       | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise form <0zso>                        ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise <1xs9>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Delete            | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Delete ⏵︎Cancel <100g>                     ☑ ⏵︎xxx <uspe> | ⛾ ◉End.success <1p88>             ☝ ◉End.success <0h6y>                        ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Cancel            | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Delete ⏵︎Cancel <100g>                     ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Archive           | ⛾ ⏵︎Archive <1hgs>                 ☝ ⏵︎Archive <0fy4>                            ☑ ⏵︎xxx <uspe> | ⛾ ◉End.success <1p88>             ☝ ◉End.success <0h6y>                        ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Revise            | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise <1xs9>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Revise ⏵︎Notify approver <1kl7> ☝ ⏵︎Revise form ⏵︎Notify approver <00n4>       ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Revise ⛞          | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise <1xs9>                             ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Revise <01p7>                  ☝ ⏵︎Revise <1xs9>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Revise form       | ⛾ ⏵︎Revise ⏵︎Notify approver <1kl7> ☝ ⏵︎Revise form ⏵︎Notify approver <00n4>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Revise ⏵︎Notify approver <1kl7> ☝ ⏵︎Revise <1xs9>                             ☑ ⏵︎xxx <uspe> |
| ☝ ⏵︎Notify approver   | ⛾ ⏵︎Revise ⏵︎Notify approver <1kl7> ☝ ⏵︎Revise form ⏵︎Notify approver <00n4>       ☑ ⏵︎xxx <uspe> | ⛾ ⏵︎Publish ⏵︎Delete ⏵︎Update <1hp2> ☝ ⏵︎Update form ⏵︎Delete? form ⏵︎Publish <1sq4> ☑ ⏵︎xxx <uspe> |
+----------------------+----------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------+)
  end
end

class TestPlanExecutionTest < Minitest::Spec
  include Trailblazer::Workflow::Test::Assertions
  require "trailblazer/test/assertions"
  include Trailblazer::Test::Assertions # DISCUSS: this is for assert_advance and friends.

  it "run test plan" do
    states, schema, lanes_cfg, message_flow = DiscoveryTest.states()

    schema = schema.to_h.merge(message_flow: message_flow)
    schema = schema.to_h.merge(state_guards: state_guards()) # FIXME

    iteration_set = Trailblazer::Workflow::Introspect::Iteration::Set.from_discovered_states(states, lanes_cfg: lanes_cfg)

    #@ Test plan
    # FIXME: properly test this output!
    puts Trailblazer::Workflow::Test::Plan.for(iteration_set, lanes_cfg: lanes_cfg, input: {})

    # TODO: encapsulate
    # plan_structure = Trailblazer::Workflow::Test::Plan::Structure.serialize(states, lanes_cfg: lanes_cfg)
    # testing_json = JSON.pretty_generate(plan_structure)
    # test_plan_structure = Trailblazer::Workflow::Test::Plan::Structure.deserialize(plan_structure, lanes_cfg: lanes_cfg)
    test_plan_structure = iteration_set

    # test: ☝ ⏵︎Create form
    ctx = assert_advance "☝ ⏵︎Create form", expected_ctx: {}, test_plan: test_plan_structure, schema: schema
    assert_exposes ctx, seq: [:create_form], reader: :[]

    # test: ☝ ⏵︎Create
    ctx = assert_advance "☝ ⏵︎Create", expected_ctx: {}, test_plan: test_plan_structure, schema: schema
    assert_exposes ctx, seq: [:ui_create, :create], reader: :[]

    # test: ☝ ⏵︎Create ⛞
    ctx = assert_advance "☝ ⏵︎Create ⛞", ctx: {create: false, seq: []}, expected_ctx: {}, test_plan: test_plan_structure, schema: schema
    assert_exposes ctx, seq: [:ui_create, :create, :create_form_with_errors], reader: :[]

    # test: ☝ ⏵︎Update form
    ctx = assert_advance "☝ ⏵︎Update form", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {seq: [], model: Posting.new(state: "⏸︎ Update form♦Notify approver [00u]")}
    assert_exposes ctx, seq: [:update_form], reader: :[]

    # test: ☝ ⏵︎Notify approver
    ctx = assert_advance "☝ ⏵︎Notify approver", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {seq: [], model: Posting.new(state: "⏸︎ Update form♦Notify approver [00u]")}
    assert_exposes ctx, seq: [:notify_approver, :notify_approver, :approve], reader: :[]

    # test: ☝ ⏵︎Update
    ctx = assert_advance "☝ ⏵︎Update", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {seq: [], model: Posting.new(state: "⏸︎ Update [00u]")}
    assert_exposes ctx, seq: [:ui_update, :update], reader: :[]

    # test: ☝ ⏵︎Notify approver ⛞
    ctx = assert_advance "☝ ⏵︎Notify approver ⛞", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {decision: false, seq: [], model: Posting.new(state: "⏸︎ Update form♦Notify approver [00u]")}
    assert_exposes ctx, seq: [:notify_approver, :notify_approver, :reject], reader: :[]

    # test: ☝ ⏵︎Delete? form
    ctx = assert_advance "☝ ⏵︎Delete? form", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {seq: [], model: Posting.new(state: "⏸︎ Update form♦Delete? form♦Publish [11u]")}
    assert_exposes ctx, seq: [:delete_form], reader: :[]

    # test: ☝ ⏵︎Publish
    ctx = assert_advance "☝ ⏵︎Publish", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {seq: [], model: Posting.new(state: "⏸︎ Update form♦Delete? form♦Publish [11u]")}
    assert_exposes ctx, seq: [:publish, :publish], reader: :[]

    # test: ☝ ⏵︎Update ⛞
    ctx = assert_advance "☝ ⏵︎Update ⛞", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Update [00u]")}
    assert_exposes ctx, seq: [:ui_update, :update, :update_form_with_errors], reader: :[]

    # test: ☝ ⏵︎Revise form
    ctx = assert_advance "☝ ⏵︎Revise form", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Revise form [00u]")}
    assert_exposes ctx, seq: [:revise_form], reader: :[]

    # test: ☝ ⏵︎Delete
    ctx = assert_advance "☝ ⏵︎Delete", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Delete♦Cancel [11u]")}
    assert_exposes ctx, seq: [:delete, :delete], reader: :[]

    # test: ☝ ⏵︎Cancel
    ctx = assert_advance "☝ ⏵︎Cancel", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Delete♦Cancel [11u]")}
    assert_exposes ctx, seq: [:cancel], reader: :[]

    # test: ☝ ⏵︎Archive
    ctx = assert_advance "☝ ⏵︎Archive", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Archive [10u]")}
    assert_exposes ctx, seq: [:archive, :archive], reader: :[]

    # test: ☝ ⏵︎Revise
    ctx = assert_advance "☝ ⏵︎Revise", expected_ctx: {}, test_plan: test_plan_structure, schema: schema, ctx: {update: false, seq: [], model: Posting.new(state: "⏸︎ Revise [01u]")}
    assert_exposes ctx, seq: [:revise, :revise], reader: :[]


# TODO: test error message for assert_advance
# TODO: test invalid: true and {invalid_event} outcome
  end

end
