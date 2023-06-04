require "test_helper"
require "json"

class GenerateTest < Minitest::Spec
  # UNIT TEST {Generate::Representer}
  it "works with PRO's JSON format" do
    # from ../pro-rails/test/fixtures/bpmn2/moderation.xml-exported.json
    moderation_json = File.read("test/fixtures/v1/moderation.json")

    collaboration = Trailblazer::Workflow::Generate::Representer::Collaboration.new(OpenStruct.new).from_json(moderation_json)

    assert_equal collaboration.id, 1

    lifecycle_lane = collaboration.lanes.find { |lane| lane.id == "article moderation" }

    assert_equal lifecycle_lane.id, "article moderation"

    # assert_equal lifecycle_lane.type "lane"
    assert_equal lifecycle_lane.elements.size, 39

    create = lifecycle_lane.elements[4]
    assert_equal create.id, "Activity_0wwfenp"
    assert_equal create.label, "Create"
    assert_equal create.type, :task
    assert_equal create.links.size, 2
    assert_equal create.links[0].target_id, "throw-after-Activity_0wwfenp"
    assert_equal create.links[0].semantic, :success
    assert_equal create.links[1].target_id, "Event_0odjl3c"
    assert_equal create.links[1].semantic, :failure
    assert_equal create.data, {}

    suspend = lifecycle_lane.elements[32]
    assert_equal suspend.id, "suspend-Gateway_1wzosup"
    assert_equal suspend.type, :suspend
    assert_equal suspend.links.size, 0
    assert_equal suspend.data["resumes"], ["catch-before-Activity_0wr78cv", "catch-before-Activity_0q9p56e"]
  end

  it do
    skip
    moderation_json = File.read("test/fixtures/v1/moderation.json")

    signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: moderation_json}, {}])

    lanes = ctx[:intermediates]

    # pp lanes
    # TODO: test ui lane
    assert_equal lanes["article moderation"].pretty_inspect, %(#<struct Trailblazer::Activity::Schema::Intermediate
 wiring=
  {#<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Create",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Create">,
     #<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:failure,
      target="create_invalid!">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f",
    data=
     {"resumes"=>["catch-before-Update", "catch-before-Notify approver"],
      :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Update",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Update">,
     #<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:failure,
      target="update_invalid!">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-e1b7cd7c-55ca-48e8-ae4b-bdfee7b221e0",
    data=
     {"resumes"=>["catch-before-Notify approver", "catch-before-Update"],
      :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Notify approver",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Notify approver">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-62921669-ef4e-4753-b3e9-b5ee498594a3",
    data=
     {"resumes"=>["catch-before-Reject", "catch-before-Approve"],
      :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Reject",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Reject">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Approve",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Approve">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-d99c4fe5-ee6f-4bda-8ed5-c74464ff0ea5",
    data={"resumes"=>["catch-before-Revise"], :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Revise",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Revise">,
     #<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:failure,
      target="revise_invalid!">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-dec8907b-b3e0-43e4-a536-343052bd83c3",
    data=
     {"resumes"=>["catch-before-Notify approver", "catch-before-Revise"],
      :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="revise_invalid!",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-d99c4fe5-ee6f-4bda-8ed5-c74464ff0ea5">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="update_invalid!",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-21a0f9bb-0b3f-4dba-8951-04df2cdc50d0",
    data=
     {"resumes"=>
       ["catch-before-Publish", "catch-before-Delete", "catch-before-Update"],
      :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Publish",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Publish">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Archive",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Archive">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="success",
    data={:type=>:terminus}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="Delete",
    data={:type=>:task}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="throw-after-Delete">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="create_invalid!",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-gw-to-catch-before-Create">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Create",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Create">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Create",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Update",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Update">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Update",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-e1b7cd7c-55ca-48e8-ae4b-bdfee7b221e0">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Notify approver",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Notify approver">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Notify approver",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-62921669-ef4e-4753-b3e9-b5ee498594a3">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Reject",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Reject">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Reject",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-d99c4fe5-ee6f-4bda-8ed5-c74464ff0ea5">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Approve",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Approve">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Approve",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-21a0f9bb-0b3f-4dba-8951-04df2cdc50d0">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Revise",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Revise">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Revise",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-dec8907b-b3e0-43e4-a536-343052bd83c3">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Publish",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Publish">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Publish",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="suspend-gw-to-catch-before-Archive">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Archive",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Archive">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Archive",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="success">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="catch-before-Delete",
    data={:type=>:catch_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="Delete">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="throw-after-Delete",
    data={:type=>:throw_event}>=>
    [#<struct Trailblazer::Activity::Schema::Intermediate::Out
      semantic=:success,
      target="success">],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-gw-to-catch-before-Create",
    data={"resumes"=>["catch-before-Create"], :type=>:suspend}>=>[],
   #<struct Trailblazer::Activity::Schema::Intermediate::TaskRef
    id="suspend-gw-to-catch-before-Archive",
    data={"resumes"=>["catch-before-Archive"], :type=>:suspend}>=>[]},
 stop_task_ids=
  {"success"=>:success,
   "suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f"=>:suspend,
   "suspend-e1b7cd7c-55ca-48e8-ae4b-bdfee7b221e0"=>:suspend,
   "suspend-62921669-ef4e-4753-b3e9-b5ee498594a3"=>:suspend,
   "suspend-d99c4fe5-ee6f-4bda-8ed5-c74464ff0ea5"=>:suspend,
   "suspend-dec8907b-b3e0-43e4-a536-343052bd83c3"=>:suspend,
   "suspend-21a0f9bb-0b3f-4dba-8951-04df2cdc50d0"=>:suspend,
   "suspend-gw-to-catch-before-Create"=>:suspend,
   "suspend-gw-to-catch-before-Archive"=>:suspend},
 start_task_id="Create">
)

    assert_equal lanes["article moderation"].pretty_inspect, %(#<struct Trailblazer::Activity::Schema::Intermediate
    )
  end
end
