module Fog
  module Scaleway
    class Compute
      class Real
        def update_user_data(server_id, key, value)
          request(method: :patch,
                  path: "/servers/#{server_id}/user_data/#{key}",
                  headers: { 'Content-Type' => 'text/plain' },
                  body: value,
                  expects: [204])
        end
      end
    end
  end
end