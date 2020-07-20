# @summary Sign node certificates on Puppet server
#
# Bolt plan which run puppetserver ca sign command for each node on Puppet
# controller node. The Bolt plan targets are Nodes
#
# @param targets
#   Nodes for which certificate signing requests should be signed
#
# @param server
#   Puppet controller server(s) on which certificate should be signed
#
plan puppet::cert::sign (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
) {
  $puppet_server = get_targets($server)

  $nodes = get_targets($targets).map |$node| { $node.name }

  return run_plan('puppet::server::sign', 'targets' => $puppet_server, 'nodes' => $nodes)
}
