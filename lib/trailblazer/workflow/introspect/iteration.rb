module Trailblazer
  module Workflow
    module Introspect
      # An {Iteration} represents the "path" from a triggered event to its suspend configuration of a collaboration.
      # It is usually generated from a discovery process.
      # A {Set} of {Iteration}s comprises of all possible events and outcomes. This is the interface
      # for higher-level tools such as Advance, state tables, test plans or outcome deciders to work with.
      # While this set can be auto-discovered, it technically could be hand-crafted, but, why?
      #
      # DISCUSS: maybe the naming/namespace will change.
      #          maybe Introspect::Iteration?
      class Iteration < Struct.new(:id, :event_label, :start_task_position, :start_positions, :suspend_positions, :outcome)
        class Set
          def self.from_discovered_states(discovered_states, **options)
            iterations = discovered_states.collect do |row|
              triggered_catch_event_position = row[:positions_before][1]

              id          = Introspect::Present.id_for_position(triggered_catch_event_position)
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

          def to_a
            # FIXME: remove?
            @iterations
          end

          def collect(&block)
            @iterations.collect(&block)
          end

          module Serialize
            module_function

            # An Iteration::Set is usually serialized to a JSON document, so we don't have
            # to re-run the discovery every time we use the collaboration.
            def call(iterations, **options)
              iterations.to_a.collect do |iteration|
                attributes = {
                  id: iteration.id,
                  event_label: iteration.event_label,
                  start_task_position: Serialize.serialize_position(*iteration.start_task_position.to_a, **options),
                  start_positions: Serialize.serialize_suspend_positions(iteration.start_positions, **options),
                  suspend_positions: Serialize.serialize_suspend_positions(iteration.suspend_positions, **options),
                  outcome: iteration.outcome,
                }
              end
            end

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
                  [:before, Introspect::Present.readable_name_for_suspend_or_terminus(activity, suspend, **options)]
                end

              {
                tuple: position_tuple,
                comment: comment,
              }
            end

            # TODO: merge with serialize_suspend_position.
            def serialize_position(activity, catch_event, **options)
              position_tuple = id_tuple_for(activity, catch_event, **options)

              comment = [:before, Introspect::Present.readable_name_for_catch_event(activity, catch_event, **options)]

              {
                tuple: position_tuple,
                comment: comment,
              }
            end
          end

          module Deserialize
            module_function

            def call(structure, lanes_cfg:)
              iterations = structure.collect do |attributes|
                label_2_activity = lanes_cfg.values.collect { |cfg| [cfg[:label], cfg[:activity]] }.to_h

                Iteration.new(
                  attributes["id"],
                  attributes["event_label"],
                  position_from_tuple(*attributes["start_task_position"]["tuple"], label_2_activity: label_2_activity),
                  positions_from(attributes["start_positions"], label_2_activity: label_2_activity),
                  positions_from(attributes["suspend_positions"], label_2_activity: label_2_activity),
                  attributes["outcome"],
                )
              end

              Iteration::Set.new(iterations, lanes_cfg: lanes_cfg)
            end

            # "Deserialize" a {Position} from a serialized tuple.
            # Opposite of {#id_tuple_for}.
            def position_from_tuple(lane_label, task_id, label_2_activity:)
              lane_activity = label_2_activity[lane_label]
              task = Trailblazer::Activity::Introspect.Nodes(lane_activity, id: task_id).task

              Collaboration::Position.new(lane_activity, task)
            end

            def positions_from(positions, **options)
              Collaboration::Positions.new(
                positions.collect { |attributes| position_from_tuple(*attributes["tuple"], **options) }
              )
            end
          end
        end
      end # Iteration
    end
  end
end
