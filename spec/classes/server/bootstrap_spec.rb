# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::bootstrap' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

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

        it {
          is_expected.to contain_exec('environment-setup')
            .with(
              command: '/opt/puppetlabs/puppet/bin/r10k deploy environment -p',
              refreshonly: false,
              timeout: 900,
              cwd: '/root/bootstrap',
            )
        }

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

        it {
          is_expected.to contain_exec('environment-setup')
            .with(
              command: '/opt/puppetlabs/puppet/bin/r10k deploy environment -p',
              refreshonly: false,
              timeout: 900,
              cwd: '/root/bootstrap',
            )
        }
      end

      context 'with dns_alt_names' do
        let(:params) do
          {
            dns_alt_names: [
              'puppet',
              'puppet-puppet-puppet-1',
            ],
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_content(%r{dns_alt_names = puppet,puppet-puppet-puppet-1})
        }
      end
    end
  end
end
