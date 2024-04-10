# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::puppetdb' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      context 'when cron management is in use' do
        let(:facts) { os_facts.merge({ 'systemd' => false }) }

        it {
          is_expected.to contain_cron('puppetdb-dlo-cleanup')
        }

        context 'and cron management disabled' do
          let(:params) do
            {
              manage_cron: false,
            }
          end

          it {
            is_expected.not_to contain_cron('puppetdb-dlo-cleanup')
          }
        end
      end
    end
  end
end
