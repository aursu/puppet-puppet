# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      # A private address: ssl_host defaults to one and puppet::config::webserver
      # fails closed without it. Merged in, since networking also carries fqdn.
      let(:facts) do
        os_facts.merge(networking: os_facts[:networking].merge(
                         'ip' => '10.154.5.6',
                         'interfaces' => { 'lo' => { 'ip' => '127.0.0.1' },
                                           'eno2' => { 'ip' => '10.154.5.6' } },
                       ))
      end

      it { is_expected.to compile }

      it {
        is_expected.to contain_class('puppetdb')
      }

      it {
        is_expected.to contain_class('puppetdb::master::config')
          .with(
            puppetdb_server: 'puppet',
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
        }
      end

      context 'with custom PuppetDB server' do
        let(:params) do
          {
            puppetdb_server: 'puppet-db.domaiin.tld',
          }
        end

        it {
          is_expected.to contain_class('puppetdb::master::config')
            .with(
              puppetdb_server: 'puppet-db.domaiin.tld',
            )
        }
      end

      context 'without local PuppetDB server' do
        let(:params) do
          {
            puppetdb_local: false,
          }
        end

        it {
          is_expected.to contain_class('puppetdb::master::config')
        }

        it {
          is_expected.not_to contain_class('puppetdb')
        }
      end

      context 'with mount points for file server' do
        let(:params) do
          {
            mount_points: {
              'geoip' => '/var/data/geoip',
              'ssl'   => '/usr/local/ssl/certs',
            },
          }
        end

        it {
          is_expected.to contain_file('/etc/puppetlabs/puppet/fileserver.conf')
            .with_content(<<-FILESERV)
[geoip]
    path /var/data/geoip

[ssl]
    path /usr/local/ssl/certs

FILESERV
        }
      end

      context 'with manage_nginx => true' do
        let(:params) { { manage_nginx: true } }

        it { is_expected.to contain_class('puppet::nginx') }

        # The whole point of owning the switch here: the companions follow, so a
        # caller cannot produce nginx-terminates-TLS-but-Puppet-Server-does-not,
        # or Puppet Server trusting headers nothing sets.
        it { is_expected.to contain_class('puppet::config').with_tls_offload(true) }
        it { is_expected.to contain_class('puppet::config').with_allow_header_cert_info(true) }
      end

      context 'with manage_nginx => false' do
        it { is_expected.not_to contain_class('puppet::nginx') }
        it { is_expected.to contain_class('puppet::config').with_tls_offload(false) }

        # undef, not false: unmanaged unless someone asks for it.
        it { is_expected.to contain_class('puppet::config').with_allow_header_cert_info(nil) }
      end
    end
  end
end
