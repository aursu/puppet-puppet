# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::ca::generate' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec('backup /etc/puppetlabs/puppet/ssl/certs/puppetserver1.domain.tld.pem')
      }

      it {
        is_expected.to contain_exec('backup /etc/puppetlabs/puppet/ssl/private_keys/puppetserver1.domain.tld.pem')
      }

      it {
        is_expected.to contain_exec('backup /etc/puppetlabs/puppet/ssl/public_keys/puppetserver1.domain.tld.pem')
      }

      it {
        is_expected.to contain_exec('backup /etc/puppetlabs/puppetserver/ca/signed/puppetserver1.domain.tld.pem')
      }

      it {
        is_expected.to contain_exec('puppetserver ca generate')
          .with(
            command: 'puppetserver ca generate --force --ca-client --certname puppetserver1.domain.tld --subject-alt-names puppet,puppetserver1.domain.tld --ttl 10y',
            unless: 'openssl x509 -in /etc/puppetlabs/puppet/ssl/certs/puppetserver1.domain.tld.pem -checkend 0',
          )
          .that_requires('Exec[stop puppetserver]')
      }

      it {
        is_expected.to contain_exec('stop puppetserver')
          .with(
            command: 'systemctl stop puppetserver',
            onlyif:  'systemctl status puppetserver',
            unless: 'openssl x509 -in /etc/puppetlabs/puppet/ssl/certs/puppetserver1.domain.tld.pem -checkend 0',
          )
      }
    end
  end
end
