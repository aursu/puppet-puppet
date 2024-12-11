# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::agent::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
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
      else
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
end
