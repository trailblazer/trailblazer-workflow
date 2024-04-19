require "test_helper"

class StructuresTest < Minitest::Spec
  it "Collaboration::Positions" do
    activity_a = "A"
    suspend_a  = "suspend:a"
    activity_b = "B"
    suspend_b = "suspend:b"

    #@ Position.new
    position_a = Trailblazer::Workflow::Collaboration::Position.new(activity_a, suspend_a)
    position_b = Trailblazer::Workflow::Collaboration::Position.new(activity_b, suspend_b)

    #@ Position#to_a
    assert_equal position_a.to_a.inspect, %(["A", "suspend:a"])

    #@ Positions.new
    positions = Trailblazer::Workflow::Collaboration::Positions.new([position_a, position_b])

    #@ Positions.collect automatically decomposes each iterated position.
    assert_equal positions.collect { |activity, task| [activity, task] }.inspect, %([[\"A\", \"suspend:a\"], [\"B\", \"suspend:b\"]])

    #@ Positions#replace
    positions = positions.replace(activity_a, "suspend:c")
    # DISCUSS: check how the interal order is now different!
    assert_equal positions.collect { |activity, task| [activity, task] }.inspect, %([[\"A\", \"suspend:c\"], [\"B\", \"suspend:b\"]])
  end

  it "Positions#==" do
    activity_a = "A"
    suspend_a  = "suspend:a"
    activity_b = "B"
    suspend_b = "suspend:b"

    position_a = Trailblazer::Workflow::Collaboration::Position.new(activity_a, suspend_a)
    position_b = Trailblazer::Workflow::Collaboration::Position.new(activity_b, suspend_b)
    positions = Trailblazer::Workflow::Collaboration::Positions.new([position_a, position_b])

    position_a_2 = Trailblazer::Workflow::Collaboration::Position.new(activity_a, suspend_a)
    position_b_2 = Trailblazer::Workflow::Collaboration::Position.new(activity_b, suspend_b)
    positions_2 = Trailblazer::Workflow::Collaboration::Positions.new([position_a_2, position_b_2])

    #@ Position#==
    assert position_a == position_a_2
    #@ Position#hash for keying in hashes
    assert_equal position_a.hash, position_a_2.hash

    #@ Positions#==
    assert positions == positions_2

    #@ changed position order # DISCUSS: should we allow that in the first place?
    assert positions == Trailblazer::Workflow::Collaboration::Positions.new([position_b, position_a])

    #@ Positions with same Position configuration look identical in hashes.
    some_hash = {positions => true}
    assert_equal some_hash[positions], true
    assert_equal some_hash[positions_2], true
  end

  it "Introspect::Lanes" do
    lane_activity = Module.new
    lane_activity_ui = Class.new

    lanes_cfg = Trailblazer::Workflow::Introspect::Lanes.new(
      lanes_data =
      {
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
      }
    )

    assert_equal lanes_cfg.(json_id: "article moderation")[:activity], lane_activity
    assert_equal lanes_cfg.(activity: lane_activity_ui)[:label], "UI"
    assert_equal lanes_cfg.(activity: lane_activity_ui)[:icon], "☝"

    assert_equal lanes_cfg.(label: "UI")[:activity], lane_activity_ui

    exception = assert_raises RuntimeError do
      lanes_cfg.(label: nil)[:activity]
    end
    assert_equal exception.message, %(:label == nil not found)


    assert_equal lanes_cfg.to_h.inspect,
      %({#{lane_activity.inspect}=>{:label=>"lifecycle", :icon=>"⛾", :activity=>#{lane_activity.inspect}, :json_id=>"article moderation"}, #{lane_activity_ui.inspect}=>{:label=>"UI", :icon=>"☝", :activity=>#{lane_activity_ui.inspect}, :json_id=>\"<ui> author workflow\"}})
    # assert_equal lanes_cfg.json_id("article moderatoin")[:activity], lane_activity
  end
end
