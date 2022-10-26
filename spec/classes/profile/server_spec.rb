# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_class('puppetdb')
          .with(
            ssl_protocols: 'TLSv1.2,TLSv1.3',
            cipher_suites: [
                              'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256',
                              'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256',
                              'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384',
                              'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384',
                              'TLS_DHE_RSA_WITH_AES_256_GCM_SHA384',
                              'TLS_DHE_RSA_WITH_AES_128_GCM_SHA256'
                            ].join(',')
          )
      }

      it {
        is_expected.to contain_class('puppetdb::master::config')
          .with(
            puppetdb_server: 'puppet',
          )
      }

      context 'with custom PuppetDB server' do
        let(:params) do
          {
            puppetdb_server: 'puppet-db.domaiin.tld',
          }
        end

        it {
          is_expected.to contain_class('puppetdb::master::config')
            .with(
              puppetdb_server: 'puppet-db.domaiin.tld',
            )
        }
      end

      context 'without local PuppetDB server' do
        let(:params) do
          {
            puppetdb_local: false,
          }
        end

        it {
          is_expected.to contain_class('puppetdb::master::config')
        }

        it {
          is_expected.not_to contain_class('puppetdb')
        }
      end
    end
  end
end
