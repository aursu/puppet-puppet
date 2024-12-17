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

      if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
        config_path = '/etc/puppet/puppet.conf'
        server_confdir = '/etc/puppet/puppetserver'
      else
        config_path = '/etc/puppetlabs/puppet/puppet.conf'
        server_confdir = '/etc/puppetlabs/puppetserver'
      end

      it { is_expected.to compile }

      if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppet/puppet.conf')
            .with_content(%r{basemodulepath = /etc/puppet/code/environments/common/modules})
        }
      else
        it {
          is_expected.to contain_file('puppet-config')
            .with_path('/etc/puppetlabs/puppet/puppet.conf')
            .with_content(%r{basemodulepath = /etc/puppetlabs/code/environments/common/modules})
        }
      end

      it {
        is_expected.to contain_file('puppet-config')
          .with_path(config_path)
          .with_content(%r{\[server\]})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path(config_path)
          .with_content(%r{autosign = false})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path(config_path)
          .without_content(%r{^ca =})
      }

      it {
        is_expected.to contain_file("#{server_confdir}/services.d/ca.cfg")
          .with_content(%r{^puppetlabs.services.ca.certificate-authority-service/certificate-authority-service})
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path(config_path)
          .without_content(%r{certname})
      }

      it {
        is_expected.not_to contain_file("#{server_confdir}/conf.d/webserver.conf")
      }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path(config_path)
          .without_content(%r{dns_alt_names})
      }

      context 'check dns_alt_names when empty Array' do
        let(:params) do
          {
            dns_alt_names: [],
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path(config_path)
            .without_content(%r{dns_alt_names})
        }
      end

      context 'check webserver.conf management' do
        let(:params) do
          {
            manage_webserver_conf: true,
          }
        end

        if os_facts[:os]['name'] == 'Ubuntu' && os_facts[:os]['distro']['codename'] == 'noble'
          it {
            is_expected.to contain_file('/etc/puppet/puppetserver/conf.d/webserver.conf')
              .with_content(%r{ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem}) # this path is hardcoded in default_facts.yml
          }
        else
          it {
            is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/webserver.conf')
              .with_content(%r{ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
          }
        end
      end

      context 'check static certname' do
        let(:params) do
          {
            static_certname: true,
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path(config_path)
            .with_content(%r{^\[main\]\ncertname =})
        }

        context 'with defined static name' do
          let(:params) do
            super().merge(
              'certname' => 'puppet-ca.domain.tld',
            )
          end

          it {
            is_expected.to contain_file('puppet-config')
              .with_path(config_path)
              .with_content(%r{^\[main\]\ncertname = puppet-ca.domain.tld$})
          }
        end
      end

      context 'check ca directive in server config for default (Puppet 7) server' do
        let(:params) do
          {
            sameca: false,
          }
        end

        it {
          is_expected.to contain_file('puppet-config')
            .with_path(config_path)
            .without_content(%r{^ca =})
        }

        it {
          is_expected.to contain_file("#{server_confdir}/services.d/ca.cfg")
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
            .with_path(config_path)
            .with_content(%r{\[master\]})
        }

        it {
          is_expected.to contain_file('puppet-config')
            .with_path(config_path)
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
              .with_path(config_path)
              .with_content(%r{^ca = false})
          }
        end
      end
    end
  end
end
