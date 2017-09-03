# encoding: UTF-8

require "prometheus/client"

require "prometheus-gke-letsencrypt-certs/prometheus"
require "prometheus-gke-letsencrypt-certs/collector"
require "prometheus-gke-letsencrypt-certs/collector/registry"
require "prometheus-gke-letsencrypt-certs/collector/registry/gke"
require "prometheus-gke-letsencrypt-certs/collector/registry/ssl"

module PrometheusGKELetsEncryptCerts
  class Collector
    attr_reader :app, :registry

    def initialize(app)
      @app      = app
      @registry = Prometheus::Client.registry
      @gauge    = @registry.gauge(
        # FIXME: double check that this is actually what we're reporting on 
        # FIXME: why did "test" have a timestamp?
        :gke_letsencrypt_cert_expiration,
        'GKE LetsEncrypt SSL certificate - expiration date (seconds since epoch)',
      )
    end

    def call(env)
      @registry, @gauge = Registry.update(@registry, @gauge)

      @app.call(env)
    end
  end
end
