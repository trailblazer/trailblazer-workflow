require "test_helper"

# TODO: how can we prevent users from triggering lifecycle.Create? only UI events allowed?
#
class CollaborationTest < Minitest::Spec
  require "trailblazer/test/assertions"
  include Trailblazer::Test::Assertions # DISCUSS: this is for assert_advance and friends.


  include BuildSchema

    # TODO: remove me, or move me at least!
    # DISCUSS: {states} should probably be named {reached_states} as some states appear multiple times in the list.
    def render_states(states, lanes:, additional_state_data:, task_map:)
      present_states = Trailblazer::Workflow::State::Discovery.generate_from(states) # returns rows with [{activity, suspend, resumes}]

      rows = present_states.collect do |state| # state = {start_position, lane_states: [{activity, suspend, resumes}]}
        # raise state.inspect

        start_position, lane_positions, discovery_state_fixme = state.to_a

        triggered_catch_event_id = Trailblazer::Activity::Introspect.Nodes(start_position.activity, task: start_position.task).id

        # Go through each lane.
        row = lane_positions.flat_map do |lane_position|
          next if lane_position.nil? # FIXME: why do we have that?

          activity, suspend, resumes = lane_position[:activity], lane_position[:suspend], lane_position[:resumes]
          # next if suspend.to_h["resumes"].nil?

        # Compute the task name that follows a particular catch event.
        # TODO: use Testing's code here.
          resumes_labels = resumes.collect do |catch_event|

            task_after_catch = activity.to_h[:circuit].to_h[:map][catch_event][Trailblazer::Activity::Right]
            # raise task_after_catch.inspect

            Trailblazer::Activity::Introspect.Nodes(activity, task: task_after_catch).data[:label] || task_after_catch
          end

          [
            lanes[activity],
            resumes_labels.inspect,

            "#{lanes[activity]} suspend",
            suspend.to_h[:semantic][1],
          ]
        end

        ctx_before, ctx_after = additional_state_data[discovery_state_fixme.object_id]
        # raise data.inspect

        triggered_catch_event_label = nil
        task_map.invert.each do |id, label|
          if triggered_catch_event_id =~ /#{id}$/
            triggered_catch_event_label = "--> #{label}" and break
          end
        end


        row = Hash[*row.compact, "ctx before", ctx_before, "ctx after", ctx_after, "triggered catch", triggered_catch_event_label]
      end
      # .uniq # comment me if you want to see all reached configurations


      puts Hirb::Helpers::Table.render(rows, fields: [
        "triggered catch",
        "UI",
        # "UI suspend",
        "lifecycle",
        # "lifecycle suspend",
        "ctx before",
        "ctx after",
      ], max_width: 186) # 186 for laptop 13"
    end


  it "Collaboration::StateTable generating" do # FIXME: move me
    skip "extract me from below"
    schema, lane_activity, lane_activity_ui, message_flow = build_schema()

    state_table = Trailblazer::Workflow::State::Discovery.generate_state_table

  end

  it "Collaboration::StateTable interface that already knows the lane positions" do
    schema, lane_activity, lane_activity_ui, message_flow = build_schema()

    state_table = todo

    collaboration_state_table_interface.(schema, state_table, event: "ui_create_form", process_model_id: nil)
  end

  it "low level {Collaboration.advance} API" do
    ui_create_form = "Activity_0wc2mcq" # TODO: this is from pro-rails tests.
    ui_create = "Activity_1psp91r"
    ui_create_valid = "Event_0km79t5"
    ui_create_invalid = "Event_0co8ygx"
    ui_update_form = 'Activity_1165bw9'
    ui_update = "Activity_0j78uzd"
    ui_update_valid = "Event_1vf88fn"
    ui_update_invalid = "Event_1nt0djb"
    ui_notify_approver = "Activity_1dt5di5"
    ui_accepted = "Event_1npw1tg"
    ui_delete_form = "Activity_0ha7224"
    ui_delete = "Activity_15nnysv"
    ui_cancel = "Activity_1uhozy1"
    ui_publish = "Activity_0bsjggk"
    ui_archive = "Activity_0fy41qq"
    ui_revise_form = "Activity_0zsock2"
    ui_revise = "Activity_1wiumzv"
    ui_revise_valid = "Event_1bz3ivj"
    ui_revise_invalid = "Event_1wly6jj"
    ui_revise_form_with_errors = "Activity_19m1lnz"
    ui_create_form_with_errors = "Activity_08p0cun"
    ui_update_form_with_errors = "Activity_00kfo8w"
    ui_rejected = "Event_1vb197y"

    # FIXME: redundant with {lane_test}.
    create_id = "Activity_0wwfenp"
    update_id = "Activity_0q9p56e"
    notify_id = "Activity_0wr78cv"


    revise_id = "Activity_18qv6ob"
    publish_id = "Activity_1bjelgv"
    delete_id = "Activity_0cc4us9"
    archive_id = "Activity_1hgscu3"
    success_id = "Event_1p8873y"


    schema, lanes, message_flow, initial_lane_positions = build_schema()
    schema_hash = schema.to_h

    lane_activity = lanes[:lifecycle]
    lane_activity_ui = lanes[:ui]
    approver_activity = lanes[:approver]




    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)


    states, additional_state_data = Trailblazer::Workflow::Discovery.(
      schema,
      initial_lane_positions: initial_lane_positions,
      start_position: start_position,
      message_flow: message_flow,

      # TODO: allow translating the original "id" (?) to the stubbed.
      run_multiple_times: {
         # We're "clicking" the [Notify_approver] button again, this time to get rejected.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_notify_approver}").task => {ctx_merge: {
              # decision: false, # TODO: this is how it should be.
              :"approver:xxx" => Trailblazer::Activity::Left, # FIXME: {:decision} must be translated to {:"approver:xxx"}
            }, config_payload: {outcome: :failure}},

          # Click [UI Create] again, with invalid data.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create}").task => {ctx_merge: {
              # create: false
              :"lifecycle:Create" => Trailblazer::Activity::Left,
            }, config_payload: {outcome: :failure}}, # lifecycle create is supposed to fail.

          # Click [UI Update] again, with invalid data.
          Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_update}").task => {ctx_merge: {
              # update: false
              :"lifecycle:Update" => Trailblazer::Activity::Left,
            }, config_payload: {outcome: :failure}}, # lifecycle create is supposed to fail.
      }
    )



    # render_states(states, lanes: ___lanes___ = {lane_activity => "lifecycle", lane_activity_ui => "UI", approver_activity => "approver"}, additional_state_data: additional_state_data, task_map: task_map)
