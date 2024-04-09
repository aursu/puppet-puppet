# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::agent::config' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{usecacheonfailure = false})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{runtimeout = 10m})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{onetime = true})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .without_content(%r{certname})
      }

      context 'with defined static name' do
        let(:params) do
          {
            certname: 'puppet-ca.domain.tld',
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_content(%r{^\[main\]\ncertname = puppet-ca.domain.tld$})
        }
      end
    end
  end
end
