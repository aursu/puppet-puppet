require 'spec_helper'

describe 'puppet::server::install' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_package('puppet-server')
          .with_name('puppetserver')
          .with_ensure('installed')
      }

      context 'with openvox8 platform' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet::globals': platform_name => 'openvox8', }
          include puppet
          PRECOND
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_package('puppet-server')
            .with_name('openvox-server')
            .with_ensure('installed')
        }
      end

      context 'with puppet7 platform' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet::globals': platform_name => 'puppet7', }
          include puppet
          PRECOND
        end

        it { is_expected.to compile }

        it {
          is_expected.to contain_package('puppet-server')
            .with_name('puppetserver')
            .with_ensure('installed')
        }
      end
    end
  end
end
