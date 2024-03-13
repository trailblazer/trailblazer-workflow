module App::Posting::StateGuards
  Decider = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash(
    {
      "⏸︎ Create form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Create"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Update"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Approve♦Reject"              => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Delete? form♦Publish"        => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Revise form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Delete♦Cancel"               => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Archive"                     => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
      "⏸︎ Revise"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }},
    },
    state_table: StateTable,
  )
end
