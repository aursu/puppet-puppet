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
    end
  end
end
