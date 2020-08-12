# @summary Clean node certificates on Puppet server
#
# Bolt plan which run puppetserver ca clean command for each node on Puppet
# controller node. The Bolt plan targets are Nodes
#
# @param targets
#   Nodes for which certificate should be cleaned
#
# @param server
#   Puppet controller server(s) on which certificate should be cleaned
#
plan puppet::cert::clean (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
) {
  $puppet_server = get_targets($server)

  $nodes = get_targets($targets).map |$node| { $node.name }

  return run_plan('puppet::server::clean', 'targets' => $puppet_server, 'nodes' => $nodes)
}
