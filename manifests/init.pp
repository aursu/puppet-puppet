# puppet
#
# Puppet 5 installation module
#
# @summary Puppet 5 installation module
#
# @example
#   include puppet
class puppet (
  String $environment,
  String $production_remote,
  String $server,
  Optional[String] $ca_server,
  Optional[Array[String]] $dns_alt_names,
  Optional[String] $server_ipaddress,
  Boolean $hosts_update,
  String $agent_version,
  Boolean $master,
  String $server_version,
  String $server_service_ensure,
  Boolean $server_service_enable,
  Boolean $use_common_env,
  String $common_envname,
  String $common_remote,
  Optional[Stdlib::Absolutepath] $basemodulepath,
  Puppet::Strictness $strict,
  Boolean $strict_variables,
  Boolean $daemonize,
  Boolean $onetime,
  Optional[Puppet::TimeUnit] $runtimeout,
  Puppet::TimeUnit $http_read_timeout,
  Puppet::Ordering $ordering,
  Optional[Puppet::Priority] $priority,
  Boolean $usecacheonfailure,
  Optional[Puppet::Autosign] $autosign,
  Puppet::TimeUnit $environment_timeout,
  Boolean $sameca,
  Boolean $allow_duplicate_certs,
  Boolean $use_enc,
  String  $enc_template,
  Optional[Stdlib::Absolutepath] $enc_data_source,
  String $enc_envname,
  String $enc_remote,
  Boolean $use_puppetdb,
  Boolean $r10k_config_setup,
  String $r10k_yaml_template,
  String $r10k_cachedir,
  Boolean $r10k_crontab_setup,
  Boolean $environment_setup_on_each_run,
  Boolean $external_facts_setup,
  Boolean $static_certname,
  String  $certname = $facts['networking']['fqdn'],
  Boolean $manage_webserver_conf,
) {}
