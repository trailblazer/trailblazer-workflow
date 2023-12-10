require "test_helper"

class CollaborationTest < Minitest::Spec
  it "what" do
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


    moderation_json = File.read("test/fixtures/v1/moderation.json")
    signal, (ctx, _) = Trailblazer::Workflow::Generate.invoke([{json_document: moderation_json}, {}])

    article_moderation_intermediate = ctx[:intermediates]["article moderation"]
    # pp article_moderation_intermediate

    implementing = Trailblazer::Activity::Testing.def_steps(:create, :update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete)

    lane_activity = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create" => implementing.method(:create),
      "Update" => implementing.method(:update),
      "Approve" => implementing.method(:approve),
      "Notify approver" => implementing.method(:notify_approver),
      "Revise" => implementing.method(:revise),
      "Reject" => implementing.method(:reject),
      "Publish" => implementing.method(:publish),
      "Archive" => implementing.method(:archive),
      "Delete" => implementing.method(:delete),
    )


    article_moderation_intermediate = ctx[:intermediates]["<ui> author workflow"]
    # pp article_moderation_intermediate

    implementing = Trailblazer::Activity::Testing.def_steps(:create_form, :create, :update_form, :update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete, :delete_form, :cancel, :revise_form,
      :create_form_with_errors, :update_form_with_errors, :revise_form_with_errors)

    lane_activity_ui = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create form" => implementing.method(:create_form),
      "Create" => implementing.method(:create),
      "Update form" => implementing.method(:update_form),
      "Notify approver" => implementing.method(:notify_approver),
      "Publish" => implementing.method(:publish),
      "Delete" => implementing.method(:delete),
      "Delete? form" => implementing.method(:delete_form),
      "Cancel" => implementing.method(:cancel),
      "Revise" => implementing.method(:revise),
      "Revise form" => implementing.method(:revise_form),
      "Update" => implementing.method(:update),
      "Create form with errors" => implementing.method(:create_form_with_errors),
      "Update form with errors" => implementing.method(:update_form_with_errors),
      "Revise form with errors" => implementing.method(:revise_form_with_errors),
      "Archive" => implementing.method(:archive),
      # "Approve" => implementing.method(:approve),
      # "Reject" => implementing.method(:reject),
    )

    id_to_lane = {
      "article moderation"    => lane_activity,
      "<ui> author workflow"  => lane_activity_ui,
    }

    # pp ctx[:structure].lanes
    message_flow = Trailblazer::Workflow::Collaboration.Messages(
      ctx[:structure].messages,
      id_to_lane
    )

    schema = Trailblazer::Workflow::Collaboration::Schema.new(
      lanes: {
        lifecycle:  lane_activity,
        ui:         lane_activity_ui
      },
      message_flow: message_flow,
    )

    schema_hash = schema.to_h

    # raise schema_hash.keys.inspect

    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(schema_hash[:lanes].values)

    # TODO: do this in the State layer.
    # start_task = [lane_activity_ui, initial_lane_positions[lane_activity_ui][:resume_events].first]
    start_position = Trailblazer::Workflow::Collaboration::Position.new(lane_activity_ui, initial_lane_positions[lane_activity_ui][:resume_events].first)

    configuration, (ctx, flow) = Trailblazer::Workflow::Collaboration::Synchronous.advance(
      schema,
      [{seq: []}, {throw: []}],
      {}, # circuit_options

      start_position: start_position,
      lane_positions: initial_lane_positions, # current position/"state"

      message_flow: schema_hash[:message_flow],
    )

    assert_equal configuration.lane_positions.keys, [lane_activity, lane_activity_ui]
    assert_equal configuration.lane_positions.values.inspect, %([{:resume_events=>[#<Trailblazer::Workflow::Event::Catch start_task=true type=:catch_event semantic=[:catch, \"catch-before-Activity_0wwfenp\"]>]}, \
#<Trailblazer::Workflow::Event::Suspend resumes=[\"catch-before-#{ui_create}\"] type=:suspend semantic=[:suspend, \"suspend-Gateway_14h0q7a\"]>])
    assert_equal ctx.inspect, %({:seq=>[:create_form]})
  end
end
