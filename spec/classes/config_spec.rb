require 'spec_helper'

describe 'puppet::config' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      it {
        is_expected.to contain_file('puppet-config')
          .with_path('/etc/puppetlabs/puppet/puppet.conf')
          .with_content(%r{basemodulepath = /etc/puppetlabs/code/environments/common/modules})
      }
    end
  end
end
