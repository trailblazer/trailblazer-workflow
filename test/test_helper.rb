# frozen_string_literal: true

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
