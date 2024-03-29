# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::bootstrap::setup' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec('mkdir -p /root/bootstrap')
          .with(
            cwd: '/',
            creates: '/root/bootstrap',
          )
          .that_comes_before('File[/root/bootstrap]')
      }

      it {
        is_expected.to contain_file('/root/bootstrap')
          .with_ensure(:directory)
      }

      it {
        is_expected.to contain_file('/root/bootstrap/ca')
          .with_ensure(:directory)
      }

      it {
        is_expected.to contain_file('/root/bootstrap/keys')
          .with_ensure(:directory)
      }

      context 'when cwd is different' do
        let(:pre_condition) do
          <<-PRECOND
          class { 'puppet::server::bootstrap::globals':
            cwd => '/tmp',
          }
          PRECOND
        end

        it {
          is_expected.to contain_exec('mkdir -p /tmp')
            .with(
              cwd: '/',
              creates: '/tmp',
            )
        }

        it {
          is_expected.to contain_file('/tmp')
            .with_ensure(:directory)
        }
      end
    end
  end
end
