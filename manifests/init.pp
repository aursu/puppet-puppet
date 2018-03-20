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
    Boolean $r10k_deployment,
    String  $server_service_ensure,
    Boolean $server_service_enable,
    Boolean $use_common_env,
    String  $common_envname,
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
    Boolean $use_puppetdb,
)
{
    include puppet::repo
    include puppet::install
    include puppet::config
    include puppet::setup
    include puppet::service
}