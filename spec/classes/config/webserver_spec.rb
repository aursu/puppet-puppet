# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::config::webserver' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/webserver.conf')
          .with_content(%r{ssl-cert: /etc/puppetlabs/puppet/ssl/certs/.*\.pem})
          .with_content(%r{ssl-key: /etc/puppetlabs/puppet/ssl/private_keys/.*\.pem})
          .with_content(%r{ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
          .with_content(%r{ssl-cert-chain: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
          .with_content(%r{ssl-crl-path: /etc/puppetlabs/puppet/ssl/crl.pem})
      }
    end
  end
end