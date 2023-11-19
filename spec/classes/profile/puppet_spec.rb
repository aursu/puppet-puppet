# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::puppet' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      context 'when it is a Puppet Server' do
        let(:params) do
          {
            puppetserver: true,
            ca_server: 'puppetserver.domain.tld',
          }
        end

        it { is_expected.to compile.with_all_deps }
      end

      context 'when it is a Puppet Server and Puppet CA' do
        let(:params) do
          {
            puppetserver: true,
            sameca: true,
            ca_server: 'puppetserver.domain.tld',
          }
        end

        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
