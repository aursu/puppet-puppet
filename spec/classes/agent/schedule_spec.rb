# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::agent::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      # The agent package enables the daemon on install, and this estate drives
      # the agent from cron. Both scheduling the same agent means whichever
      # starts second hits the run lock and exits non-zero, leaving
      # puppet.service permanently failed.
      context 'agent daemon, with cron scheduling enabled (the default)' do
        it 'stops and masks the daemon' do
          is_expected.to contain_service('puppet-agent-daemon')
            .with_ensure('stopped')
            .with_name('puppet')
            .with_enable('mask')
            .with_provider('systemd')
        end
      end

      # Managed in both directions: declaring it only when disabling would leave
      # a masked unit behind that Puppet would never unmask.
      context 'when the daemon is explicitly wanted' do
        let(:params) { { 'disable_daemon' => false } }

        it { is_expected.to compile }

        it 'runs and enables the daemon instead' do
          is_expected.to contain_service('puppet-agent-daemon')
            .with_ensure('running')
            .with_enable(true)
            .with_provider('systemd')
        end
      end

      # false is both falsy and meaningful, so an explicit false must not be
      # mistaken for "unset" and fall back to $enable.
      context 'when disable_daemon is false while cron scheduling is enabled' do
        let(:params) { { 'enable' => true, 'disable_daemon' => false } }

        it { is_expected.to contain_service('puppet-agent-daemon').with_ensure('running') }
        it { is_expected.to contain_cron('puppet agent run') }
      end

      # No cron schedule, so nothing else runs the agent: the daemon is left be
      # unless asked for otherwise.
      context 'when cron scheduling is disabled' do
        let(:params) { { 'enable' => false } }

        it { is_expected.to compile }
        it { is_expected.to contain_service('puppet-agent-daemon').with_ensure('running') }
        it { is_expected.not_to contain_cron('puppet agent run') }
      end

      context 'when the daemon is disabled on a host with no cron schedule' do
        let(:params) { { 'enable' => false, 'disable_daemon' => true } }

        it { is_expected.to contain_service('puppet-agent-daemon').with_ensure('stopped').with_enable('mask') }
        it { is_expected.not_to contain_cron('puppet agent run') }
      end

      context 'with a renamed daemon service' do
        let(:params) { { 'daemon_service_name' => 'openvox-agent' } }

        it { is_expected.to contain_service('puppet-agent-daemon').with_name('openvox-agent') }
      end

      context 'when vendor distro enabled' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet::globals': os_vendor_distro => true,  }
          include puppet
          PRECOND
        end

        it {
          is_expected.to contain_cron('puppet agent run')
            .with_command('/usr/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay --verbose')
        }

        context 'check verbose disabled on Ubuntu 24.04' do
          let(:params) do
            {
              verbose: false,
            }
          end

          it {
            is_expected.to contain_cron('puppet agent run')
              .with_command('/usr/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay')
          }
        end
      end

      it {
        is_expected.to contain_cron('puppet agent run')
          .with_command('/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay --verbose')
      }

      context 'check verbose disabled' do
        let(:params) do
          {
            verbose: false,
          }
        end

        it {
          is_expected.to contain_cron('puppet agent run')
            .with_command('/opt/puppetlabs/puppet/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay')
        }
      end
    end
  end
end
