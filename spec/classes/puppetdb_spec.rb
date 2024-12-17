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
    end
  end
end
