# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

describe Puppet::Type.type(:puppet_auth_setting).provider(:ruby) do
  let(:resource_name) { 'allow-header-cert-info' }
  let(:resource) do
    Puppet::Type.type(:puppet_auth_setting).new(
      name: resource_name,
      ensure: :present,
      value: true,
    )
  end
  let(:provider) do
    provider = subject
    provider.resource = resource
    provider
  end
  let(:tmppath) { Tempfile.new('auth.conf', '/tmp').path }

  before(:each) do
    PuppetX::Puppetserver::AuthConf.reset!
    PuppetX::Puppetserver::AuthConf.file_name = tmppath
    PuppetX::Puppetserver::AuthConf.content = File.read(Dir.pwd + '/spec/fixtures/files/auth.conf')
    described_class.instance_variable_set('@auth_settings', nil)
  end

  context 'reading existing settings' do
    it 'ignores the structural keys owned by other things' do
      # `rules` belongs to puppet_auth_rule and `version` to Puppet Server.
      # Surfacing either here would let this type fight them.
      expect(described_class.auth_settings.keys).not_to include('rules')
      expect(described_class.auth_settings.keys).not_to include('version')
    end

    it 'produces no instance for a setting that is absent' do
      expect(described_class.instances.map(&:name)).not_to include('allow-header-cert-info')
    end
  end

  context 'creating a setting' do
    before(:each) { provider.create }

    it 'writes it into the authorization section' do
      expect(File.read(tmppath)).to match(%r{allow-header-cert-info\s*[:=]\s*true})
    end

    it 'keeps the rules list intact' do
      # The whole reason the document is shared: writing a setting must not
      # discard the rules another type owns.
      expect(File.read(tmppath)).to match(%r{puppetlabs cert status})
    end

    it 'reports the setting as present' do
      expect(provider.exists?).to be true
    end
  end

  context 'changing a setting' do
    before(:each) do
      provider.create
      provider.value = false
    end

    it 'writes the new value' do
      expect(File.read(tmppath)).to match(%r{allow-header-cert-info\s*[:=]\s*false})
    end

    it 'does not leave the previous value behind' do
      expect(File.read(tmppath)).not_to match(%r{allow-header-cert-info\s*[:=]\s*true})
    end
  end

  context 'removing a setting' do
    before(:each) do
      provider.create
      provider.destroy
    end

    it 'drops it from the file' do
      expect(File.read(tmppath)).not_to match(%r{allow-header-cert-info})
    end

    it 'keeps the rules list intact' do
      expect(File.read(tmppath)).to match(%r{puppetlabs cert status})
    end
  end

  context 'sharing the document with puppet_auth_rule' do
    # The bug this guards against: two providers each parsing their own copy of
    # auth.conf and each rendering it back over the whole file, so whichever
    # flushed last discarded the other's work.
    it 'uses the same parsed document as the rule provider' do
      rule_provider = Puppet::Type.type(:puppet_auth_rule).provider(:ruby)

      expect(rule_provider.auth_conf_object).to be(PuppetX::Puppetserver::AuthConf.document)
      expect(rule_provider.auth_conf_file_name).to eq(tmppath)
    end
  end
end
