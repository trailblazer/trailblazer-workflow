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
    assert_equal positions.collect { |activity, task| [activity, task] }.inspect, %([[\"B\", \"suspend:b\"], [\"A\", \"suspend:c\"]])
  end
end
