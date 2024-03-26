module Trailblazer
  module Workflow
    module Test
      module Plan
        module_function

        # Code fragment with assertions for the discovered/configured test plan.
        def for(iteration_set, input:, **options)
          code_string = iteration_set.collect do |iteration|
            event_label = iteration.event_label

            %(
# test: #{event_label}
ctx = assert_advance "#{event_label}", test_plan: test_plan, schema: schema
assert_exposes ctx, seq: [:revise, :revise], reader: :[]
)
          end
        end

      end

    end # Test
  end
end
