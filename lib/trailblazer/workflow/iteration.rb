module Trailblazer
  module Workflow
    # An {Iteration} represents the "path" from a triggered event to its suspend configuration of a collaboration.
    # It is usually generated from a discovery process.
    # A {Set} of {Iteration}s comprises of all possible events and outcomes. This is the interface
    # for higher-level tools such as Advance, state tables, test plans or outcome deciders to work with.
    #
    # DISCUSS: maybe the naming/namespace will change.
    #          maybe Introspect::Iteration?
    class Iteration < Struct.new(:id, :event_label, :start_position, :start_positions, :suspend_positions, :outcome)
      class Set
        def self.from_discovered_states(discovered_states, **options)
          iterations = discovered_states.collect do |row|
            triggered_catch_event_position = row[:positions_before][1]

            id          = Discovery::Present.id_for_task(triggered_catch_event_position)
            event_label = Test::Plan::CommentHeader.start_position_label(row[:positions_before][1], row, **options)

            Iteration.new(
              id,
              event_label,
              row[:positions_before][1],
              row[:positions_before][0],
              row[:suspend_configuration].lane_positions,
              row[:outcome],
            )
          end

          Set.new(iterations, **options)
        end

        def initialize(iterations, lanes_cfg:)
          @iterations = iterations
          @lanes_cfg  = lanes_cfg
        end

        # An Iteration::Set is usually serialized to a JSON document, so we don't have
        # to re-run the discovery every time we use the collaboration.
        def to_hash()
          @iterations.collect do |iteration|
            attributes = {
              id: iteration.id,
              event_label: iteration.event_label,
              start_task: Serialize.serialize_position(*iteration.start_position.to_a, lanes_cfg: @lanes_cfg),
              start_positions: Serialize.serialize_suspend_positions(iteration.start_positions, lanes_cfg: @lanes_cfg),
              suspend_positions: Serialize.serialize_suspend_positions(iteration.suspend_positions, lanes_cfg: @lanes_cfg),
              outcome: iteration.outcome,
            }
          end
        end

        module Serialize
          module_function

          def serialize_suspend_positions(start_positions, **options)
            start_positions.collect do |activity, suspend|
              serialize_suspend_position(activity, suspend, **options)
            end
          end

          def id_tuple_for(activity, task, lanes_cfg:)
            activity_id = lanes_cfg.values.find { |cfg| cfg[:activity] == activity }[:label]
            task_id = Trailblazer::Activity::Introspect.Nodes(activity, task: task).id

            return activity_id, task_id
          end

          # A lane position is always a {Suspend} (or a terminus).
          def self.serialize_suspend_position(activity, suspend, **options)
            position_tuple = id_tuple_for(activity, suspend, **options) # usually, this is a suspend. sometimes a terminus {End}.

            comment =
              if suspend.to_h["resumes"].nil? # FIXME: for termini.
                comment = [:terminus, suspend.to_h[:semantic]]
              else
                [:before, Discovery::Present.readable_name_for_suspend_or_terminus(activity, suspend, **options)]
              end

            {
              tuple: position_tuple,
              comment: comment,
            }
          end

          # TODO: merge with serialize_suspend_position.
          def serialize_position(activity, catch_event, **options)
            position_tuple = id_tuple_for(activity, catch_event, **options)

            comment = [:before, Discovery::Present.readable_name_for_catch_event(activity, catch_event, **options)]

            {
              tuple: position_tuple,
              comment: comment,
            }
          end
        end
      end
    end # Iteration
  end
end
