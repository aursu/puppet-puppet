# frozen_string_literal: true

require 'spec_helper'

describe 'puppet::nginx' do
  # With manage_nginx_core => false the core class is owned by something else on
  # the host - on the real servers, by the profile that already runs nginx. It
  # must still be in the catalogue, because nginx::resource::server reads
  # $nginx::spdy and friends. This class deliberately does not declare it: doing
  # so before whatever owns core would be a duplicate declaration.
  let(:pre_condition) { ['include puppet', 'include nginx'] }

  # Deterministic interfaces: one loopback, one private, one public. The default
  # facterdb set varies per OS, and address selection is exactly what several of
  # these examples assert.
  # Merged INTO the OS fact set, never replacing it: `networking` also carries
  # fqdn, hostname and domain, which the rest of the module needs to compile.
  let(:networking_override) do
    {
      'ip' => '203.0.113.10',
      'interfaces' => {
        'lo' => { 'ip' => '127.0.0.1' },
        'eth0' => { 'ip' => '10.154.5.6' },
        'eth1' => { 'ip' => '203.0.113.10' },
      },
    }
  end
  let(:no_private_override) do
    {
      'ip' => '203.0.113.10',
      'interfaces' => {
        'lo' => { 'ip' => '127.0.0.1' },
        'eth0' => { 'ip' => '203.0.113.10' },
      },
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts.merge(networking: os_facts[:networking].merge(networking_override)) }

      context 'with manage_nginx_core => false' do
        let(:params) { { manage_nginx_core: false } }

        it { is_expected.to compile }

        # Core is owned elsewhere on such a host; declaring it here would fight
        # whatever already manages nginx.conf.
        it { is_expected.not_to contain_class('lsys_nginx') }

        it {
          is_expected.to contain_nginx__resource__server('puppetserver')
            .with(
              listen_port: 8140,
              ssl: true,
              ssl_verify_client: 'optional',
              use_default_location: false,
            )
        }

        # `optional`, not `on`: the CA path has to accept a client with no
        # certificate at all, which is the entire point of the split.
        it {
          expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:ssl_verify_client]).to eq('optional')
        }

        # Revocation is nginx's job once it verifies the client, so a missing CRL
        # would mean a revoked certificate still authenticating.
        it {
          expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:ssl_crl])
            .to eq('/etc/puppetlabs/puppet/ssl/crl.pem')
        }

        describe 'the catalogue location' do
          it {
            is_expected.to contain_nginx__resource__location('puppetserver-default')
              .with(
                server: 'puppetserver',
                location: '/',
                proxy: 'http://127.0.0.1:8140',
              )
          }

          # This is what replaces Jetty's client-auth => need.
          it {
            expect(catalogue.resource('nginx::resource::location', 'puppetserver-default')[:raw_prepend])
              .to include(%r{ssl_client_verify != SUCCESS})
          }
        end

        describe 'the CA location' do
          it {
            is_expected.to contain_nginx__resource__location('puppetserver-ca')
              .with(
                server: 'puppetserver',
                location: '/puppet-ca',
                proxy: 'http://127.0.0.1:8140',
              )
          }

          # Deliberately NOT carrying the verify check - that is what allows a
          # node with no certificate to enrol.
          it {
            prepend = Array(catalogue.resource('nginx::resource::location', 'puppetserver-ca')[:raw_prepend])

            expect(prepend.join(' ')).not_to match(%r{ssl_client_verify})
          }
        end

        # The security-critical assertion: identity headers are overwritten on
        # EVERY location. A location that forwards a client-supplied X-Client-DN
        # lets an unauthenticated caller claim to be any node.
        ['puppetserver-default', 'puppetserver-ca'].each do |location|
          it "overwrites the client identity headers on #{location}" do
            headers = catalogue.resource('nginx::resource::location', location)[:proxy_set_header]

            expect(headers).to include('X-Client-Verify $ssl_client_verify')
            expect(headers).to include('X-Client-DN $ssl_client_s_dn')
            expect(headers).to include('X-Client-Cert $ssl_client_escaped_cert')
          end
        end
      end

      context 'with manage_nginx_core => true' do
        # lsys_nginx declares class nginx itself, so pre-including it here would
        # be the duplicate declaration described above.
        let(:pre_condition) { 'include puppet' }
        let(:params) { { manage_nginx_core: true } }

        it { is_expected.to contain_class('lsys_nginx') }
      end

      describe 'address selection' do
        context 'with no listen_ip given' do
          let(:params) { { manage_nginx_core: false } }

          # First RFC 1918 address in interface order. Loopback is skipped for
          # free, being outside RFC 1918, and the public address is not chosen.
          it {
            expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:listen_ip]).to eq('10.154.5.6')
          }
        end

        context 'with an explicit private listen_ip' do
          let(:params) { { manage_nginx_core: false, listen_ip: '192.168.10.4' } }

          it { is_expected.to compile }
          it {
            expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:listen_ip]).to eq('192.168.10.4')
          }
        end

        context 'with a public listen_ip' do
          let(:params) { { manage_nginx_core: false, listen_ip: '203.0.113.10' } }

          it {
            is_expected.to compile.and_raise_error(%r{outside RFC 1918 private space})
          }
        end

        # 172.16.0.0/12 is 172.16 through 172.31 only. A bare "172." check would
        # wave these through as internal.
        ['172.15.0.1', '172.32.0.1'].each do |address|
          context "with #{address}, which is outside 172.16.0.0/12" do
            let(:params) { { manage_nginx_core: false, listen_ip: address } }

            it { is_expected.to compile.and_raise_error(%r{outside RFC 1918 private space}) }
          end
        end

        ['172.16.0.1', '172.31.255.254'].each do |address|
          context "with #{address}, which is inside 172.16.0.0/12" do
            let(:params) { { manage_nginx_core: false, listen_ip: address } }

            it { is_expected.to compile }
          end
        end

        context 'with a public listen_ip and use_external_ip => true' do
          let(:params) { { manage_nginx_core: false, listen_ip: '203.0.113.10', use_external_ip: true } }

          it { is_expected.to compile }
          it {
            expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:listen_ip]).to eq('203.0.113.10')
          }
        end

        context 'on a host with no private address and no listen_ip' do
          let(:facts) { os_facts.merge(networking: os_facts[:networking].merge(no_private_override)) }
          let(:params) { { manage_nginx_core: false } }

          # Refuses rather than guessing: a wrong guess here publishes Puppet
          # Server on whatever address it lands on.
          it { is_expected.to compile.and_raise_error(%r{no RFC 1918 private address found}) }
        end

        context 'on a host with no private address but use_external_ip => true' do
          let(:facts) { os_facts.merge(networking: os_facts[:networking].merge(no_private_override)) }
          let(:params) { { manage_nginx_core: false, use_external_ip: true } }

          it { is_expected.to compile }
          it {
            expect(catalogue.resource('nginx::resource::server', 'puppetserver')[:listen_ip]).to eq('203.0.113.10')
          }
        end
      end
    end
  end
end