# raise "figure out how to build a generated state table"

    ___lanes___ = {lane_activity => "lifecycle", lane_activity_ui => "UI", approver_activity => "approver"}


    # DISCUSS: technically, this is an event table, not a state table.
    state_table = Trailblazer::Workflow::State::Discovery.generate_state_table(states, lanes: ___lanes___)

    cli_state_table = Trailblazer::Workflow::State::Discovery.render_cli_state_table(state_table)
    puts cli_state_table
    assert_equal cli_state_table,
%(+---------------------------------+--------------------------------------------+
| state name                      | triggerable events                         |
+---------------------------------+--------------------------------------------+
| "> Create form"                 | "UI: ▶Create form"                         |
| "> Create"                      | "UI: ▶Create"                              |
| "> Update form/Notify approver" | "UI: ▶Update form", "UI: ▶Notify approver" |
| "> Update"                      | "UI: ▶Update"                              |
| "> Delete? form/Publish"        | "UI: ▶Delete? form", "UI: ▶Publish"        |
| "> Revise form"                 | "UI: ▶Revise form"                         |
| "> Delete/Cancel"               | "UI: ▶Delete", "UI: ▶Cancel"               |
| "> Archive"                     | "UI: ▶Archive"                             |
| "> Revise"                      | "UI: ▶Revise"                              |
+---------------------------------+--------------------------------------------+
9 rows in set)


