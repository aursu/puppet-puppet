require 'spec_helper'

describe Puppet::Type.type(:puppet_auth_rule) do
  let(:resource) do
    described_class.new(
      name: 'puppetlabs cert status',
      match_request_path: '/puppet-ca/v1/certificate_status',
      match_request_type: 'path',
      match_request_method: [:get, :put, :delete],
      allow: { 'extensions' => { 'pp_cli_auth' => true } },
    )
  end

  it 'raises an error if match-request path is not a String' do
    expect { resource[:match_request_path] = true }.to raise_error \
      Puppet::Error, %r{A match-request rule must have a 'path' parameter of type String}
  end

  it 'raises an error if match-request path is empty' do
    expect { resource[:match_request_path] = '' }.to raise_error \
      Puppet::Error, %r{A match-request rule must have a non-empty 'path' parameter}
  end

  it 'raises an error if match-request type is invalid' do
    expect { resource[:match_request_type] = 'value' }.to raise_error \
      Puppet::Error, %r{Invalid value (.*)\. Valid values are regex, path\.}
  end

  it 'does not raise an error if match-request method is absent' do
    expect { resource[:match_request_method] = :absent }.not_to raise_error
  end

  it 'set default sort-order to 500' do
    expect(resource[:sort_order]).to be(500)
  end

  context 'check allow/deny values' do
    it 'raises an error if parameter is a map with invalid key' do
      expect { resource[:allow] = ['puppet.domain.tld', 'puppet2.domain.tld', { 'issuer' => 'Comodo' }] }.to \
        raise_error Puppet::Error, %r{The map values can contain an 'extensions' key that specifies an array}
    end

    it 'raises an error if parameter is a map with both valid keys' do
      expect { resource[:deny] = { 'extensions' => { 'pp_cli_auth' => true }, 'certname' => '*.domain.tld' } }.to \
        raise_error Puppet::Error, %r{Parameter can take a map value with either an extensions or certname key}
    end

    it 'raises an error if parameter is an empty map' do
      expect { resource[:allow] = {} }.to \
        raise_error Puppet::Error, %r{Parameter can take a map value with either an extensions or certname key}
    end

    it 'does not raise an error if parameter is absent' do
      expect { resource[:allow] = :absent }.not_to raise_error
    end
  end

  it 'does not raise an error if allow-unauthenticated is absent' do
    expect { resource[:allow_unauthenticated] = :absent }.not_to raise_error
  end

  it 'does not raise an error if allow-unauthenticated is boolean' do
    resource[:allow_unauthenticated] = false
    expect(resource[:allow_unauthenticated]).to be(:false)
  end

  it 'raises an error if allow-unauthenticated is :true and allow/deny is set' do
    expect {
      described_class.new(
        name: 'puppetlabs cert status',
        match_request_path: '/puppet-ca/v1/certificate_status',
        match_request_type: 'path',
        match_request_method: [:get, :put, :delete],
        allow_unauthenticated: true,
        allow: { 'extensions' => { 'pp_cli_auth' => true } },
      )
    }.to raise_error Puppet::Error, %r{A rule with allow-unauthenticated parameter set to true}
  end

  it 'raises an error allow, deny and allow-unauthenticated are unset' do
    expect {
      described_class.new(
        name: 'puppetlabs cert status',
        match_request_path: '/puppet-ca/v1/certificate_status',
        match_request_type: 'path',
        match_request_method: [:get, :put, :delete],
        allow: :absent,
      )
    }.to raise_error Puppet::Error, %r{Each rule's match-request section must have an allow, allow-unauthenticated, or deny}
  end

  it 'raises an error if path not provided' do
    expect {
      described_class.new(
        name: 'puppetlabs cert status',
        match_request_type: 'path',
        match_request_method: [:get, :put, :delete],
        allow: { 'extensions' => { 'pp_cli_auth' => true } },
      )
    }.to raise_error Puppet::Error, %r{A match-request rule must have a 'path' and 'type' parameters}
  end
end
