require "json"
require "http"

require "assently/serializers/case_serializer"

module Assently
  class Client
    attr_reader :api_key, :api_secret

    attr_accessor :environment

    def initialize api_key, api_secret, environment = :production
      @api_key = api_key
      @api_secret = api_secret
      self.environment = environment
    end

    def create_case signature_case, options = {}
      signature_case_json = Assently::Serializers::CaseSerializer.serialize signature_case, options

      post "/api/v2/createcase", signature_case_json
    end

    def send_case id
      post "/api/v2/sendcase", JSON.pretty_generate({ id: id })
    end

    def get_case id
      get "/api/v2/getcase", { id: id }
    end

    def find_cases options = {}
      get "/api/v2/findcases", options
    end

    def get_document_data case_id, document_id
      get "/api/v2/getdocumentdata", { "caseId" => case_id, "documentId" => document_id }
    end

    # Method to create case from template
    def create_case_from_template options = {}
      post "/api/v2/createcasefromtemplate", options.to_json
    end

    def send_case id
      post "/api/v2/sendcase", JSON.pretty_generate({ id: id })
    end

    # Method to update case
    def update_case options = {}
      post "/api/v2/updatecase", options.to_json
    end

    # Method to recall a case
    def recall_case id
      post "/api/v2/recallcase", JSON.pretty_generate({ id: id })
    end

    # Method to delete a case
    def delete_case id
      post "/api/v2/deletecase", JSON.pretty_generate({ id: id })
    end

    def post api_command, body = nil
      make_response make_post(api_command, body)
    end

    def get api_command, parameters = {}
      make_response make_get(api_command, parameters)
    end

    def host
      hosts.fetch(self.environment, hosts[:production])
    end

    def connection
      HTTP.
        headers(accept: "application/json").
        basic_auth(user: api_key, pass: api_secret)
    end

    def headers
      connection.headers
    end

    private

    def api_base_url
      "https://#{host}"
    end

    def api_url path
      URI.join(api_base_url, path)
    end

    def make_response response
      if response.status.success?
        SuccessResult.new response.body.to_s
      else
        ErrorResult.new response.body.to_s
      end
    end

    def make_post path, body
      connection.
        headers(content_type: "application/json; charset=utf-8").
        post api_url(path), body: body
    end

    def make_get path, parameters
      connection.get api_url(path), params: parameters
    end

    def hosts
      {
        production: "app.assently.com",
        test: "test.assently.com"
      }
    end

    class SuccessResult
      attr_reader :raw

      def initialize response
        @raw = response
      end

      def response
        begin
          JSON.parse raw
        rescue JSON::ParserError
          raw
        end
      end

      def success?
        true
      end
    end

    class ErrorResult
      attr_reader :raw

      def initialize response
        @raw = response
      end

      def errors
        begin
          Array(JSON.parse(raw)["error"].values.join(" "))
        rescue JSON::ParserError
          raw
        end
      end

      def success?
        false
      end
    end
  end
end
