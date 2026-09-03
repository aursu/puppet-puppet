require 'spec_helper'

describe 'puppet::repo' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    # Debian keeps conffiles on remove, so removing the package is not what
    # decommissions the repository - the file removals below are. Purging would
    # do it, but it fails the resource via `apt-mark` once the repository is
    # gone, so the package stays `absent` on every platform.
    debian = os.match?(%r{^(ubuntu|debian)-})

    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      # The defect this fixes: the release package owns the source file, so once
      # the package is installed Puppet never revisits it. do-release-upgrade
      # then either renames it away (leaving no live source at all) or leaves it
      # naming the previous release -- and neither is visible to Puppet, because
      # Package['puppet-release'] is still satisfied.
      context 'the active platform apt source' do
        if debian
          it 'is declared as a resource Puppet owns, not left to the package' do
            is_expected.to contain_apt__source('puppet8-release')
              .with_repos('puppet8')
              .with_notify_update(false)
          end

          it 'takes its release from the OS fact, so it follows an OS upgrade' do
            expected = os_facts[:os]['distro']['codename']
            is_expected.to contain_apt__source('puppet8-release').with_release(expected)
          end

          # do-release-upgrade leaves these beside the file it renames. `.list`
          # is deliberately absent from the list -- apt::source writes that one.
          ['sources', 'list.distUpgrade', 'list.save'].each do |ext|
            it { is_expected.to contain_file("/etc/apt/sources.list.d/puppet8-release.#{ext}").with_ensure('absent') }
          end

          # The point of the change: the .list is now a File resource in the
          # catalogue, declared by apt::source rather than merely shipped by the
          # package -- which is what lets Puppet notice it going missing.
          it {
            is_expected.to contain_file('/etc/apt/sources.list.d/puppet8-release.list')
              .without_ensure('absent')
          }

          # A recreated or rewritten source needs the same apt refresh the
          # package triggers -- and on the hosts this fixes, the package does
          # not change at all.
          it {
            is_expected.to contain_apt__source('puppet8-release')
              .that_notifies('Exec[puppet-release-apt-update]')
          }

          # Puppet Inc keys live in trusted.gpg.d and their source line carries
          # no signed-by, so inventing one would not reproduce the original.
          it { is_expected.to contain_apt__source('puppet8-release').without_keyring }
        else
          it { is_expected.not_to contain_apt__source('puppet8-release') }
        end
      end

      context 'on the OpenVox platform' do
        let(:pre_condition) { "class { 'puppet::globals': platform_name => 'openvox8' } include puppet" }

        it { is_expected.to compile }

        if debian
          it 'points signed-by at the keyring the release package ships' do
            is_expected.to contain_apt__source('openvox8-release')
              .with_keyring('/etc/apt/keyrings/openvox-keyring.gpg')
              .with_repos('openvox8')
          end

          it { is_expected.to contain_apt__source('openvox8-release').with_location(%r{voxpupuli}) }
        end
      end

      context 'when the source is left to the release package' do
        let(:params) { { 'manage_source' => false } }

        it { is_expected.to compile }
        it { is_expected.not_to contain_apt__source('puppet8-release') }
        it { is_expected.not_to contain_file('/etc/apt/sources.list.d/puppet8-release.list.distUpgrade') }
      end

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

      context 'stale repository files of a decommissioned platform' do
        if debian
          # Purging the package removes what dpkg owns. These are the files it
          # does not: do-release-upgrade leaves a disabled `.sources` and a
          # `.list.distUpgrade` behind, and they keep pointing at a repository
          # that was supposed to be gone.
          ['list', 'sources', 'list.distUpgrade', 'list.save'].each do |ext|
            it {
              is_expected.to contain_file("/etc/apt/sources.list.d/puppet7-release.#{ext}")
                .with_ensure('absent')
                .that_requires('Package[puppet7-release]')
                .that_comes_before('Package[puppet-release]')
            }
          end

          # Version-specific, so it belongs to exactly one release package.
          it {
            is_expected.to contain_file('/etc/apt/trusted.gpg.d/puppet7-keyring.gpg')
              .with_ensure('absent')
          }

          # ⚠ Shared between openvox7 and openvox8. Removing it while migrating
          # 7 -> 8 would delete the key the new repository needs.
          it {
            is_expected.not_to contain_file('/etc/apt/keyrings/openvox-keyring.gpg')
          }

          # Shared between platform versions too.
          it {
            is_expected.not_to contain_file('/etc/apt/preferences.d/puppet-release.pref')
          }
        else
          it {
            is_expected.not_to contain_file('/etc/apt/sources.list.d/puppet7-release.list')
          }
        end
      end

      context 'apt index refresh after the release package changes' do
        if debian
          # Without this the agent package, ordered directly after this class,
          # fails on the same run with "Unable to locate package".
          it {
            is_expected.to contain_exec('puppet-release-apt-update')
              .with_command('apt-get update')
              .with_refreshonly(true)
              .that_subscribes_to('Package[puppet-release]')
          }
        else
          it { is_expected.not_to contain_exec('puppet-release-apt-update') }
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
