# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::ca::allow' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
