require 'hocon/config_factory'
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

Puppet::Type.type(:puppet_auth_rule).provide(
  :ruby2,
  :parent => Puppet::Type.type(:puppet_auth_rule).provider(:ruby), # rubocop:disable Style/HashSyntax
) do
  @doc = 'Puppet auth.conf rules'

  confine :exists => '/etc/puppet/puppetserver/conf.d/auth.conf'

  def self.auth_conf_file_name
    # @file_name is for unit testing
    @file_name ||= '/etc/puppet/puppetserver/conf.d/auth.conf'
  end

  # Optional defaults file
  def self.auth_conf_file
    @conf ||= File.read(auth_conf_file_name) if File.exist?(auth_conf_file_name)
  end

  def self.base_auth_rule
    { 'deny' => '*',
      'match-request' => {
        'path' => '/',
        'type' => 'path',
      },
      'name' => 'puppetlabs deny all',
      'sort-order' => 999 }
  end

  def self.base_conf_object
    empty = Hocon::Parser::ConfigDocumentFactory.parse_string('')
    auth_base = empty.set_value('authorization.version', '1')
    base_auth_rule_object = Hocon::ConfigValueFactory.from_map(base_auth_rule)
    rule_list = Hocon::ConfigValueFactory.from_any_ref([base_auth_rule_object])
    auth_base.set_config_value('authorization.rules', rule_list)
  end

  def self.auth_conf_object
    return @data if @data

    # read file content and remove shell quotes
    @data = if auth_conf_file
              Hocon::Parser::ConfigDocumentFactory.parse_string(auth_conf_file)
            else
              base_conf_object
            end
    @data
  end

  def self.auth_rules
    return @auth_rules if @auth_rules

    if auth_conf_file
      data = Hocon::ConfigFactory.parse_string(auth_conf_file)
      rules = data.get_list('authorization.rules').unwrapped
    else
      rules = [base_auth_rule]
    end

    @auth_rules ||= rules.map { |r| [r['name'], r] }.to_h
  end

  def self.sync_auth_rules
    rules = auth_rules.map { |_k, v| v }

    rule_list = Hocon::ConfigValueFactory.from_any_ref(rules.compact, nil)

    @data = auth_conf_object.set_config_value('authorization.rules', rule_list)
  end

  def self.update_auth_rules(rule)
    rule_name = rule['name']
    auth_rules[rule_name] = rule
  end

  def self.delete_auth_rules(rule_name)
    auth_rules[rule_name] = nil
  end

  def self.sync_file
    sync_auth_rules

    data = auth_conf_object.render
    File.open(auth_conf_file_name, 'w') do |fh|
      fh.puts(data)
    end
  end

  def self.instances
    return @instances if @instances
    @instances = []

    auth_rules.map do |entity_name, entity|
      entity['match-request'] = {} if entity['match-request'].to_s.empty?

      match_request_type   = entity['match-request']['type']
      match_request_path   = entity['match-request']['path']

      next unless match_request_type && match_request_path

      match_request_method = entity['match-request']['method'] unless entity['match-request']['method'].to_s.empty?

      allow = entity['allow'] unless entity['allow'].to_s.empty?
      deny  = entity['deny']  unless entity['deny'].to_s.empty?
      allow_unauthenticated = entity['allow-unauthenticated'].to_s.to_sym unless entity['allow-unauthenticated'].to_s.empty?

      next unless allow || deny || [:true, :false].include?(allow_unauthenticated)

      @instances << new(name: entity_name,
                        ensure: :present,
                        sort_order: entity['sort-order'],
                        allow: allow,
                        deny: deny,
                        allow_unauthenticated: allow_unauthenticated,
                        match_request_path: match_request_path,
                        match_request_type: match_request_type,
                        match_request_method: match_request_method,
                        provider: name)
    end

    @instances
  end

  def self.prefetch(resources)
    entities = instances
    # rubocop:disable Lint/AssignmentInCondition
    resources.each_key do |entity_name|
      if provider = entities.find { |entity| entity.name == entity_name }
        resources[entity_name].provider = provider
      end
    end
    # rubocop:enable Lint/AssignmentInCondition
  end
end
