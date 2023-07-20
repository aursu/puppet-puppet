# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::config::fileserver' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        # by default if mount_points us empty - no config file managed
        is_expected.not_to contain_file('/etc/puppetlabs/puppet/fileserver.conf')
      }
    end
  end
end
