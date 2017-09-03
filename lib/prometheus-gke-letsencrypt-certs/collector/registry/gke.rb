# encoding: UTF-8

require "httparty"
require "json"

module PrometheusGKELetsEncryptCerts
  class Collector
    module Registry
      module GKE
        def self.token
          File.read("/var/run/secrets/kubernetes.io/serviceaccount/token")
        end

        def self.cacert
          "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
        end

        def self.certificates
          host = ENV["KUBERNETES_SERVICE_HOST"]
          port = ENV["KUBERNETES_PORT_443_TCP_PORT"]
          headers = { "Authorization" => "Bearer #{token}"}

          response = HTTParty.get("https://#{host}:#{port}/api/v1/services", :headers => headers, :ssl_ca_file => cacert)

          json = JSON.parse(response.body)

          json["items"].each_with_object([]) do |item, collection|
            key = %w(metadata annotations acme/certificate)

            next unless item.dig(*key)

            # parse as JSON if value is array
            begin
              values = JSON.parse(item.dig(*key))
            rescue
              values = item.dig(*key)
            end

            collection << values
          end
        end

        def self.defunct_certificates(registry)
          certificate_cache = certificates

          registry.metrics.flat_map do |metric|
            next unless metric.name == :gke_letsencrypt_cert_expiration

            metric.values.flat_map do |gauge, value|
              gauge[:certificate_name] unless certificate_cache.include? gauge[:certificate_name]
            end
          end.delete_if { |e| e.nil? }
        end
      end
    end
  end
end
