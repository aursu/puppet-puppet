# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::server' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

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
    end
  end
end