# currently, from this table we can read the discovery process, what states were discovered and what start lane positions those states imply.
# we still have redundant states here, as the discovery algorithm was instructed to invoke several events multiple times.
    cli_state_table = Trailblazer::Workflow::State::Discovery.render_cli_event_table(state_table)
    # puts cli_state_table
    assert_equal cli_state_table,
%(+-------------------+-----------------------+-------------------------+------------------------------------+-----------------------------------------------------------------+
| event name        | triggered catch event | lifecycle               | UI                                 | approver                                                        |
+-------------------+-----------------------+-------------------------+------------------------------------+-----------------------------------------------------------------+
| "Create form"     | UI: ▶Create form      | Create                  | Create form                        | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Create"          | UI: ▶Create           | Create                  | Create                             | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Create"          | UI: ▶Create           | Create                  | Create                             | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Update form"     | UI: ▶Update form      | Update, Notify approver | Update form, Notify approver       | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Notify approver" | UI: ▶Notify approver  | Update, Notify approver | Update form, Notify approver       | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Update"          | UI: ▶Update           | Update, Notify approver | Update                             | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Notify approver" | UI: ▶Notify approver  | Update, Notify approver | Update form, Notify approver       | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Delete? form"    | UI: ▶Delete? form     | Publish, Delete, Update | Update form, Delete? form, Publish | failure                                                         |
| "Publish"         | UI: ▶Publish          | Publish, Delete, Update | Update form, Delete? form, Publish | failure                                                         |
| "Update"          | UI: ▶Update           | Update, Notify approver | Update                             | [#<Trailblazer::Workflow::Event::Throw semantic="xxx_approve">] |
| "Revise form"     | UI: ▶Revise form      | Revise                  | Revise form                        | success                                                         |
| "Delete"          | UI: ▶Delete           | Publish, Delete, Update | Delete, Cancel                     | failure                                                         |
| "Cancel"          | UI: ▶Cancel           | Publish, Delete, Update | Delete, Cancel                     | failure                                                         |
| "Archive"         | UI: ▶Archive          | Archive                 | Archive                            | failure                                                         |
| "Revise"          | UI: ▶Revise           | Revise                  | Revise                             | success                                                         |
+-------------------+-----------------------+-------------------------+------------------------------------+-----------------------------------------------------------------+
15 rows in set)

    cli_state_table_with_ids = Trailblazer::Workflow::State::Discovery.render_cli_event_table(state_table, render_ids: true)
    puts cli_state_table_with_ids
    # FIXME: we still have wrong formatting for ID rows with CLI coloring.
    assert_equal cli_state_table_with_ids,
%(+-------------------+----------------------------------------+----------------------------------------+----------------------------------------+----------------------------------------+
| event name        | triggered catch event                  | lifecycle                              | UI                                     | approver                               |
+-------------------+----------------------------------------+----------------------------------------+----------------------------------------+----------------------------------------+
| \"Create form\"     | UI: ▶Create form                       | [\"Create\"]                             | [\"Create form\"]                        | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_0wc2mcq\e[0m | suspend-gw-to-catch-before-Activity... | suspend-gw-to-catch-before-Activity... | #<Trailblazer::Workflow::Event::Sus... |
| \"Create\"          | UI: ▶Create                            | [\"Create\"]                             | [\"Create\"]                             | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_1psp91r\e[0m | suspend-gw-to-catch-before-Activity... | suspend-Gateway_14h0q7a                | #<Trailblazer::Workflow::Event::Sus... |
| \"Create\"          | UI: ▶Create                            | [\"Create\"]                             | [\"Create\"]                             | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_1psp91r\e[0m | suspend-gw-to-catch-before-Activity... | suspend-Gateway_14h0q7a                | #<Trailblazer::Workflow::Event::Sus... |
| \"Update form\"     | UI: ▶Update form                       | [\"Update\", \"Notify approver\"]          | [\"Update form\", \"Notify approver\"]     | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_1165bw9\e[0m | suspend-Gateway_0fnbg3r                | suspend-Gateway_0kknfje                | #<Trailblazer::Workflow::Event::Sus... |
| \"Notify approver\" | UI: ▶Notify approver                   | [\"Update\", \"Notify approver\"]          | [\"Update form\", \"Notify approver\"]     | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_1dt5di5\e[0m | suspend-Gateway_0fnbg3r                | suspend-Gateway_0kknfje                | #<Trailblazer::Workflow::Event::Sus... |
| \"Update\"          | UI: ▶Update                            | [\"Update\", \"Notify approver\"]          | [\"Update\"]                             | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_0j78uzd\e[0m | suspend-Gateway_0fnbg3r                | suspend-Gateway_0nxerxv                | #<Trailblazer::Workflow::Event::Sus... |
| \"Notify approver\" | UI: ▶Notify approver                   | [\"Update\", \"Notify approver\"]          | [\"Update form\", \"Notify approver\"]     | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_1dt5di5\e[0m | suspend-Gateway_0fnbg3r                | suspend-Gateway_0kknfje                | #<Trailblazer::Workflow::Event::Sus... |
| \"Delete? form\"    | UI: ▶Delete? form                      | [\"Publish\", \"Delete\", \"Update\"]        | [\"Update form\", \"Delete? form\", \"Pu... | failure                                |
|                   | \e[34mcatch-before-Activity_0ha7224\e[0m | suspend-Gateway_1hp2ssj                | suspend-Gateway_1sq41iq                | End.failure                            |
| \"Publish\"         | UI: ▶Publish                           | [\"Publish\", \"Delete\", \"Update\"]        | [\"Update form\", \"Delete? form\", \"Pu... | failure                                |
|                   | \e[34mcatch-before-Activity_0bsjggk\e[0m | suspend-Gateway_1hp2ssj                | suspend-Gateway_1sq41iq                | End.failure                            |
| \"Update\"          | UI: ▶Update                            | [\"Update\", \"Notify approver\"]          | [\"Update\"]                             | [#<Trailblazer::Workflow::Event::Th... |
|                   | \e[34mcatch-before-Activity_0j78uzd\e[0m | suspend-Gateway_0fnbg3r                | suspend-Gateway_0nxerxv                | #<Trailblazer::Workflow::Event::Sus... |
| \"Revise form\"     | UI: ▶Revise form                       | [\"Revise\"]                             | [\"Revise form\"]                        | success                                |
|                   | \e[34mcatch-before-Activity_0zsock2\e[0m | suspend-Gateway_01p7uj7                | suspend-gw-to-catch-before-Activity... | End.success                            |
| \"Delete\"          | UI: ▶Delete                            | [\"Publish\", \"Delete\", \"Update\"]        | [\"Delete\", \"Cancel\"]                   | failure                                |
|                   | \e[34mcatch-before-Activity_15nnysv\e[0m | suspend-Gateway_1hp2ssj                | suspend-Gateway_100g9dn                | End.failure                            |
| \"Cancel\"          | UI: ▶Cancel                            | [\"Publish\", \"Delete\", \"Update\"]        | [\"Delete\", \"Cancel\"]                   | failure                                |
|                   | \e[34mcatch-before-Activity_1uhozy1\e[0m | suspend-Gateway_1hp2ssj                | suspend-Gateway_100g9dn                | End.failure                            |
| \"Archive\"         | UI: ▶Archive                           | [\"Archive\"]                            | [\"Archive\"]                            | failure                                |
|                   | \e[34mcatch-before-Activity_0fy41qq\e[0m | suspend-gw-to-catch-before-Activity... | suspend-gw-to-catch-before-Activity... | End.failure                            |
| \"Revise\"          | UI: ▶Revise                            | [\"Revise\"]                             | [\"Revise\"]                             | success                                |
|                   | \e[34mcatch-before-Activity_1wiumzv\e[0m | suspend-Gateway_01p7uj7                | suspend-Gateway_1xs96ik                | End.success                            |
+-------------------+----------------------------------------+----------------------------------------+----------------------------------------+----------------------------------------+
30 rows in set)

cli_state_table_with_ids = Trailblazer::Workflow::State::Discovery.render_cli_event_table(state_table, render_ids: true, hide_lanes: ["approver"])
puts cli_state_table_with_ids
assert_equal cli_state_table_with_ids,
%(+-------------------+----------------------------------------+---------------------------------------------+---------------------------------------------+
| event name        | triggered catch event                  | lifecycle                                   | UI                                          |
+-------------------+----------------------------------------+---------------------------------------------+---------------------------------------------+
| "Create form"     | UI: ▶Create form                       | ["Create"]                                  | ["Create form"]                             |
|                   | \e[34mcatch-before-Activity_0wc2mcq\e[0m | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-gw-to-catch-before-Activity_0wc2mcq |
| "Create"          | UI: ▶Create                            | ["Create"]                                  | ["Create"]                                  |
|                   | \e[34mcatch-before-Activity_1psp91r\e[0m | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| "Create"          | UI: ▶Create                            | ["Create"]                                  | ["Create"]                                  |
|                   | \e[34mcatch-before-Activity_1psp91r\e[0m | suspend-gw-to-catch-before-Activity_0wwfenp | suspend-Gateway_14h0q7a                     |
| "Update form"     | UI: ▶Update form                       | ["Update", "Notify approver"]               | ["Update form", "Notify approver"]          |
|                   | \e[34mcatch-before-Activity_1165bw9\e[0m | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| "Notify approver" | UI: ▶Notify approver                   | ["Update", "Notify approver"]               | ["Update form", "Notify approver"]          |
|                   | \e[34mcatch-before-Activity_1dt5di5\e[0m | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| "Update"          | UI: ▶Update                            | ["Update", "Notify approver"]               | ["Update"]                                  |
|                   | \e[34mcatch-before-Activity_0j78uzd\e[0m | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| "Notify approver" | UI: ▶Notify approver                   | ["Update", "Notify approver"]               | ["Update form", "Notify approver"]          |
|                   | \e[34mcatch-before-Activity_1dt5di5\e[0m | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0kknfje                     |
| "Delete? form"    | UI: ▶Delete? form                      | ["Publish", "Delete", "Update"]             | ["Update form", "Delete? form", "Publish"]  |
|                   | \e[34mcatch-before-Activity_0ha7224\e[0m | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| "Publish"         | UI: ▶Publish                           | ["Publish", "Delete", "Update"]             | ["Update form", "Delete? form", "Publish"]  |
|                   | \e[34mcatch-before-Activity_0bsjggk\e[0m | suspend-Gateway_1hp2ssj                     | suspend-Gateway_1sq41iq                     |
| "Update"          | UI: ▶Update                            | ["Update", "Notify approver"]               | ["Update"]                                  |
|                   | \e[34mcatch-before-Activity_0j78uzd\e[0m | suspend-Gateway_0fnbg3r                     | suspend-Gateway_0nxerxv                     |
| "Revise form"     | UI: ▶Revise form                       | ["Revise"]                                  | ["Revise form"]                             |
|                   | \e[34mcatch-before-Activity_0zsock2\e[0m | suspend-Gateway_01p7uj7                     | suspend-gw-to-catch-before-Activity_0zsock2 |
| "Delete"          | UI: ▶Delete                            | ["Publish", "Delete", "Update"]             | ["Delete", "Cancel"]                        |
|                   | \e[34mcatch-before-Activity_15nnysv\e[0m | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| "Cancel"          | UI: ▶Cancel                            | ["Publish", "Delete", "Update"]             | ["Delete", "Cancel"]                        |
|                   | \e[34mcatch-before-Activity_1uhozy1\e[0m | suspend-Gateway_1hp2ssj                     | suspend-Gateway_100g9dn                     |
| "Archive"         | UI: ▶Archive                           | ["Archive"]                                 | ["Archive"]                                 |
|                   | \e[34mcatch-before-Activity_0fy41qq\e[0m | suspend-gw-to-catch-before-Activity_1hgscu3 | suspend-gw-to-catch-before-Activity_0fy41qq |
| "Revise"          | UI: ▶Revise                            | ["Revise"]                                  | ["Revise"]                                  |
|                   | \e[34mcatch-before-Activity_1wiumzv\e[0m | suspend-Gateway_01p7uj7                     | suspend-Gateway_1xs96ik                     |
+-------------------+----------------------------------------+---------------------------------------------+---------------------------------------------+
30 rows in set)

# raise "introduce 'suggested state name' column"

=begin
Create            process_model.nil?
Notify_approver   state == :created || :updated || :revised
                  state == "ready_for_review"
Update            state == :created || :updated FIXME: or :revised?
Publish           state == :accepted
Revise            state == :rejected

Every configuration has one (or several) names, e.g. "created" and "updated"

This event is possible because process_model is in configuration ABC ("state")
=end
# pp additional_state_data

    testing_structure = Trailblazer::Workflow::State::Discovery::Testing.render_structure(
      states,
      lanes: {lane_activity => "lifecycle", lane_activity_ui => "UI", approver_activity => "approver"},
      additional_state_data: additional_state_data,
      lane_icons: lane_icons = {"UI" => "☝", "lifecycle" => "⛾", "approver" => "☑"},
    )

    testing_json = JSON.pretty_generate(testing_structure)
    # File.write "test/discovery_testing_json.json",  testing_json
    assert_equal testing_json, File.read("test/discovery_testing_json.json")


    # This rendering can be based on testing_structure from {states} because it always happens directly after a discovery run.
    testing_comment_header = Trailblazer::Workflow::State::Discovery::Testing.render_comment_header(testing_structure, lane_icons: lane_icons)
    puts testing_comment_header
    assert_equal testing_comment_header,
%(+----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| triggered catch      | start_configuration_formatted                                                  | expected_lane_positions_formatted                                              |
+----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
| ☝ ▶Create form       | ☝ ▶Create form                        ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... |
| ☝ ▶Create            | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
| ☝ ▶Create ⛞          | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... |
| ☝ ▶Update form       | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
| ☝ ▶Notify approver   | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
| ☝ ▶Update            | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Notify approver ▶Update ☑ ▶#<Trail... |
| ☝ ▶Notify approver ⛞ | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Revise form                        ⛾ ▶Revise                  ☑ ◉End.suc... |
| ☝ ▶Delete? form      | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
| ☝ ▶Publish           | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Archive                            ⛾ ▶Archive                 ☑ ◉End.fai... |
| ☝ ▶Update ⛞          | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
| ☝ ▶Revise form       | ☝ ▶Revise form                        ⛾ ▶Revise                  ☑         ... | ☝ ▶Revise                             ⛾ ▶Revise                  ☑ ◉End.suc... |
| ☝ ▶Delete            | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ◉End.success                        ⛾ ◉End.success             ☑ ◉End.fai... |
| ☝ ▶Cancel            | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
| ☝ ▶Archive           | ☝ ▶Archive                            ⛾ ▶Archive                 ☑         ... | ☝ ◉End.success                        ⛾ ◉End.success             ☑ ◉End.fai... |
| ☝ ▶Revise            | ☝ ▶Revise                             ⛾ ▶Revise                  ☑         ... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Revise ▶Notify approver ☑ ◉End.suc... |
+----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
15 rows in set)

    # TODO: we should be parsing the testing_json into {testing_structure} and generate a test plan from it
    # test_plan = Test::Plan.build(
    #   json: testing_json,
    #   input: {
    #     "▶Create form" => {params: {}}
    #     "▶Update ⛞" => {params: {posting: {title: ""}}}
    #   }
    #   output: { # this is what we expect
    #     "▶Update ⛞" => {"contract.default" => ->(*) { errors }}
    #   }
    # )

    puts Trailblazer::Workflow::Test::Plan.for( # TODO: this is the 2nd step after parsing {testing_json}.
      testing_structure,

      input: {
        "▶Create form" => {params: {}},
        "▶Update ⛞" => {params: {posting: {title: ""}}},
      }
    )


lanes = ___lanes___.invert

# +----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
# | triggered catch      | start_configuration_formatted                                                  | expected_lane_positions_formatted                                              |
# +----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
# | ☝ ▶Create form       | ☝ ▶Create form                        ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... |
# | ☝ ▶Create            | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
# | ☝ ▶Create ⛞          | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... | ☝ ▶Create                             ⛾ ▶Create                  ☑ ▶#<Trail... |
# | ☝ ▶Update form       | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
# | ☝ ▶Notify approver   | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
# | ☝ ▶Update            | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Notify approver ▶Update ☑ ▶#<Trail... |
# | ☝ ▶Notify approver ⛞ | ☝ ▶Update form ▶Notify approver       ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Revise form                        ⛾ ▶Revise                  ☑ ◉End.suc... |
# | ☝ ▶Delete? form      | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
# | ☝ ▶Publish           | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Archive                            ⛾ ▶Archive                 ☑ ◉End.fai... |
# | ☝ ▶Update ⛞          | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... | ☝ ▶Update                             ⛾ ▶Update ▶Notify approver ☑ ▶#<Trail... |
# | ☝ ▶Revise form       | ☝ ▶Revise form                        ⛾ ▶Revise                  ☑         ... | ☝ ▶Revise                             ⛾ ▶Revise                  ☑ ◉End.suc... |
# | ☝ ▶Delete            | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ◉End.success                        ⛾ ◉End.success             ☑ ◉End.fai... |
# | ☝ ▶Cancel            | ☝ ▶Delete ▶Cancel                     ⛾ ▶Publish ▶Delete ▶Update ☑         ... | ☝ ▶Update form ▶Delete? form ▶Publish ⛾ ▶Publish ▶Delete ▶Update ☑ ◉End.fai... |
# | ☝ ▶Archive           | ☝ ▶Archive                            ⛾ ▶Archive                 ☑         ... | ☝ ◉End.success                        ⛾ ◉End.success             ☑ ◉End.fai... |
# | ☝ ▶Revise            | ☝ ▶Revise                             ⛾ ▶Revise                  ☑         ... | ☝ ▶Update form ▶Notify approver       ⛾ ▶Revise ▶Notify approver ☑ ◉End.suc... |
# +----------------------+--------------------------------------------------------------------------------+--------------------------------------------------------------------------------+
# 15 rows in set

# test: ☝ ▶Create form
ctx = assert_advance "☝ ▶Create form", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:create_form], reader: :[]

# test: ☝ ▶Create
ctx = assert_advance "☝ ▶Create", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:ui_create, :create], reader: :[]

# test: ☝ ▶Create ⛞
ctx = assert_advance "☝ ▶Create ⛞", ctx: {seq: [], create: false}, expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:ui_create, :create, :create_form_with_errors], reader: :[]

# test: ☝ ▶Update form
ctx = assert_advance "☝ ▶Update form", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:update_form], reader: :[]

# test: ☝ ▶Notify approver
ctx = assert_advance "☝ ▶Notify approver", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:notify_approver, :notify_approver, :approve], reader: :[]

# test: ☝ ▶Update
ctx = assert_advance "☝ ▶Update", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:ui_update, :update], reader: :[]

# test: ☝ ▶Notify approver ⛞
ctx = assert_advance "☝ ▶Notify approver ⛞", ctx: {seq: [], decision: false}, expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:notify_approver, :notify_approver, :reject], reader: :[]

# test: ☝ ▶Delete? form
ctx = assert_advance "☝ ▶Delete? form", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:delete_form], reader: :[]

# test: ☝ ▶Publish
ctx = assert_advance "☝ ▶Publish", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:publish, :publish], reader: :[]

# test: ☝ ▶Update ⛞
ctx = assert_advance "☝ ▶Update ⛞", ctx: {seq: [], update: false}, expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:ui_update, :update, :update_form_with_errors], reader: :[]

# test: ☝ ▶Revise form
ctx = assert_advance "☝ ▶Revise form", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:revise_form], reader: :[]

# test: ☝ ▶Delete
ctx = assert_advance "☝ ▶Delete", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:delete, :delete], reader: :[]

# test: ☝ ▶Cancel
ctx = assert_advance "☝ ▶Cancel", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:cancel], reader: :[]

# test: ☝ ▶Archive
ctx = assert_advance "☝ ▶Archive", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:archive, :archive], reader: :[]

# test: ☝ ▶Revise
ctx = assert_advance "☝ ▶Revise", expected_ctx: {}, test_plan: testing_structure, lanes: lanes, schema: schema, message_flow: extended_message_flow
assert_exposes ctx, seq: [:revise, :revise], reader: :[]




    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(schema_hash[:lanes].values)



    # TODO: do this in the State layer.
    start_task = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "catch-before-#{ui_create_form}").task # catch-before-Activity_0wc2mcq
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, start_task)

    configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
      schema,
      [{seq: []}, {throw: []}],
      {}, # circuit_options

      start_position: start_position,
      lane_positions: initial_lane_positions, # current position/"state"

      message_flow: schema_hash[:message_flow],
    )

# TODO: test {:last_lane}.
    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]
    assert_equal configuration.lane_positions.values.inspect, %([{"resumes"=>["catch-before-#{create_id}"], :semantic=>[:suspend, "from initial_lane_positions"]}, \
#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{ui_create}"] type=:suspend semantic=[:suspend, "suspend-Gateway_14h0q7a"]>])
    assert_equal ctx.inspect, %({:seq=>[:create_form]})

# create_form <submit>
    start_task_id = Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: "suspend-Gateway_14h0q7a").data["resumes"].first # "catch-before-Activity_1psp91r"
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, Trailblazer::Activity::Introspect.Nodes(lane_activity_ui, id: start_task_id).task)

    configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
      schema,
      [{seq: []}, {throw: []}],
      {}, # circuit_options

      start_position: start_position,
      lane_positions: configuration.lane_positions, # current position/"state"

      message_flow: schema_hash[:message_flow],
    )

    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]

    assert_equal configuration.lane_positions.values.inspect, %([#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{update_id}", "catch-before-#{notify_id}"] type=:suspend semantic=[:suspend, "suspend-Gateway_0fnbg3r"]>, \
#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-#{ui_update_form}", "catch-before-#{ui_notify_approver}"] type=:suspend semantic=[:suspend, "suspend-Gateway_0kknfje"]>])
    assert_equal ctx.inspect, %({:seq=>[:ui_create, :create]})
    # we can actually see the last signal and its semantic is {[:suspend, "suspend-Gateway_0kknfje"]}
    assert_equal configuration.signal.inspect, %(#<Trailblazer::Workflow::Event::Suspend resumes=["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"] type=:suspend semantic=[:suspend, "suspend-Gateway_0kknfje"]>)
  end
  include Trailblazer::Workflow::Test::Assertions

end
