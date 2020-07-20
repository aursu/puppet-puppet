# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::profile::master' do
  let(:pre_condition) do
    <<-PRECOND
    postgresql::server::extension { 'puppetdb-pg_trgm':
      extension => 'pg_trgm',
      database  => 'puppetdb',
    }
    PRECOND
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
