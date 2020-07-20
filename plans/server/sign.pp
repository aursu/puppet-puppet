# @summary Sign node certificates on Puppet controller node
#
# Bolt plan which run puppetserver ca sign command for each node on Puppet
# controller node as Bolt plan target
#
# @param targets
#   Puppet server(s) where certificate should be signed
#
# @param nodes
#   Nodes for which certificate signing requesgts should be signed
#
plan puppet::server::sign (
  TargetSpec $targets,
  Array[Stdlib::Fqdn] $nodes,
) {
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet
    $nodes.each |$node| {
      puppet::server::ca::sign { $node: }
    }
  }
}
