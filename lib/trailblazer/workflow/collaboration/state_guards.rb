module Trailblazer
  module Workflow
    class Collaboration
      # Maintains catch events and their particular state guard and allows
      # evaluating the guard using `#call`.
      #
      # This is used in Advance.
      #
      class StateGuards
        # Compile time
        # Note: this is called at every boot-up and needs to be reasonably fast, as we're mapping
        #       catch events to state guards.
        def self.from_user_hash(state_guards_cfg, state_table:)
          # state_2_guard = state_guards_cfg.flat_map do |state_label, user_cfg|
          #   raise state_label.inspect
          #   catch_event_ids = state_table.fetch(state_label)[:id] # raise if we don't know this state label.

          #   catch_event_ids.collect { |catch_id| [catch_id, user_cfg[:guard]] }
          # end

          # TODO: optimize this for runtime.

          guards = StateGuards.new(state_guards_cfg)

          # FIXME: rename this very method!
          State::Resolver.new(guards, state_table)
        end

        def initialize(state_2_guard)
          @state_2_guard = state_2_guard
        end

        def call(state_name, args, **kws) # DISCUSS: do we really need that abstraction here?
          @state_2_guard.fetch(state_name)[:guard].(*args, **kws) # TODO: discuss exec interface
        end
      end
    end # Collaboration
  end
end
