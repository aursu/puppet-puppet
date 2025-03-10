# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::bootstrap' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.deep_merge('networking' => { 'fqdn' => 'hostname.domain.tld' }) }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.not_to contain_exec('environment-setup')
      }

      it {
        is_expected.to contain_file('/root/bootstrap')
          .with_ensure(:directory)
      }

      it {
        is_expected.to contain_file('/root/bootstrap/ca')
          .with_ensure(:directory)
      }

      if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppet/puppet.conf')
            .with_content(%r{dns_alt_names = puppet,hostname.domain.tld})
        }
      else
        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_content(%r{dns_alt_names = puppet,hostname.domain.tld})
        }
      end

      context 'when use SSH for Git access' do
        let(:pre_condition) do
          <<-PRECOND
          include puppet
          class { 'puppet::server::bootstrap::globals':
            access_data => lookup({
              name => 'puppet::server::bootstrap::access',
              default_value => [],
            }),
          }
          PRECOND
        end
        let(:facts) { os_facts.merge(stype: 'puppetserver') }
        let(:params) do
          {
            use_ssh: true,
          }
        end

        if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
          it {
            is_expected.to contain_exec('environment-setup')
              .with(
                command: '/usr/bin/flock -n /run/r10k.lock /usr/local/bin/r10k deploy environment -p',
                refreshonly: false,
                timeout: 900,
                cwd: '/root/bootstrap',
              )
          }
        else
          it {
            is_expected.to contain_exec('environment-setup')
              .with(
                command: '/usr/bin/flock -n /run/r10k.lock /opt/puppetlabs/puppet/bin/r10k deploy environment -p',
                refreshonly: false,
                timeout: 900,
                cwd: '/root/bootstrap',
              )
          }
        end

        it {
          is_expected.to contain_exec('environment-setup')
            .that_requires('Openssh::Ssh_config[root]')
        }
      end

      context 'without SSH for Git access' do
        let(:params) do
          {
            use_ssh: false,
          }
        end

        if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
          it {
            is_expected.to contain_exec('environment-setup')
              .with(
                command: '/usr/bin/flock -n /run/r10k.lock /usr/local/bin/r10k deploy environment -p',
                refreshonly: false,
                timeout: 900,
                cwd: '/root/bootstrap',
              )
          }
        else
          it {
            is_expected.to contain_exec('environment-setup')
              .with(
                command: '/usr/bin/flock -n /run/r10k.lock /opt/puppetlabs/puppet/bin/r10k deploy environment -p',
                refreshonly: false,
                timeout: 900,
                cwd: '/root/bootstrap',
              )
          }
        end
      end

      context 'with dns_alt_names' do
        let(:params) do
          {
            dns_alt_names: %w[puppet puppet-puppet-puppet-1],
          }
        end

        if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
          it {
            is_expected.to contain_file('puppet-config')
              .with_path('/etc/puppet/puppet.conf')
              .with_content(%r{dns_alt_names = puppet,puppet-puppet-puppet-1,hostname.domain.tld})
          }
        else
          it {
            is_expected.to contain_file('puppet-config')
              .with_path('/etc/puppetlabs/puppet/puppet.conf')
              .with_content(%r{dns_alt_names = puppet,puppet-puppet-puppet-1,hostname.domain.tld})
          }
        end
      end

      context 'with dns_alt_names single name' do
        let(:params) do
          {
            dns_alt_names: [
              'puppet-puppet-puppet-1',
            ],
          }
        end

        if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
          it {
            is_expected.to contain_file('puppet-config')
              .with_path('/etc/puppet/puppet.conf')
              .with_content(%r{dns_alt_names = puppet-puppet-puppet-1,puppet,hostname.domain.tld})
          }
        else
          it {
            is_expected.to contain_file('puppet-config')
              .with_path('/etc/puppetlabs/puppet/puppet.conf')
              .with_content(%r{dns_alt_names = puppet-puppet-puppet-1,puppet,hostname.domain.tld})
          }
        end
      end
    end
  end
end
