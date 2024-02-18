module Trailblazer
  module Workflow
    module Discovery
      # Rendering-specific code using {Discovery:states}.
      module Present
        module EventTable
          module_function

          def call(discovered_states, render_ids: true, hide_lanes: [], lanes_cfg:, **)
            rows = discovered_states.flat_map do |row|
              positions_before, start_position = row[:positions_before]

              lane_positions = render_lane_position_columns(positions_before, lanes_cfg: lanes_cfg)

              # The resulting hash represents one row.
              state_row = Hash[
                "triggered event",
                Present.readable_name_for_catch_event(*start_position.to_a, lanes_cfg: lanes_cfg),

                # "triggered catch event",
                # readable_name_for_catch_event(row[:start_position]),

                *lane_positions
              ]

              rows = [
                state_row,
              ]

              # FIXME: use developer for coloring.
              # def bg_gray(str);        "\e[47m#{str}\e[0m" end
              if render_ids
                rows << render_lane_position_id_columns(positions_before, lanes_cfg: lanes_cfg)
              end

              rows
            end


            pp rows
            lane_labels = lanes_cfg.collect { |id, cfg| cfg[:label] }

            lane_labels = lane_labels - hide_lanes # TODO: extract, new feature.

            Hirb::Helpers::Table.render(rows, fields: [
                # "event name",
                "triggered event",
                *lane_labels,
              ],
              max_width: 186,
            ) # 186 for laptop 13"
          end

          # @private
          def render_lane_position_columns(positions_before, **options)
            lane_positions = positions_before.to_a.flat_map do |lane_position|
              lane_label = Present.lane_options_for(*lane_position.to_a, **options)[:label]

              # DISCUSS: extract?
              if lane_position.task.to_h["resumes"].nil? # Terminus.
                readable_lane_position = "◉End.#{lane_position.task.to_h[:semantic]}"
              else
                readable_lane_position = Present.resumes_from_suspend(*lane_position.to_a).collect do |catch_event|
                  Present.readable_name_for_catch_event(lane_position.activity, catch_event, **options)
                end.join(",")
              end

              [
                lane_label,
                readable_lane_position
              ]
            end
          end

          def render_lane_position_id_columns(positions_before, **options)
            lane_position_ids = positions_before.to_a.flat_map do |lane_position|
              # Present.readable_id_label(*lane_position.to_a, **options)
              lane_label = lane_label_for(lane_position, **options) # FIXME: redundant in {#render_lane_position_columns}
              id = Trailblazer::Activity::Introspect.Nodes(lane_position.activity, task: lane_position.task).id

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
      end # Present
    end
  end
end
