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
    Optional[Array[String]]
            $server_aliases,
    Optional[String]
            $server_ipaddress,
    Boolean $hosts_update,
    String  $agent_version,
    Boolean $master,
    String  $server_version,
    Boolean $r10k_deployment,
    String  $server_service_ensure,
    Boolean $server_service_enable,
)
{
    include puppet::repo
    include puppet::install
    include puppet::setup
    include puppet::service
}