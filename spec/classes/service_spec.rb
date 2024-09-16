require 'spec_helper'

describe 'puppet::service' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_service('puppet-server')
          .with(
            ensure: 'running',
            name: 'puppetserver',
            enable: true,
          )
          .that_subscribes_to('Package[puppet-server]')
      }

      it {
        is_expected.to contain_package('puppet-server')
          .with(
            ensure: 'installed',
            name: 'puppetserver',
          )
      }

      if os_facts[:os]['name'] == 'Rocky'
        it {
          is_expected.to contain_file('/etc/sysconfig/puppetserver')
            .with_content(%r{"-Xms2g -Xmx2g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"})
        }

        context 'with different tmp path' do
          let(:params) do
            {
              tmpdir: '/usr/local/tmp',
            }
          end

          it {
            is_expected.to contain_file('/etc/sysconfig/puppetserver')
              .with_content(%r{"-Xms2g -Xmx2g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -Djava.io.tmpdir=/usr/local/tmp"})
          }
        end

        context 'with different heap settings' do
          let(:params) do
            {
              min_heap_size: '4g',
              max_heap_size: '16g',
            }
          end

          it {
            is_expected.to contain_file('/etc/sysconfig/puppetserver')
              .with_content(%r{"-Xms4g -Xmx16g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"})
          }
        end
      end

      if os_facts[:os]['name'] == 'Ubuntu'
        context 'on Ubuntu' do
          it {
            is_expected.to contain_file('/etc/default/puppetserver')
              .with_content(%r{"-Xms2g -Xmx2g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger"})
          }

          context 'with different tmp path' do
            let(:params) do
              {
                tmpdir: '/usr/local/tmp',
              }
            end

            it {
              is_expected.to contain_file('/etc/default/puppetserver')
                .with_content(%r{"-Xms2g -Xmx2g -Djruby.logger.class=com.puppetlabs.jruby_utils.jruby.Slf4jLogger -Djava.io.tmpdir=/usr/local/tmp"})
            }
          end
        end
      end
    end
  end
end
