# encoding: UTF-8

require "openssl"

module PrometheusGKELetsEncryptCerts
  class Collector
    module Registry
      module SSL
        def self.valid_until(host)
          certificate(host).not_after.to_i
        end

        def self.certificate(host)
          tcp_client = TCPSocket.new(host, 443)
          ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
          ssl_client.hostname = host
          ssl_client.connect
          cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
          ssl_client.sysclose
          tcp_client.close
          cert
        end
      end
    end
  end
end
