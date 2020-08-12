# @summary Clean node certificates on Puppet controller node
#
# Bolt plan which run puppetserver ca clean command for each node on Puppet
# controller node as Bolt plan target
#
# @param targets
#   Puppet server(s) where certificate should be cleaned
#
# @param nodes
#   Nodes for which certificates should be cleaned
#
plan puppet::server::clean (
  TargetSpec $targets,
  Array[Stdlib::Fqdn] $nodes,
) {
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    $nodes.each |$node| {
      puppet::server::ca::clean { $node: }
    }
  }
}
