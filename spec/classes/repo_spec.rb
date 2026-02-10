require 'spec_helper'

describe 'puppet::repo' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

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
          class { 'puppet::globals': platform_name => 'puppet7', }
          include puppet
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

      context 'check platform repository URLs for OpenVox' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet::globals': platform_name => 'openvox8', }
          include puppet
          PRECOND
        end

        case os_facts[:os]['family']
        when 'Debian'
          case os_facts[:os]['name']
          when 'Ubuntu'
            case os_facts[:os]['release']['major']
            when '24.04'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.voxpupuli.org/openvox8-release-ubuntu24.04.deb -f -s -o /tmp/puppet-puppet/openvox8-release-ubuntu24.04.deb')
              }
            when '22.04'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.voxpupuli.org/openvox8-release-ubuntu22.04.deb -f -s -o /tmp/puppet-puppet/openvox8-release-ubuntu22.04.deb')
              }
            end
          when 'Debian'
            case os_facts[:os]['release']['major']
            when '12'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.voxpupuli.org/openvox8-release-debian12.deb -f -s -o /tmp/puppet-puppet/openvox8-release-debian12.deb')
              }
            end
          end
        when 'Suse'
          case os_facts[:os]['name']
          when 'SLES'
            case os_facts[:os]['release']['major']
            when '15'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.voxpupuli.org/openvox8-release-sles-15.noarch.rpm -f -s -o /tmp/puppet-puppet/openvox8-release-sles-15.noarch.rpm')
              }
            end
          end
        when 'RedHat'
          case os_facts[:os]['name']
          when 'Fedora'
            case os_facts[:os]['release']['major']
            when '41'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.voxpupuli.org/openvox8-release-fedora-41.noarch.rpm -f -s -o /tmp/puppet-puppet/openvox8-release-fedora-41.noarch.rpm')
              }
            end
          when 'Rocky'
            case os_facts[:os]['release']['major']
            when '10'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.voxpupuli.org/openvox8-release-el-10.noarch.rpm -f -s -o /tmp/puppet-puppet/openvox8-release-el-10.noarch.rpm')
              }
            end
          when 'Amazon'
            case os_facts[:os]['release']['major']
            when '2023'
              it {
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.voxpupuli.org/openvox8-release-amazon-2023.noarch.rpm -f -s -o /tmp/puppet-puppet/openvox8-release-amazon-2023.noarch.rpm')
              }
            end
          end
        end
      end

      context 'check platform repository URLs for standard Puppet' do
        case os_facts[:os]['family']
        when 'Debian'
          case os_facts[:os]['name']
          when 'Ubuntu'
            case os_facts[:os]['release']['major']
            when '24.04'
              it 'downloads puppet8-release-noble.deb repository package for Ubuntu 24.04' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.puppet.com/puppet8-release-noble.deb -f -s -o /tmp/puppet-puppet/puppet8-release-noble.deb')
              end
            when '22.04'
              it 'downloads puppet8-release-jammy.deb repository package for Ubuntu 22.04' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.puppet.com/puppet8-release-jammy.deb -f -s -o /tmp/puppet-puppet/puppet8-release-jammy.deb')
              end
            end
          when 'Debian'
            case os_facts[:os]['release']['major']
            when '12'
              it 'downloads puppet8 repository package for Debian 12' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://apt.puppet.com/puppet8-release-bookworm.deb -f -s -o /tmp/puppet-puppet/puppet8-release-bookworm.deb')
              end
            end
          end
        when 'Suse'
          case os_facts[:os]['name']
          when 'SLES'
            case os_facts[:os]['release']['major']
            when '15'
              it 'downloads puppet8 repository package for SLES 15' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-sles-15.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-sles-15.noarch.rpm')
              end
            end
          end
        when 'RedHat'
          case os_facts[:os]['name']
          when 'Fedora'
            case os_facts[:os]['release']['major']
            when '41'
              it 'downloads puppet8 repository package for Fedora 41' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-fedora-41.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-fedora-41.noarch.rpm')
              end
            end
          when 'Rocky'
            case os_facts[:os]['release']['major']
            when '10'
              it 'downloads puppet8 repository package for Rocky 10' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-el-10.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-el-10.noarch.rpm')
              end
            when '9'
              it 'downloads puppet8 repository package for Rocky 9' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-el-9.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-el-9.noarch.rpm')
              end
            when '8'
              it 'downloads puppet8 repository package for Rocky 8' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-el-8.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-el-8.noarch.rpm')
              end
            end
          when 'Amazon'
            case os_facts[:os]['release']['major']
            when '2023'
              it 'downloads puppet8 repository package for Amazon Linux 2023' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-amazon-2023.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-amazon-2023.noarch.rpm')
              end
            end
          when 'CentOS'
            case os_facts[:os]['release']['major']
            when '7'
              it 'downloads puppet8 repository package for CentOS 7' do
                is_expected.to contain_exec('puppet-release')
                  .with_command('curl https://yum.puppet.com/puppet8-release-el-7.noarch.rpm -f -s -o /tmp/puppet-puppet/puppet8-release-el-7.noarch.rpm')
              end
            end
          end
        end
      end
    end
  end
end
