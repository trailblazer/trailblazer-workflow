require_relative "workflow/version"

module Trailblazer
  module Workflow
    # Your code goes here...
  end
end

require "trailblazer/workflow/generate"
require "trailblazer/workflow/collaboration"
require "trailblazer/workflow/collaboration/lane"
require "trailblazer/workflow/collaboration/messages"
require "trailblazer/workflow/event"

require "trailblazer/workflow/test/plan"
require "trailblazer/workflow/test/assertions"

require "trailblazer/workflow/discovery"
require "terminal-table" # TODO: only require when discovery is "loaded".
require "trailblazer/workflow/introspect"
require "trailblazer/workflow/introspect/iteration"
require "trailblazer/workflow/introspect/state_table"
require "trailblazer/workflow/introspect/event_table"
