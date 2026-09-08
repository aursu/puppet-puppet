# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::config::webserver' do
  let(:pre_condition) { 'include puppet' }
  let(:conf_file) { '/etc/puppetlabs/puppetserver/conf.d/webserver.conf' }

  # A private address, because ssl_host now defaults to one and the class fails
  # closed without it. Merged into the OS fact set rather than replacing it -
  # `networking` also carries fqdn, which the rest of the module needs.
  let(:private_networking) do
    {
      'ip' => '10.154.5.6',
      'interfaces' => {
        'lo' => { 'ip' => '127.0.0.1' },
        'eth0' => { 'ip' => '10.154.5.6' },
      },
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(networking: os_facts[:networking].merge(private_networking)) }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file(conf_file)
          .with_content(%r{ssl-cert: /etc/puppetlabs/puppet/ssl/certs/.*\.pem})
          .with_content(%r{ssl-key: /etc/puppetlabs/puppet/ssl/private_keys/.*\.pem})
          .with_content(%r{ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
          .with_content(%r{ssl-cert-chain: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
          .with_content(%r{ssl-crl-path: /etc/puppetlabs/puppet/ssl/crl.pem})
      }

      context 'by default' do
        # No wildcard: the default is this host's first private address. Binding
        # 0.0.0.0 would put the fleet's control plane on every interface the host
        # has, including any added later.
        it { is_expected.to contain_file(conf_file).without_content(%r{ssl-host: 0\.0\.0\.0}) }

        # The host's first private address, chosen via puppet::globals.
        it { is_expected.to contain_file(conf_file).with_content(%r{^\s*ssl-host: 10\.154\.5\.6$}) }

        it {
          is_expected.to contain_file(conf_file)
            .with_content(%r{^\s*ssl-port: 8140$})
            .with_content(%r{^\s*client-auth: want$})
        }

        # No plain HTTP listener unless TLS is deliberately offloaded.
        it { is_expected.to contain_file(conf_file).without_content(%r{^\s*host:}) }
        it { is_expected.to contain_file(conf_file).without_content(%r{^\s*port:}) }
      end

      context 'with a restricted bind address' do
        let(:params) { { ssl_host: '127.0.0.1', ssl_port: 8141, client_auth: 'need' } }

        it {
          is_expected.to contain_file(conf_file)
            .with_content(%r{^\s*ssl-host: 127\.0\.0\.1$})
            .with_content(%r{^\s*ssl-port: 8141$})
            .with_content(%r{^\s*client-auth: need$})
        }
      end

      context 'with tls_offload => true' do
        let(:params) { { tls_offload: true } }

        it { is_expected.to compile }

        # Plain HTTP on loopback: the proxy owns TLS from here on.
        it {
          is_expected.to contain_file(conf_file)
            .with_content(%r{^\s*host: 127\.0\.0\.1$})
            .with_content(%r{^\s*port: 8140$})
        }

        # Every SSL directive must be gone. Leaving one behind would mean Puppet
        # Server still negotiating TLS on a listener the proxy speaks plain HTTP
        # to, which fails in a way that looks like a certificate problem.
        it {
          is_expected.to contain_file(conf_file)
            .without_content(%r{^\s*ssl-host:})
            .without_content(%r{^\s*ssl-port:})
            .without_content(%r{^\s*ssl-cert:})
            .without_content(%r{^\s*ssl-key:})
            .without_content(%r{^\s*ssl-ca-cert:})
            .without_content(%r{^\s*ssl-crl-path:})
            .without_content(%r{^\s*client-auth:})
        }
      end

      context 'on a host with no private address and no ssl_host' do
        # Merged into the OS fact set: networking also carries fqdn and friends.
        let(:facts) do
          os_facts.merge(networking: os_facts[:networking].merge(
                                       'ip' => '203.0.113.10',
                                       'interfaces' => { 'lo' => { 'ip' => '127.0.0.1' },
                                                         'eth0' => { 'ip' => '203.0.113.10' } },
                                     ))
        end

        # Fails rather than falling back to a wildcard.
        it { is_expected.to compile.and_raise_error(%r{no ssl_host given}) }
      end

      context 'with tls_offload => true and a non-default internal endpoint' do
        let(:params) { { tls_offload: true, host: '127.0.0.1', port: 18_140 } }

        it {
          is_expected.to contain_file(conf_file)
            .with_content(%r{^\s*host: 127\.0\.0\.1$})
            .with_content(%r{^\s*port: 18140$})
        }
      end
    end
  end
end
