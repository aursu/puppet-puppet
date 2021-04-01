# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::ca::import' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          import_path: '/root/ca',
        }
      end

      it { is_expected.to compile }
    end
  end
end
