#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "rack"
require "prometheus-gke-letsencrypt-certs"

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }

use PrometheusGKELetsEncryptCerts::Collector
use PrometheusGKELetsEncryptCerts::Exporter

run ->(_) { [200, {'Content-Type' => 'text/html'}, ['see /metrics']]  }
