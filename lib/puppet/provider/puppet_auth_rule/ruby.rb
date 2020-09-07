require 'hocon/config_factory'
require 'hocon/parser/config_document_factory'
require 'hocon/config_value_factory'

Puppet::Type.type(:puppet_auth_rule).provide(:ruby) do
  @doc = 'Puppet auth.conf rules'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def self.auth_conf_file_name
    # @file_name is for unit testing
    @file_name ||= '/etc/puppetlabs/puppetserver/conf.d/auth.conf'
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
    resources.keys.each do |entity_name|
      if provider = entities.find { |entity| entity.name == entity_name }
        resources[entity_name].provider = provider
      end
    end
    # rubocop:enable Lint/AssignmentInCondition
  end

  def resource_rule
    name                      = @resource[:name]
    sort_order                = @resource.value(:sort_order)
    match_request_path        = @resource.value(:match_request_path)
    match_request_type        = @resource.value(:match_request_type)
    match_request_method      = @resource.value(:match_request_method) unless @resource.value(:match_request_method).to_s.empty?
    allow                     = @resource.value(:allow) unless @resource.value(:allow).to_s.empty?
    deny                      = @resource.value(:deny) unless @resource.value(:deny).to_s.empty?
    allow_unauthenticated     = @resource.value(:allow_unauthenticated) unless @resource.value(:allow_unauthenticated).to_s.empty?

    allow = allow[0] if allow && allow.size == 1
    deny  = deny[0] if deny && deny.size == 1
    if match_request_method
      match_request_method = if match_request_method.size == 1
                               match_request_method[0].to_s
                             else
                               match_request_method.map { |m| m.to_s }
                             end
    end

    rule = {}
    rule['name'] = name
    rule['sort-order'] = sort_order
    if allow
      rule['allow'] = allow unless allow == :absent
    end
    if deny
      rule['deny'] = deny unless deny == :absent
    end
    rule['allow-unauthenticated'] = allow_unauthenticated unless allow_unauthenticated.nil? || allow_unauthenticated == :absent
    rule['match-request'] = {}
    rule['match-request']['path'] = match_request_path
    rule['match-request']['type'] = match_request_type.to_s
    if match_request_method
      rule['match-request']['method'] = match_request_method unless match_request_method == 'absent'
    end

    rule
  end

  def create
    rule = resource_rule

    [:name, :sort_order, :allow, :deny, :allow_unauthenticated].each do |p|
      v = rule[p.to_s]
      @property_hash[p] = v if v
    end

    %w[path type method].each do |k|
      p = "match_request_#{k}".to_sym
      v = rule['match-request'][k]
      @property_hash[p] = v if v
    end

    self.class.update_auth_rules(rule)
    self.class.sync_file

    @property_hash[:ensure] = :present
  end

  def destroy
    name = @resource[:name]

    self.class.delete_auth_rules(name)
    self.class.sync_file

    @property_hash.clear
  end

  def exists?
    @property_hash[:ensure] == :present || false
  end

  def sort_order=(order)
    @property_flush[:sort_order] = order
  end

  def match_request_path=(path)
    @property_flush[:match_request_path] = path
  end

  def match_request_type=(request_type)
    @property_flush[:match_request_type] = request_type
  end

  def match_request_method=(method)
    @property_flush[:match_request_method] = method
  end

  def allow=(rule)
    @property_flush[:allow] = rule
  end

  def deny=(rule)
    @property_flush[:deny] = rule
  end

  def allow_unauthenticated=(rule)
    @property_flush[:allow_unauthenticated] = rule
  end

  def flush
    return if @property_flush.empty?
    @property_flush.clear

    rule = resource_rule
    self.class.update_auth_rules(rule)

    self.class.sync_file
  end
end
