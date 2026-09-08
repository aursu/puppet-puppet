require 'hocon/config_factory'
require 'hocon/config_value_factory'
require File.expand_path(File.join(__dir__, '..', '..', '..', 'puppet_x', 'puppetserver', 'auth_conf'))

Puppet::Type.type(:puppet_auth_setting).provide(:ruby) do
  @doc = 'Settings in the authorization section of Puppet auth.conf'

  mk_resource_methods

  # File reading, the parsed document and the write are all shared with
  # puppet_auth_rule via PuppetX::Puppetserver::AuthConf. That is deliberate: both types
  # edit the same file, and a provider holding its own copy of the document would
  # render it back over the whole file and drop whatever the other type changed in
  # the same run.

  # Structural keys owned elsewhere: `rules` belongs to puppet_auth_rule, and
  # `version` to Puppet Server itself. Managing either from here would fight them.
  RESERVED_KEYS = %w[rules version].freeze

  def self.auth_settings
    return @auth_settings if @auth_settings

    @auth_settings = {}

    config = PuppetX::Puppetserver::AuthConf.config
    return @auth_settings unless config
    return @auth_settings unless config.has_path?('authorization')

    config.get_config('authorization').root.unwrapped.each do |key, value|
      next if RESERVED_KEYS.include?(key)
      # Scalars only. A nested block under `authorization` is a structure this
      # type cannot express, and flattening it would corrupt the file.
      next if value.is_a?(Hash) || value.is_a?(Array)

      @auth_settings[key] = value
    end

    @auth_settings
  end

  def self.instances
    auth_settings.map do |key, value|
      new(name: key, ensure: :present, value: value, provider: name)
    end
  end

  def self.prefetch(resources)
    found = instances
    resources.each_key do |name|
      provider = found.find { |i| i.name == name }
      resources[name].provider = provider if provider
    end
  end

  def self.set_setting(key, value)
    rendered = Hocon::ConfigValueFactory.from_any_ref(value, nil).render
    PuppetX::Puppetserver::AuthConf.document = PuppetX::Puppetserver::AuthConf.document.set_value("authorization.#{key}", rendered)
    auth_settings[key] = value
  end

  def self.remove_setting(key)
    PuppetX::Puppetserver::AuthConf.document = PuppetX::Puppetserver::AuthConf.document.remove_value("authorization.#{key}")
    auth_settings.delete(key)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    self.class.set_setting(resource[:name], resource[:value])
    PuppetX::Puppetserver::AuthConf.save
    @property_hash[:ensure] = :present
    @property_hash[:value] = resource[:value]
  end

  def destroy
    self.class.remove_setting(resource[:name])
    PuppetX::Puppetserver::AuthConf.save
    @property_hash.clear
  end

  def value=(new_value)
    self.class.set_setting(resource[:name], new_value)
    PuppetX::Puppetserver::AuthConf.save
    @property_hash[:value] = new_value
  end
end
