# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::puppetdb::https_config' do
  let(:pre_condition) do
    # The package name comes from puppet::puppetdb::globals, as puppet::puppetdb
    # passes it, so https_config's require resolves on an OpenVox platform too.
    <<-PRECOND
    include puppet::puppetdb::globals
    class { 'puppetdb':
      manage_firewall  => false,
      puppetdb_package => $puppet::puppetdb::globals::puppetdb_package,
    }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    puppetdb_package = openvox_default?(os) ? 'openvoxdb' : 'puppetdb'

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
          .that_requires("Package[#{puppetdb_package}]")
      }
    end
  end
end
