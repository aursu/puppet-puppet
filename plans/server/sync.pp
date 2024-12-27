# @summary Sync Puppet manifests on specified Puppet controller nodes
#
# This Bolt plan runs the r10k command on each Puppet controller node specified in the target.
# It ensures that the latest manifests are synced.
#
# @param targets
#   Puppet server(s) where the manifests should be synced.
#
plan puppet::server::sync (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  # Gather facts about the target nodes
  run_plan('facts', $targets)

  # Apply the puppet::r10k::run class on each target node
  return apply($targets) {
    class { 'puppet::globals':
      platform_name => $collection,
    }

    include puppet

    class { 'puppet::r10k::run':
      cwd               => '/',
      setup_on_each_run => true,
    }
  }
}
