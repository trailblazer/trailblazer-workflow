require "trailblazer/pro"

module Trailblazer
  module Workflow
    module Task
      class Import < Trailblazer::Activity::Railway
        step Subprocess(Pro::Client::Connect), id: :connect,
          Output(:failure) => End(:failure)
        step :retrieve_document
        fail :error_for_retrieve
        step :store_document

        def retrieve_document(ctx, session:, diagram_slug:, **)
          id_token = session.id_token

          ctx[:response] = response = Faraday.get(
            "#{session.trailblazer_pro_host}/api/v1/diagrams/#{diagram_slug}/export",
            {},
            {'Content-Type'=>'application/json', "Accept": "application/json",
              "Authorization": "Bearer #{id_token}"
            }
          )

          return false unless response.status == 200 # TODO: abstract this for other users, and use "endpoint" paths.

          ctx[:pro_json_document] = ctx[:response].body
        end

        def store_document(ctx, pro_json_document:, target_filename:, **)
          File.write(target_filename, pro_json_document) > 0
        end

        def error_for_retrieve(ctx, response:, diagram_slug:, **)
          ctx[:error_message] = %(Diagram #{diagram_slug.inspect} couldn't be retrieved. HTTP status: #{response.status})
        end
      end

    end # Task
  end
end
