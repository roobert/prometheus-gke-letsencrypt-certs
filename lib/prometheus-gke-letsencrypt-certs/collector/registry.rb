# encoding: UTF-8

module PrometheusGKELetsEncryptCerts
  class Collector
    module Registry
      def self.update(registry, gauge)
        refresh_certificates(gauge)
        purge_defunct_certificates(registry, gauge)
        GKE.cache_clear

        [ registry, gauge ]
      end

      def self.lookup(host)
        valid_until = -1

        labels = {
          certificate_name: host,
          failure:          false,
          error:            "",
        }

        begin
          valid_until = SSL.valid_until(host)
        rescue => e
          labels[:failure] = true
          labels[:error]   = e.to_s
        end

        [labels, valid_until]
      end

      def self.refresh_certificates(gauge)
        GKE.certificate_cache.each do |host|
          labels, valid_until = lookup(host)
          gauge.set(labels, valid_until)
        end
      end

      def self.purge_defunct_certificates(registry, gauge)
        GKE.defunct_certificates(registry).each do |host|
          gauge.values.delete_if { |tags, _| tags[:certificate_name] == host }
        end
      end
    end
  end
end
