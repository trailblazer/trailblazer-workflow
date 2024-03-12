App::Bla::StateGuards = Trailblazer::Workflow::Collaboration::StateGuards.from_user_hash({
  "⏸︎ Create form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0wc2mcq"]},
  "⏸︎ Create"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1psp91r"]},
  "⏸︎ Update form♦Notify approver" => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1165bw9", "catch-before-Activity_1dt5di5"]},
  "⏸︎ Update"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0j78uzd"]},
  "⏸︎ Approve♦Reject"              => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_13fw5nm", "catch-before-Activity_1j7d8sd"]},
  "⏸︎ Delete? form♦Publish"        => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0bsjggk", "catch-before-Activity_0ha7224"]},
  "⏸︎ Revise form"                 => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0zsock2"]},
  "⏸︎ Delete♦Cancel"               => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_15nnysv", "catch-before-Activity_1uhozy1"]},
  "⏸︎ Archive"                     => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_0fy41qq"]},
  "⏸︎ Revise"                      => {guard: ->(ctx, process_model:, **) { raise "implement me!" }, id: ["catch-before-Activity_1wiumzv"]},
})
