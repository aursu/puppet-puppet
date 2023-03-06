# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::compiler' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          ca_server: 'puppet',
        }
      end

      it { is_expected.to compile }

      it {
        is_expected.not_to contain_cron('r10k-crontab')
      }

      context 'when enabled r10k crontab' do
        let(:params) do
          super().merge(
            r10k_crontab_setup: true,
          )
        end

        it {
          is_expected.to contain_cron('r10k-crontab')
        }
      end
    end
  end
end
