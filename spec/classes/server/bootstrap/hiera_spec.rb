# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::bootstrap::hiera' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec('cp -a hiera/common.yaml /etc/puppetlabs/code/environments/production/data/common.yaml')
          .with(
            cwd: '/root/bootstrap',
          )
      }
    end
  end
end
