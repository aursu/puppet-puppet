# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::server::ca::allow' do
  let(:pre_condition) { 'include puppet' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      context 'by default' do
        # The rule Puppet Server ships allows both halves unauthenticated. Left
        # alone unless asked, because this is a public module and the shipped
        # behaviour is what other users expect.
        it { is_expected.not_to contain_puppet_auth_rule('puppetlabs csr') }
        it { is_expected.not_to contain_puppet_auth_rule('puppetlabs csr read') }
      end

      context 'with restrict_csr_read => true' do
        let(:params) { { restrict_csr_read: true } }

        it { is_expected.to compile }

        # Submitting a CSR must stay open: a node enrolling has no certificate
        # yet, so requiring one would make enrolment impossible.
        it {
          is_expected.to contain_puppet_auth_rule('puppetlabs csr')
            .with(
              ensure: 'present',
              match_request_path: '/puppet-ca/v1/certificate_request',
              match_request_type: 'path',
              match_request_method: 'put',
              allow_unauthenticated: true,
            )
        }

        # Reading one is restricted the same way the certificate-status rules
        # are, and must NOT carry allow_unauthenticated - the type rejects a rule
        # that sets both.
        it {
          is_expected.to contain_puppet_auth_rule('puppetlabs csr read')
            .with(
              ensure: 'present',
              match_request_path: '/puppet-ca/v1/certificate_request',
              match_request_type: 'path',
              match_request_method: 'get',
            )
        }

        # The ACL property munges extension values to strings, so the catalogue
        # holds 'true' rather than the boolean written in the manifest.
        it {
          expect(catalogue.resource('puppet_auth_rule', 'puppetlabs csr read')[:allow])
            .to include({ 'extensions' => { 'pp_cli_auth' => 'true' } })
        }

        it {
          expect(catalogue.resource('puppet_auth_rule', 'puppetlabs csr read')[:allow_unauthenticated])
            .to be_nil
        }
      end

      context 'with restrict_csr_read => true and a separate ca_server' do
        let(:params) { { restrict_csr_read: true, ca_server: 'ca.example.com' } }

        it { is_expected.to compile }

        # The CA server has to keep reading requests, exactly as it does for the
        # certificate-status rules.
        it {
          expect(catalogue.resource('puppet_auth_rule', 'puppetlabs csr read')[:allow])
            .to include('ca.example.com')
        }
      end
    end
  end
end
