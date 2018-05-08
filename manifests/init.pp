# puppet
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include puppet
class puppet (
    String  $environment,
    String  $production_remote,
    String  $server,
    Optional[String]
            $ca_server,
    Optional[Array[String]]
            $dns_alt_names,
    Optional[String]
            $server_ipaddress,
    Boolean $hosts_update,
    String  $agent_version,
    Boolean $master,
    String  $server_version,
    String  $server_service_ensure,
    Boolean $server_service_enable,
    Boolean $use_common_env,
    String  $common_envname,
    String  $common_remote,
    Optional[Stdlib::Absolutepath]
            $basemodulepath,
    Puppet::Strictness
            $strict,
    Boolean $strict_variables,
    Boolean $daemonize,
    Puppet::TimeUnit
            $http_read_timeout,
    Puppet::Ordering
            $ordering,
    Optional[Puppet::Priority]
            $priority,
    Boolean $usecacheonfailure,
    Optional[Puppet::Autosign]
            $autosign,
    Puppet::TimeUnit
            $environment_timeout,
    Boolean $sameca,
    Boolean $allow_duplicate_certs,
    Boolean $use_enc,
    String  $enc_template,
    Optional[Stdlib::Absolutepath]
            $enc_data_source,
    Boolean $use_enc_env,
    String  $enc_envname,
    String  $enc_remote,
    Boolean $use_puppetdb,
    String  $r10k_yaml_template,
)
{}
