# @summary Signs node certificates on the Puppet controller node.
#
# This Bolt plan runs the 'puppetserver ca sign' command for each specified node on the
# Puppet controller node, treating it as the target for this Bolt plan. The
# `$nodes` parameter can include both fully qualified domain names (FQDNs) and
# separate certificate names (certnames), allowing for flexible specification of
# targets for certificate signing.
#
# @param targets
#   Puppet server(s) on which certificates should be signed.
#
# @param hosts
#   Nodes or certnames for which certificate signing requests should be signed.
#
plan puppet::server::sign (
  TargetSpec $targets,
  Variant[Stdlib::Fqdn, Array[Stdlib::Fqdn]] $hosts,
) {
  run_plan(facts, $targets)

  $apply_results = apply($targets) {
    include puppet
    flatten($hosts).each |$host| {
      puppet::server::ca::sign { $host: }
    }
  }

  # Print log messages from the report
  $apply_results.each |$result| {
    $result.report['logs'].each |$log| {
      out::message("${log['level'].capitalize}: ${log['source']}: ${log['message']}")
    }
  }

  return $apply_results
}
