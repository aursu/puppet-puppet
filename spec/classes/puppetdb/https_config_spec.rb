# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::puppetdb::https_config' do
  let(:pre_condition) do
    <<-PRECOND
    class { 'puppetdb':
      manage_firewall => false,
    }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppetdb/ssl')
          .with(
            ensure: 'directory',
            owner: 'root',
            group: 'puppetdb',
            mode: '0750',
          )
      }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppetdb/ssl/public.pem')
          .with(
            ensure: 'file',
            owner: 'root',
            group: 'puppetdb',
            mode: '0640',
            source: '/etc/puppetlabs/puppet/ssl/certs/puppetserver1.domain.tld.pem',
          )
          .that_notifies('Service[puppetdb]')
          .that_requires('Package[puppetdb]')
      }
    end
  end
end
