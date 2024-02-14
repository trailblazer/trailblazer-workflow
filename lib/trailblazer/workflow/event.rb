module Trailblazer
  module Workflow
    class Event < Activity::End
      class Suspend < Event
      end

      class Throw < Event
        def call((ctx, flow_options), **circuit_options)
          flow_options = flow_options.merge(
            throw: flow_options[:throw] + [[self, "message"]] # DISCUSS: what message do we want to pass on?
          )

          return Activity::Right, [ctx, flow_options]
        end
      end # Throwing

      class Catch < Event
        def call((ctx, flow_options), **circuit_options)
          return Activity::Right, [ctx, flow_options]
        end
      end # Catching
    end
  end
end
