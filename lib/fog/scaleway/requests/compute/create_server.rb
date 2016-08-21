module Fog
  module Scaleway
    class Compute
      class Real
        def create_server(name, image, volumes, options = {})
          body = {
            organization: @organization,
            name: name,
            image: image,
            volumes: volumes
          }

          body.merge!(options)

          create('/servers', body)
        end
      end

      class Mock
        def create_server(name, image, volumes, options = {})
          body = {
            organization: @organization,
            name: name,
            image: image,
            volumes: volumes
          }

          body.merge!(options)

          body = jsonify(body)

          image = lookup(:images, body['image'])

          creation_date = now

          volumes = {}
          body['volumes'].each do |index, volume|
            volume = lookup(:volumes, volume['id'])

            if volume['server']
              message = "volume #{volume['id']} is already attached to a server"
              raise_invalid_request_error(message)
            end

            volumes[index] = volume
          end

          root_volume = image['root_volume']
          volumes['0'] = {
            'size' => root_volume['size'],
            'name' => root_volume['name'],
            'modification_date' => creation_date,
            'organization' => body['organization'],
            'export_uri' => nil,
            'creation_date' => creation_date,
            'id' => Fog::UUID.uuid,
            'volume_type' => root_volume['volume_type'],
            'server' => nil
          }

          public_ip = nil
          if body['public_ip']
            public_ip = lookup(:ips, body['public_ip'])

            public_ip = {
              'dynamic' => false,
              'id' => public_ip['id'],
              'address' => public_ip['address']
            }
          end

          dynamic_ip_required = !public_ip && body.fetch('dynamic_ip_required', true)

          default_bootscript_id = image['default_bootscript']['id']
          bootscript_id = body.fetch('bootscript', default_bootscript_id)
          bootscript = lookup(:bootscripts, bootscript_id)

          if body['security_group']
            security_group = lookup(:security_groups, body['security_group'])
          else
            security_group = default_security_group
            security_group ||= create_default_security_group
          end

          server = {
            'arch' => image['arch'],
            'bootscript' => bootscript,
            'commercial_type' => body.fetch('commercial_type', 'C1'),
            'creation_date' => creation_date,
            'dynamic_ip_required' => dynamic_ip_required,
            'enable_ipv6' => body.fetch('enable_ipv6', false),
            'extra_networks' => [],
            'hostname' => body['name'],
            'id' => Fog::UUID.uuid,
            'image' => image,
            'ipv6' => nil,
            'location' => nil,
            'modification_date' => creation_date,
            'name' => body['name'],
            'organization' => body['organization'],
            'private_ip' => nil,
            'public_ip' => public_ip,
            'security_group' => {
              'id' => security_group['id'],
              'name' => security_group['name']
            },
            'state' => 'stopped',
            'state_detail' => '',
            'tags' => body.fetch('tags', []),
            'volumes' => volumes
          }

          data[:servers][server['id']] = server

          data[:volumes][server['volumes']['0']['id']] = server['volumes']['0']

          server['volumes'].each do |_index, volume|
            volume['server'] = {
              'id' => server['id'],
              'name' => server['name']
            }
          end

          response(status: 201, body: { 'server' => server })
        end
      end
    end
  end
end
