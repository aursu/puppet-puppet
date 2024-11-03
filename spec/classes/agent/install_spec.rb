require 'spec_helper'

describe 'puppet::agent::install' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_package('puppet-agent')
          .with_name('puppet-agent')
          .with_ensure('installed')
      }

      context 'check version setup' do
        let(:params) do
          {
            agent_version: '7.26.0',
          }
        end

        it { is_expected.to compile }

        case os_facts[:os]['name']
        when 'Rocky', 'CentOS', 'RedHat'
          os_version = os_facts[:os]['release']['major']
          it {
            is_expected.to contain_package('puppet-agent')
              .with_name('puppet-agent')
              .with_ensure("7.26.0-1.el#{os_version}")
          }
        when 'Ubuntu', 'Debian'
          it {
            is_expected.to contain_package('puppet-agent')
              .with_name('puppet-agent')
              .with_ensure('7.26.0')
          }
        end
      end

      context 'when agent_version is set to latest' do
        let(:params) do
          {
            agent_version: 'latest',
          }
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_package('puppet-agent')
            .with_name('puppet-agent')
            .with_ensure('latest')
        }
      end
    end
  end
end
