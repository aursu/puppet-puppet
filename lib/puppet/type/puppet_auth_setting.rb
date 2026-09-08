#
Puppet::Type.newtype(:puppet_auth_setting) do
  @doc = <<-PUPPET
    Manages a setting inside the `authorization` section of Puppet Server's
    auth.conf, alongside but separate from the `rules` list that
    `puppet_auth_rule` owns.

    Exists because the rule type can only add, change and remove entries in
    `authorization.rules`. Settings that sit next to that list - most notably
    `allow-header-cert-info` - are unreachable through it, and hand-editing them
    puts a security-relevant value outside configuration management.

    @example Trust client identity supplied by a terminating proxy
      puppet_auth_setting { 'allow-header-cert-info':
        ensure => present,
        value  => true,
      }
  PUPPET

  ensurable do
    desc 'Create or remove the setting.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc <<-PUPPET
      Setting name, relative to the `authorization` section. A dotted path is
      accepted for nested settings; a bare name such as `allow-header-cert-info`
      refers to `authorization.allow-header-cert-info`.
    PUPPET

    validate do |value|
      raise ArgumentError, _('Setting name must not be empty') if value.to_s.strip.empty?
      raise ArgumentError, _('Setting name must not start with "authorization." - it is implied') if value.to_s.start_with?('authorization.')
    end
  end

  newproperty(:value) do
    desc <<-PUPPET
      Value to set. Booleans, numbers and strings are supported.

      ⚠ Take particular care with `allow-header-cert-info`. Setting it true tells
      Puppet Server to take the client's identity from `X-Client-*` request
      headers instead of the TLS client certificate, which is correct only when a
      proxy terminates TLS *and* Puppet Server is unreachable except through it.
      Enabled without that isolation, any client that can open a connection can
      claim to be any node.
    PUPPET

    munge do |value|
      case value
      when true, 'true', :true then true
      when false, 'false', :false then false
      when %r{\A-?\d+\z} then value.to_i
      else value
      end
    end

    def insync?(is)
      # The parsed file yields real types, while a manifest may express the same
      # value as a string. Compare on that basis rather than reporting a change
      # on every run.
      is.to_s == should.to_s
    end
  end
end
