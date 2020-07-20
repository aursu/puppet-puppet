require 'spec_helper'
require 'tempfile'

describe Puppet::Type.type(:puppet_auth_rule).provider(:ruby) do
  let(:resource_name) { 'puppetlabs cert status' }
  let(:resource) do
    Puppet::Type.type(:puppet_auth_rule).new(
      name: resource_name,
      ensure: :present,
      match_request_path: '/puppet-ca/v1/certificate_status',
      match_request_type: :path,
      match_request_method: [:delete, :put, :get],
      allow: { 'extensions' => { 'pp_cli_auth' => true } },
      provider: 'ruby',
    )
  end
  let(:provider) do
    provider = subject
    provider.resource = resource
    provider
  end
  let(:tmppath) { Tempfile.new('auth.conf', '/tmp').path }

  before(:each) do
    described_class.instance_variable_set('@file_name', tmppath)
    described_class.instance_variable_set('@conf', File.read(Dir.pwd + '/spec/fixtures/files/auth.conf'))
  end

  context 'check auth rules' do
    it {
      auth_rules = described_class.auth_rules

      expect(auth_rules[resource_name]).to eq(
        'match-request' => { 'method' => %w[get put delete], 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => { 'extensions' => { 'pp_cli_auth' => 'true' } },
        'sort-order' => 500,
        'name' => resource_name,
      )
    }
  end

  context 'check match-request path is in sync' do
    let(:property) { resource.property(:match_request_path) }

    it {
      auth_rules = described_class.auth_rules
      expect(property).to be_insync(auth_rules[resource_name]['match-request']['path'])
    }
  end

  context 'check match-request type is in sync' do
    let(:property) { resource.property(:match_request_type) }

    it {
      auth_rules = described_class.auth_rules
      expect(property).to be_insync(auth_rules[resource_name]['match-request']['type'])
    }
  end

  context 'check match-request method is in sync' do
    let(:property) { resource.property(:match_request_method) }

    it {
      auth_rules = described_class.auth_rules
      expect(property).to be_insync(auth_rules[resource_name]['match-request']['method'])
    }
  end

  context 'check resource method field removal' do
    let(:resource) do
      Puppet::Type.type(:puppet_auth_rule).new(
        name: resource_name,
        ensure: :present,
        match_request_path: '/puppet-ca/v1/certificate_status',
        match_request_type: 'path',
        match_request_method: :absent,
        allow: { 'extensions' => { 'pp_cli_auth' => true } },
        provider: 'ruby',
      )
    end

    it {
      expect(provider.resource_rule).to eq(
        'match-request' => { 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => { 'extensions' => { 'pp_cli_auth' => true } },
        'sort-order' => 500,
        'name' => resource_name,
      )
    }
  end

  context 'check resource method field setup' do
    let(:resource) do
      Puppet::Type.type(:puppet_auth_rule).new(
        name: resource_name,
        ensure: :present,
        match_request_path: '/puppet-ca/v1/certificate_status',
        match_request_type: 'path',
        match_request_method: :get,
        allow: { 'extensions' => { 'pp_cli_auth' => true } },
        provider: 'ruby',
      )
    end
    let(:property) { resource.property(:match_request_method) }

    it {
      auth_rules = described_class.auth_rules
      expect(property).not_to be_insync(auth_rules[resource_name]['match-request']['method'])
    }

    it {
      expect(provider.resource_rule).to eq(
        'match-request' => { 'method' => 'get', 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => { 'extensions' => { 'pp_cli_auth' => true } },
        'sort-order' => 500,
        'name' => resource_name,
      )
    }

    it {
      provider.create
      expect(described_class.auth_rules[resource_name]).to eq(
        'match-request' => { 'method' => 'get', 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => { 'extensions' => { 'pp_cli_auth' => true } },
        'sort-order' => 500,
        'name' => resource_name,
      )
      expect(File.read(tmppath)).to match(%r{"match-request": \{\n\s+"method": "get",\n\s+"path": "/puppet-ca/v1/certificate_status",\n\s+"type": "path"\n\s+\}})
    }
  end

  context 'check resource method field setup with array' do
    let(:resource) do
      Puppet::Type.type(:puppet_auth_rule).new(
        name: resource_name,
        ensure: :present,
        match_request_path: '/puppet-ca/v1/certificate_status',
        match_request_type: :path,
        match_request_method: [:delete, :put, :get],
        allow: [{ 'extensions' => { 'pp_cli_auth' => true } }, 'puppet1.domain.tld'],
        provider: 'ruby',
      )
    end

    it {
      expect(provider.resource_rule).to eq(
        'match-request' => { 'method' => %w[delete put get], 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => [{ 'extensions' => { 'pp_cli_auth' => true } }, 'puppet1.domain.tld'],
        'sort-order' => 500,
        'name' => resource_name,
      )
    }

    it {
      provider.create
      expect(described_class.auth_rules[resource_name]).to eq(
        'match-request' => { 'method' => %w[delete put get], 'path' => '/puppet-ca/v1/certificate_status', 'type' => 'path' },
        'allow' => [{ 'extensions' => { 'pp_cli_auth' => true } }, 'puppet1.domain.tld'],
        'sort-order' => 500,
        'name' => resource_name,
      )
      expect(File.read(tmppath)).to match(%r{"allow": \[\n\s+\{\n\s+"extensions": \{\n\s+"pp_cli_auth": true\n\s+\}\n\s+\},\n\s+"puppet1.domain.tld"\n\s+\],})
    }
  end
end
