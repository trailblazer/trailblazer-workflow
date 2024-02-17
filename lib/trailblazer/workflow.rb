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
require "trailblazer/workflow/state/discovery"
require "trailblazer/workflow/state/discovery/testing"
require "trailblazer/workflow/state/table"

require "trailblazer/workflow/test/plan"

require "trailblazer/workflow/discovery"
require "trailblazer/workflow/discovery/present"
require "trailblazer/workflow/discovery/present/state_table"
require "trailblazer/workflow/discovery/present/event_table"
