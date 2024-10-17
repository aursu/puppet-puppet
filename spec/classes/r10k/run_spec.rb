# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::r10k::run' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_exec('environment-setup')
          .without_cwd
          .without_user
          .with(
            command: '/usr/bin/flock -n /run/r10k.lock /opt/puppetlabs/puppet/bin/r10k deploy environment -p',
            refreshonly: true,
            path: '/bin:/usr/bin',
            timeout: 900,
          )
      }
    end
  end
end
