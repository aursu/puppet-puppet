require 'spec_helper'

describe 'puppet::config' do
  let(:pre_condition) { 'include puppet' }

  # Since 1.0.0 the webserver listener defaults to the host's first private
  # address and fails closed when there is none, so the fact set needs one.
  # Merged into networking rather than replacing it - fqdn lives there too.
  let(:private_networking) do
    {
      'ip' => '10.154.5.6',
      'interfaces' => {
        'lo' => { 'ip' => '127.0.0.1' },
        'eth0' => { 'ip' => '10.154.5.6' },
      },
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(networking: os_facts[:networking].merge(private_networking)) }
      let(:params) do
        {
          sameca: true,
        }
      end

      config_path    = '/etc/puppetlabs/puppet/puppet.conf'
      server_confdir = '/etc/puppetlabs/puppetserver'

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{basemodulepath = /etc/puppetlabs/code/environments/common/modules})
      }

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

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppetserver/conf.d/webserver.conf')
            .with_content(%r{ssl-ca-cert: /etc/puppetlabs/puppet/ssl/certs/ca.pem})
        }
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
    end
  end
end
