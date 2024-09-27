require 'spec_helper'

describe 'puppet::server::setup' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_exec('r10k-vardir')
          .with_command('mkdir -p /opt/puppetlabs/puppet/cache/r10k')
      }

      it {
        is_expected.to contain_file('/opt/puppetlabs/puppet/cache/r10k/r10k.yaml')
          .with_content(<<-R10KCONF)
---
# The location to use for storing cached Git repos
:cachedir: /var/cache/r10k

# A list of git repositories to create
:sources:
  # This will clone the git repository and instantiate an environment per
  # branch in /etc/puppetlabs/code/environments
  :production:
    remote: "https://github.com/aursu/control-init.git"
    basedir: /etc/puppetlabs/code/environments
  :common:
    remote: "https://github.com/aursu/control-common.git"
    basedir: /etc/puppetlabs/code/environments
  :enc:
    remote: "https://github.com/aursu/control-enc.git"
    basedir: /etc/puppetlabs/code/environments
R10KCONF
      }

      it {
        is_expected.to contain_exec('r10k-confpath-setup')
          .with_command('mkdir -p /etc/puppetlabs/r10k')
      }

      it {
        is_expected.to contain_exec('r10k-config')
          .with_command('cp /opt/puppetlabs/puppet/cache/r10k/r10k.yaml /etc/puppetlabs/r10k/r10k.yaml')
          .with_refreshonly(true)
      }

      it {
        is_expected.to contain_exec('environment-setup')
          .with(
            command: '/usr/bin/flock -n /run/r10k.lock /opt/puppetlabs/puppet/bin/r10k deploy environment -p',
            cwd: '/',
            refreshonly: true,
            timeout: 900,
          )
      }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppet/keys')
          .with(
            ensure: 'directory',
            recurse: true,
            purge: true,
          )
      }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppet/keys/public_key.pkcs7.pem')
          .with(
            owner: 'puppet',
            group: 'puppet',
            mode: '0400',
          )
      }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppet/keys/private_key.pkcs7.pem')
          .with(
            owner: 'puppet',
            group: 'puppet',
            mode: '0400',
          )
      }

      it {
        is_expected.not_to contain_cron('r10k-crontab')
      }

      context 'when enabled r10k crontab' do
        let(:params) do
          {
            r10k_crontab_setup: true,
          }
        end

        it {
          is_expected.to contain_cron('r10k-crontab')
            .with_command('/usr/bin/flock -n /run/r10k.lock /opt/puppetlabs/puppet/bin/r10k deploy environment -p')
            .that_requires('Exec[r10k-config]')
            .that_requires('Class[puppet::r10k::install]')
        }
      end
    end
  end
end
