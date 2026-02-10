# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::agent::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

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
