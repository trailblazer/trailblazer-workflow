module Trailblazer
  module Workflow
    module Introspect
      module EventTable
        module_function

        def call(iteration_set, render_ids: true, hide_lanes: [], lanes_cfg:, **)
          rows = iteration_set.to_a.flat_map do |iteration|
            start_positions     = iteration.start_positions
            start_task_position = iteration.start_task_position

            lane_positions = render_lane_position_columns(start_positions, lanes_cfg: lanes_cfg)

            # The resulting hash represents one row.
            state_row = Hash[
              "triggered event",
              Present.readable_name_for_catch_event(*start_task_position.to_a, lanes_cfg: lanes_cfg),

              *lane_positions
            ]

            rows = [
              state_row,
            ]

            # FIXME: use developer for coloring.
            # def bg_gray(str);        "\e[47m#{str}\e[0m" end
            if render_ids
              triggered_event_id_column = {"triggered event" => Present.id_for_position(start_task_position)}

              rows << render_lane_position_id_columns(start_positions, lanes_cfg: lanes_cfg)
                .merge(triggered_event_id_column)
            end

            rows
          end


          lane_labels = lanes_cfg.collect { |id, cfg| cfg[:label] }

          lane_labels = lane_labels - hide_lanes # TODO: extract, new feature.

          columns = ["triggered event", *lane_labels]
          Present::Table.render(columns, rows)
        end

        # @private
        def render_lane_position_columns(start_positions, **options)
          lane_positions = start_positions.to_a.flat_map do |lane_position|
            lane_label = Present.lane_options_for(*lane_position.to_a, **options)[:label]

            readable_lane_position = Present.readable_name_for_suspend_or_terminus(*lane_position.to_a, **options)

            [
              lane_label,
              readable_lane_position
            ]
          end
        end

        def render_lane_position_id_columns(start_positions, **options)
          lane_position_ids = start_positions.to_a.flat_map do |lane_position|
            # Present.readable_id_label(*lane_position.to_a, **options)
            lane_label = lane_label_for(lane_position, **options) # FIXME: redundant in {#render_lane_position_columns}
            id = Present.id_for_position(lane_position)

            [
              lane_label, # column name
              id
            ]
          end

          _id_row = Hash[
            *lane_position_ids, # TODO: this adds the remaining IDs.
          ]
        end


        def lane_label_for(lane_position, **options)
          Present.lane_options_for(*lane_position.to_a, **options)[:label]
        end
      end
    end # Introspect
  end
end
