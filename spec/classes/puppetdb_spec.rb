# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::puppetdb' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_class('puppetdb')
          .with(
            ssl_protocols: 'TLSv1.2,TLSv1.3',
            cipher_suites: %w[
              TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
              TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
              TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
              TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
              TLS_DHE_RSA_WITH_AES_256_GCM_SHA384
              TLS_DHE_RSA_WITH_AES_128_GCM_SHA256
            ].join(','),
          )
      }

      it {
        is_expected.to contain_class('lsys_postgresql')
      }

      # client-auth stays unmanaged unless opted into, so Jetty keeps its own default.
      it {
        is_expected.not_to contain_ini_setting('puppetdb_ssl_client_auth')
      }

      # The binding deliberately departs from upstream: loopback by default, so the
      # port is never offered to the network without someone asking for it.
      it {
        is_expected.to contain_class('puppetdb')
          .with(ssl_listen_address: '127.0.0.1')
      }

      context 'without local Postgres server' do
        let(:params) do
          {
            manage_database: false,
          }
        end

        it {
          is_expected.not_to contain_class('lsys_postgresql')
        }
      end

      context 'with ssl_client_auth => need' do
        let(:params) do
          {
            ssl_client_auth: 'need',
          }
        end

        it { is_expected.to compile }

        # The ordering is the part worth asserting: after the jetty class so the file
        # exists, notifying the service so the change takes effect. Requiring the whole
        # puppetdb class instead would deadlock on the contained service.
        it {
          is_expected.to contain_ini_setting('puppetdb_ssl_client_auth')
            .with(
              ensure: 'present',
              path: '/etc/puppetlabs/puppetdb/conf.d/jetty.ini',
              section: 'jetty',
              setting: 'ssl-client-auth',
              value: 'need',
            )
            .that_requires('Class[puppetdb::server::jetty]')
            .that_notifies('Service[puppetdb]')
        }
      end

      context 'with ssl_client_auth => none' do
        let(:params) do
          {
            ssl_client_auth: 'none',
          }
        end

        it {
          is_expected.to contain_ini_setting('puppetdb_ssl_client_auth')
            .with_value('none')
        }
      end

      context 'with an unsupported ssl_client_auth' do
        let(:params) do
          {
            ssl_client_auth: 'required',
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{ssl_client_auth})
        }
      end

      # The escape hatch for a split topology — PuppetDB on its own host, where the
      # Puppet Server reaches it over the network and loopback would break it.
      context 'with ssl_listen_address restored to the upstream default' do
        let(:params) do
          {
            ssl_listen_address: '0.0.0.0',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_class('puppetdb')
            .with(ssl_listen_address: '0.0.0.0')
        }
      end

      context 'with ssl_listen_address on a LAN address' do
        let(:params) do
          {
            ssl_listen_address: '192.0.2.10',
          }
        end

        it {
          is_expected.to contain_class('puppetdb')
            .with(ssl_listen_address: '192.0.2.10')
        }
      end

      context 'with an invalid ssl_listen_address' do
        let(:params) do
          {
            ssl_listen_address: 'not-an-address',
          }
        end

        it {
          is_expected.to compile.and_raise_error(%r{ssl_listen_address})
        }
      end

      # The posture as deployed: a profile opts into client-auth, and the binding comes
      # from the module default. Loopback keeps the port off the network; requiring a
      # client certificate covers the case where the binding is ever widened.
      context 'with client-auth opted in and the default binding' do
        let(:params) do
          {
            ssl_client_auth: 'need',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_ini_setting('puppetdb_ssl_client_auth')
            .with_value('need')
        }

        it {
          is_expected.to contain_class('puppetdb')
            .with(ssl_listen_address: '127.0.0.1')
        }
      end
    end
  end
end
