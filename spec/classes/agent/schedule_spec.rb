# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::agent::schedule' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_cron('puppet agent run')
          .with_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay --verbose')
      }

      context 'check verbose disabled' do
        let(:params) do
          {
            verbose: false,
          }
        end

        it {
          is_expected.to contain_cron('puppet agent run')
            .with_command('/opt/puppetlabs/bin/puppet agent --onetime --no-daemonize --no-usecacheonfailure --detailed-exitcodes --no-splay')
        }
      end
    end
  end
end
