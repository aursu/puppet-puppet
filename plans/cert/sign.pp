# @summary Signs node certificates on the Puppet server.
#
# This Bolt plan executes the 'puppetserver ca sign' command for each specified node
# on the Puppet controller node, with the plan targets being the nodes themselves. It
# supports specifying either a list of nodes via the `targets` parameter or a single node
# by its certificate name (`certname`)
#
# @param targets
#   Nodes for which the certificate signing requests should be signed. This parameter is
#   used unless a specific `certname` is provided.
#
# @param server
#   The Puppet controller server(s) on which the certificates should be signed.
#
# @param certname
#   Optional. The certificate name of a single node to sign. If specified, this takes
#   precedence over the list of `targets`.
#
plan puppet::cert::sign (
  TargetSpec $targets,
  Stdlib::Fqdn $server,
  Optional[String] $certname = undef,
) {
  $server_name = get_targets($server)

  run_plan(facts, $targets)

  # By default, the certname of the node is the host's fully qualified domain name (FQDN), as
  # determined by Facter.
  if $certname {
    $nodes = [$certname]
  }
  else {
    $nodes = get_targets($targets).map |$node| { $node.facts['fqdn'] }
  }

  return run_plan('puppet::server::sign', 'targets' => $server_name, 'nodes' => $nodes)
}
