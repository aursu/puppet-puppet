# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:puppet_auth_setting) do
  let(:setting) { described_class.new(name: 'allow-header-cert-info', value: true) }

  it 'accepts a bare setting name' do
    expect(setting[:name]).to eq('allow-header-cert-info')
  end

  it 'defaults to present' do
    expect(setting[:ensure]).to eq(:present)
  end

  # The provider prefixes `authorization.` itself. Accepting it here as well
  # would produce authorization.authorization.x - a setting that silently does
  # nothing, which is the worst outcome for a security flag.
  it 'rejects a name that already carries the authorization prefix' do
    expect {
      described_class.new(name: 'authorization.allow-header-cert-info', value: true)
    }.to raise_error(Puppet::Error, %r{must not start with "authorization\."})
  end

  it 'rejects an empty name' do
    expect { described_class.new(name: '  ', value: true) }.to raise_error(Puppet::Error, %r{must not be empty})
  end

  describe 'value munging' do
    # A manifest may express the same value as a boolean or a string depending on
    # where it came from - Hiera, a parameter default, a literal. They have to
    # land on the same thing or the resource reports a change on every run.
    {
      true => true,
      'true' => true,
      false => false,
      'false' => false,
      '42' => 42,
      'a-string' => 'a-string',
    }.each do |input, expected|
      it "munges #{input.inspect} to #{expected.inspect}" do
        expect(described_class.new(name: 'setting', value: input)[:value]).to eq(expected)
      end
    end
  end

  describe 'insync?' do
    let(:property) { described_class.new(name: 'setting', value: true).property(:value) }

    it 'treats a boolean read from the file as in sync with a boolean in the manifest' do
      expect(property.insync?(true)).to be true
    end

    # The parsed document yields real types; comparing on to_s is what stops a
    # spurious change being reported every run.
    it 'treats a string read from the file as in sync with the equivalent boolean' do
      expect(property.insync?('true')).to be true
    end

    it 'reports out of sync when the values genuinely differ' do
      expect(property.insync?(false)).to be false
    end
  end
end
