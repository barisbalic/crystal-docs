module Crystal::Docs
  module GitHub
    class Client
      class NotFound < Exception; end

      def initialize(token : String)
        @token = token
        @http_client = HTTP::Client.new("api.github.com", tls: true)
      end

      private def get(endpoint : String)
        request("GET", endpoint)
      end

      private def post(endpoint : String, params)
        request("POST", endpoint, params)
      end

      private def put(endpoint : String, params)
        request("PUT", endpoint, params)
      end

      private def delete(endpoint : String)
        request("DELETE", endpoint)
      end

      private def request(method : String, endpoint : String, params = nil)
        raise Exception.new("Not supported verb") unless ["GET", "PUT", "POST", "DELETE"].includes?(method)
        headers = default_headers.add("Content-Type", "application/json")

        if params.nil?
          response = @http_client.exec(method, endpoint, headers: headers)
        else
          response = @http_client.exec(method, endpoint, headers: headers, body: params.to_json)
        end
        raise Exception.new("Token invalid or expired.") if response.status_code == 401
        raise NotFound.new("No resource could be found for the specified ID") if response.status_code == 404

        response.body
      end

      private def default_headers
        HTTP::Headers{"Authorization" => "Bearer #{@token}", "Accept" => "application/vnd.github.v3+json"}
      end

      def repository(owner : String, repository : String)
        response = get("/repos/#{owner}/#{repository}")
        JSON.parse( response )
      end
    end
  end
end
