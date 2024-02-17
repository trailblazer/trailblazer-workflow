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
end
