require 'spec_helper'

describe 'puppet::repo' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
        context 'when Ubuntu 24.04 (noble)' do
          it {
            is_expected.not_to contain_package('puppet-release')
          }

          it {
            is_expected.not_to contain_package('puppet5-release')
          }

          it {
            is_expected.not_to contain_package('puppet6-release')
          }

          it {
            is_expected.not_to contain_package('puppet8-release')
          }
        end
      else
        context 'check deccomission packages' do
          it { is_expected.to compile }

          it {
            is_expected.to contain_package('puppet-release')
              .without_ensure
              .with_name('puppet8-release')
          }

          it {
            is_expected.to contain_package('puppet5-release')
              .with_ensure('absent')
              .that_comes_before('Package[puppet-release]')
          }

          it {
            is_expected.to contain_package('puppet6-release')
              .with_ensure('absent')
          }

          it {
            is_expected.to contain_package('puppet7-release')
              .with_ensure('absent')
          }
        end

        context 'check deccomission packages for Puppet 7' do
          let(:pre_condition) do
            <<-PRECOND
            include puppet
            class { 'puppet::globals': platform_name => 'puppet7', }
            PRECOND
          end

          it {
            is_expected.to contain_package('puppet-release')
              .without_ensure
              .with_name('puppet7-release')
          }

          it {
            is_expected.to contain_package('puppet5-release')
              .with_ensure('absent')
              .that_comes_before('Package[puppet-release]')
          }

          it {
            is_expected.to contain_package('puppet6-release')
              .with_ensure('absent')
          }

          it {
            is_expected.to contain_package('puppet8-release')
              .with_ensure('absent')
          }
        end
      end

      context 'when repo management disabled' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet': manage_repo => false, }
          PRECOND
        end

        it { is_expected.to compile }

        it {
          is_expected.not_to contain_package('puppet-release')
        }

        it {
          is_expected.not_to contain_package('puppet5-release')
        }

        it {
          is_expected.not_to contain_package('puppet6-release')
        }

        it {
          is_expected.not_to contain_package('puppet8-release')
        }
      end
    end
  end
end
