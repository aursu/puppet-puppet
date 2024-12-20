# @summary Clean node certificates on Puppet controller node
#
# Bolt plan which run puppetserver ca clean command for each node on Puppet
# controller node as Bolt plan target
#
# @param targets
#   Puppet server(s) where certificate should be cleaned
#
# @param hosts
#   Nodes for which certificates should be cleaned
#
plan puppet::server::clean (
  TargetSpec $targets,
  Variant[Stdlib::Fqdn, Array[Stdlib::Fqdn]] $hosts,
) {
  run_plan(facts, $targets)

  $apply_results = apply($targets) {
    include puppet
    flatten($hosts).each |$host| {
      puppet::server::ca::clean { $host: }
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
