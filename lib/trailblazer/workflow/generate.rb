require "representable/json"
require "ostruct"
require "trailblazer/macro"

module Trailblazer
  module Workflow
    # Computes a {Intermediate} data structures for every lane from a TRB PRO/editor .json file.
    class Generate < Trailblazer::Activity::Railway
      Element = Struct.new(:id, :type, :data, :links, :label)
      Link    = Struct.new(:target_id, :semantic)

      module Representer
        class Collaboration < Representable::Decorator  # Called {structure}.
          include Representable::JSON

          property :id
          collection :lanes, class: OpenStruct do
            property :id
            collection :elements, class: Element do
              property :id
              property :label
              property :type,
                parse_filter: ->(fragment, options) { fragment.to_sym }
              property :data #, default: {}
              collection :links, class: Link do
                property :target_id
                property :semantic,
                  parse_filter: ->(fragment, options) { fragment.to_sym }
              end
            end
          end
          collection :messages
        end
      end # Representer

      def self.transform_from_json(ctx, json_document:, parser: Representer::Collaboration, **)
        ctx[:structure] = parser.new(OpenStruct.new).from_json(json_document) # DISCUSS: this could be sitting in PRO?
      end

      def lanes(ctx, structure:, **)
        structure.lanes
      end

      def self.find_start_event(ctx, lane:, **)
        ctx[:start_event] = lane.elements.find { |el| el.id == "Start" }
      end

      # In the PRO JSON, usually a catch event is marked as {start_task: true}.
      def self.default_start_event(ctx, lane:, **)
        ctx[:start_event] = lane.elements.find { |node| node.data["start_task"] } || raise("no default start event found") # TODO: raise not tested.
      end

      def self.compute_termini_map(ctx, lane:, **)
        terminus_nodes = lane.elements
          .find_all { |node| node.type == :terminus }
          .collect { |node| [node.id, node.id.to_sym] } # {"success" => :success}

        suspend_nodes = lane.elements
          .find_all { |node| node.type == :suspend }
          .collect { |node| [node.id, :suspend] }

        ctx[:termini_map] = (terminus_nodes + suspend_nodes).to_h
      end

      def self.compile_intermediate(ctx, lane:, start_event:, termini_map:, **)
        wirings = lane.elements.collect do |node|
          data = (node.data || {})
            .merge(type: node.type)

          data.merge!(label: node.label) if node.label

          [
            Activity::Schema::Intermediate.TaskRef(node.id,
              data
            ),

            node.links.collect do |link|
              Activity::Schema::Intermediate.Out(link.semantic, link.target_id)
            end
          ]
        end.to_h

        intermediate = Activity::Schema::Intermediate.new(
          wirings,
          termini_map,    # {"success"=>:success, "suspend-d15ef8ea-a55f-4eed-a0e8-37f717d21c2f"=>:suspend}
          start_event.id  # start
        )

        ctx[:value] = [lane.id, intermediate]
      end

      step Generate.method(:transform_from_json),     id: :transform_from_json
      step Each(dataset_from: :lanes, item_key: :lane, collect: true) {
        step Generate.method(:find_start_event),      id: :find_start_event
        fail Generate.method(:default_start_event),   id: :default_start_event,
          Output(:success) => Track(:success)
        step Generate.method(:compute_termini_map),   id: :compute_termini_map
        step Generate.method(:compile_intermediate),  id: :compute_intermediate
      }, Out() => ->(ctx, collected_from_each:, **) { {intermediates: collected_from_each.to_h} } #{:collected_from_each => :intermediates}
    end
  end
end
