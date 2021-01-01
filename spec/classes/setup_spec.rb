require 'spec_helper'

describe 'puppet::setup' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'with external facts directories management' do
        let(:params) do
          {
            'external_facts_setup' => true,
          }
        end

        it { is_expected.to contain_file('/etc/facter') }
        it { is_expected.to contain_file('/etc/facter/facts.d') }
        it { is_expected.to contain_file('/opt/puppetlabs/facter') }
        it { is_expected.to contain_file('/opt/puppetlabs/facter/facts.d') }
        it { is_expected.to contain_file('/etc/puppetlabs/facter') }
        it { is_expected.to contain_file('/etc/puppetlabs/facter/facts.d') }
      end
    end
  end
end
