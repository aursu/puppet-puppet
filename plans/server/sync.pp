# @summary Clean node certificates on Puppet controller node
#
# Bolt plan which run r10k command for each Puppet
# controller node as Bolt plan target
#
# @param targets
#   Puppet server(s) where manifests should be synced
#
plan puppet::server::sync (
  TargetSpec $targets,
) {
  run_plan(facts, $targets)

  return apply($targets) {
    include puppet

    class { 'puppet::r10k::run':
      cwd               => '/',
      setup_on_each_run => true,
    }
  }
}
