#
Puppet::Type.newtype(:puppet_auth_rule) do
  #
  class ACLProperty < Puppet::Property
    def acl_validate(value)
      # The string values can contain
      # - An exact domain name, such as www.example.com
      # - A glob of names containing a * in the first segment, such as
      #   *.example.com or simply *.
      # - A regular expression surrounded by / characters, such as /example/.
      # - A backreference to a regular expression’s capture group in the path
      #   value, if the rule also contains a type value of regex.
      return true if value.is_a?(String)
      if value.is_a?(Hash)
        value.each do |k, _v|
          # The map values can contain:
          # - An 'extensions' key that specifies an array of matching X.509 extensions. Puppet
          #  Server authenticates the request only if each key in the map appears in the
          #  request, and each key's value exactly matches.
          # - A 'certname' key equivalent to a bare string.
          next if k == 'extensions' && value[k].is_a?(Hash)
          next if k == 'certname' && value[k].is_a?(String)
          raise ArgumentError, _(<<-PUPPET)
            The map values can contain an 'extensions' key that specifies an array of
            matching X.509 extensions or a 'certname' key equivalent to a bare string.
          PUPPET
        end
        raise ArgumentError, _('Parameter can take a map value with either an extensions or certname key') unless value.size == 1
        return true
      end
      raise ArgumentError, _(<<-PUPPET)
        This parameter can take a single string value, an array of string values, a
        single map value with either an extensions or certname key, or an array of string
        and map values.
      PUPPET
    end

    validate do |value|
      next if value == :absent
      if value.is_a?(Array)
        value.each { |a| acl_validate(a) }
      else
        acl_validate(value)
      end
    end

    munge do |value|
      extensions = value['extensions'] if value.is_a?(Hash)
      value['extensions'] = extensions.map { |k, v| [k, v.to_s] }.to_h if extensions
      value
    end
  end

  ensurable do
    desc 'Create or remove the rule.'

    defaultvalues
    defaultto :present
  end

  newparam(:name, namevar: true) do
    desc 'Unique string value identifies the rule to Puppet Server'
  end

  newproperty(:match_request_path) do
    desc 'The parameter path can be a literal string or regular expression'

    validate do |value|
      raise ArgumentError, _("A match-request rule must have a 'path' parameter of type String (got #{value.class})") unless value.is_a?(String)
      raise ArgumentError, _("A match-request rule must have a non-empty 'path' parameter") if value.empty?
    end
  end

  newproperty(:match_request_type) do
    desc <<-PUPPET
      Type of the perameter path. The parameter path can be a literal string or regular
      expression.
    PUPPET

    newvalues(:regex, :path)
  end

  newproperty(:match_request_method, array_matching: :all) do
    desc <<-PUPPET
      Puppet Server applies that rule only to requests that use its value's
      listed HTTP methods.
    PUPPET

    newvalues(:get, :post, :put, :delete, :head)

    def insync?(is)
      # is == :absent in case of non-existing match-request method
      return @should == [:absent] if is.nil? || is == []

      [is].flatten.map { |m| m.to_s }.sort == [should].flatten.map { |m| m.to_s }.sort
    end

    validate do |value|
      next if value == :absent
      super(value)
    end
  end

  newproperty(:allow, array_matching: :all, parent: ACLProperty) do
    desc <<-PUPPET
      If the request's authenticated name matches the parameter's value, Puppet
      Server allows it.
    PUPPET
  end

  newproperty(:deny, array_matching: :all, parent: ACLProperty) do
    desc <<-PUPPET
      Refuses the request if the authenticated name matches - even if the rule
      contains an allow value that also matches.
    PUPPET
  end

  newproperty(:sort_order) do
    desc <<-PUPPET
      Sets the order in which Puppet Server evaluates the rule by prioritizing
      it on a numeric value between 1 and 399 (to be evaluated before default Puppet
      rules) or 601 to 998 (to be evaluated after Puppet), with lower-numbered values
      evaluated first.
    PUPPET

    newvalue(%r{\d+})
    defaultto 500
  end

  newproperty(:allow_unauthenticated) do
    desc 'Enable domain (default)'

    newvalues(:true, :false)

    validate do |value|
      next if value == :absent
      super(value)
    end
  end

  validate do
    return true if self[:ensure] == :absent

    allow_unset = (self[:allow].nil? || self[:allow] == [:absent])
    deny_unset = (self[:deny].nil? || self[:deny] == [:absent])

    if allow_unset && deny_unset
      raise(Puppet::Error, "Each rule's match-request section must have an allow, allow-unauthenticated, or deny parameter") unless [:true, :false].include?(self[:allow_unauthenticated])
    elsif self[:allow_unauthenticated] == :true
      raise(Puppet::Error, "A rule with allow-unauthenticated parameter set to true can't also contain the allow or deny parameters.")
    end

    raise(Puppet::Error, "A match-request rule must have a 'path' and 'type' parameters") unless self[:match_request_path] && self[:match_request_type]
  end
end
