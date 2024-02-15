$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "trailblazer/workflow"

require "minitest/autorun"
require "pp"
require "trailblazer/activity/testing"

class Minitest::Spec
  def assert_equal(expected, asserted, *args)
    super(asserted, expected, *args)
  end
end

module BuildSchema
  def build_schema()
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

    implementing = Trailblazer::Activity::Testing.def_steps(:create_form, :ui_create, :update_form, :ui_update, :notify_approver, :reject, :approve, :revise, :publish, :archive, :delete, :delete_form, :cancel, :revise_form,
      :create_form_with_errors, :update_form_with_errors, :revise_form_with_errors)

    lane_activity_ui = Trailblazer::Workflow::Collaboration.Lane(
      article_moderation_intermediate,

      "Create form" => implementing.method(:create_form),
      "Create" => implementing.method(:ui_create),
      "Update form" => implementing.method(:update_form),
      "Update" => implementing.method(:ui_update),
      "Notify approver" => implementing.method(:notify_approver),
      "Publish" => implementing.method(:publish),
      "Delete" => implementing.method(:delete),
      "Delete? form" => implementing.method(:delete_form),
      "Cancel" => implementing.method(:cancel),
      "Revise" => implementing.method(:revise),
      "Revise form" => implementing.method(:revise_form),
      "Create form with errors" => implementing.method(:create_form_with_errors),
      "Update form with errors" => implementing.method(:update_form_with_errors),
      "Revise form with errors" => implementing.method(:revise_form_with_errors),
      "Archive" => implementing.method(:archive),
      # "Approve" => implementing.method(:approve),
      # "Reject" => implementing.method(:reject),
    )

    # TODO: move this into the Schema-build process.
    # This is needed to translate the JSON message structure to Ruby,
    # where we reference lanes by their {Activity} instance.
    json_id_to_lane = {
      "article moderation"    => lane_activity,
      "<ui> author workflow"  => lane_activity_ui,
    }

    # lane_icons: lane_icons = {"UI" => "☝", "lifecycle" => "⛾", "approver" => "☑"},
    lanes_cfg = {
      "article moderation"    => {
        label: "lifecycle",
        icon:  "⛾",
        activity: lane_activity, # this is copied here after the activity has been compiled in {Schema.build}.
      },
      "<ui> author workflow"  => {
        label: "UI",
        icon:  "☝",
        activity: lane_activity_ui,
      },
      # TODO: add editor/approver lane.
    }

    # pp ctx[:structure].lanes
    message_flow = Trailblazer::Workflow::Collaboration.Messages(
      ctx[:structure].messages,
      json_id_to_lane
    )

    # DISCUSS: {lanes} is always ID to activity?
    lanes = {
      lifecycle:  lane_activity,
      ui:         lane_activity_ui,
    }

    approver_activity, extended_message_flow, extended_initial_lane_positions = build_custom_editor_lane(lanes, message_flow)

    lanes = lanes.merge(approver: approver_activity)

    schema = Trailblazer::Workflow::Collaboration::Schema.new(
      lanes: lanes,
      message_flow: message_flow,
    )

    return schema, lanes, extended_message_flow, extended_initial_lane_positions
  end

  # DISCUSS: this is mostly to play around with the "API" of building a Collaboration.
  def build_custom_editor_lane(lanes, message_flow)
    approve_id = "Activity_1qrkaz0"
    reject_id = "Activity_0d9yewp"

    lifecycle_activity = lanes[:lifecycle]

    missing_throw_from_notify_approver = Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "throw-after-Activity_0wr78cv").task

    decision_is_approve_throw = nil
    decision_is_reject_throw  = nil

    approver_start_suspend = nil
    approver_activity = Class.new(Trailblazer::Activity::Railway) do
      step task: approver_start_suspend = Trailblazer::Workflow::Event::Suspend.new(semantic: "invented_semantic", "resumes" => ["catch-before-decider-xxx"]), id: "~suspend~"

      fail task: Trailblazer::Workflow::Event::Catch.new(semantic: "xxx --> decider"), id: "catch-before-decider-xxx", Output(:success) => Track(:failure)
      fail :decider, id: "xxx",
        Output(:failure) => Trailblazer::Activity::Railway.Id("xxx_reject")
      fail task: decision_is_approve_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_approve")

      step task: decision_is_reject_throw = Trailblazer::Workflow::Event::Throw.new(semantic: "xxx_reject"),
        magnetic_to: :reject, id: "xxx_reject"

      def decider(ctx, decision: true, **)
        # raise if !decision

        decision
      end
    end

    extended_message_flow = message_flow.merge(
      # "throw-after-Activity_0wr78cv"
      missing_throw_from_notify_approver => [approver_activity, Trailblazer::Activity::Introspect.Nodes(approver_activity, id: "catch-before-decider-xxx").task],
      decision_is_approve_throw => [lifecycle_activity, Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "catch-before-#{approve_id}").task],
      decision_is_reject_throw => [lifecycle_activity, Trailblazer::Activity::Introspect.Nodes(lifecycle_activity, id: "catch-before-#{reject_id}").task],
    )

    initial_lane_positions = Trailblazer::Workflow::Collaboration::Synchronous.initial_lane_positions(lanes) # we need to do this manually here, as initial_lane_positions isn't part of the {Schema.build} process.
    extended_initial_lane_positions = initial_lane_positions.merge(
      approver_activity => approver_start_suspend
    )
    extended_initial_lane_positions = Trailblazer::Workflow::Collaboration::Positions.new(extended_initial_lane_positions.collect { |activity, task| Trailblazer::Workflow::Collaboration::Position.new(activity, task) })

    return approver_activity, extended_message_flow, extended_initial_lane_positions
  end
end
