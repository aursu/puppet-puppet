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
    end
  end
end
