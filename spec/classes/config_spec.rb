require 'spec_helper'

describe 'puppet::config' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          sameca: true,
        }
      end

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{basemodulepath = /etc/puppetlabs/code/environments/common/modules})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{\[server\]})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{autosign = false})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .without_content(%r{^ca =})
      }

      it {
        is_expected.to contain_file('/etc/puppetlabs/puppetserver/services.d/ca.cfg')
          .with_content(%r{^puppetlabs.services.ca.certificate-authority-service/certificate-authority-service})
      }

      context 'check ca directive in server config for default (Puppet 7) server' do
        let(:params) do
          {
            sameca: false,
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .without_content(%r{^ca =})
        }

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/services.d/ca.cfg')
            .with_content(%r{^puppetlabs.services.ca.certificate-authority-disabled-service/certificate-authority-disabled-service})
        }
      end

      context 'on Puppet 5 platform' do
        let(:pre_condition) do
          <<-PUPPETCODE
          include puppet
          class { 'puppet::globals': platform_name => 'puppet5' }
          PUPPETCODE
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_content(%r{\[master\]})
        }

        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .without_content(%r{^ca =})
        }

        context 'check ca directive in server config for Puppet 5 server' do
          let(:params) do
            {
              sameca: false,
            }
          end

          it {
            is_expected.to contain_file('puppet-config')
              .with_path('/etc/puppetlabs/puppet/puppet.conf')
              .with_content(%r{^ca = false})
          }
        end
      end
    end
  end
end
