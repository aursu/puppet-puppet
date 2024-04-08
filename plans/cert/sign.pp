# @summary Signs node certificates on the Puppet server.
#
# This Bolt plan runs the 'puppetserver ca sign' command for each node on the
# Puppet controller node. The Bolt plan targets are the Nodes themselves.
#
# @param targets
#   Nodes for which the certificate signing requests should be signed.
#
# @param server
#   The Puppet controller server(s) on which the certificates should be signed.
#
plan puppet::cert::sign (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
) {
  $puppet_server = get_targets($server)

  run_plan(facts, $targets)

  # By default, the certname of the node is the host's fully qualified domain name (FQDN), as
  # determined by Facter.
  $nodes = get_targets($targets).map |$node| { $node.facts['fqdn'] }

  return run_plan('puppet::server::sign', 'targets' => $puppet_server, 'nodes' => $nodes)
}
