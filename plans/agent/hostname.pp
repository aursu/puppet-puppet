# @summary Set hostname on target hosts
#
# Set hostname on target hosts
#
# @param targets
#   Nodes for which hostname should be set
#
plan puppet::agent::hostname (
  TargetSpec $targets,
) {
  get_targets($targets).each |$target| {
    run_task(
      'puppet::hostname',
      $target,
      "Set hostname on ${target.name}",
      '_catch_errors' => true,
      '_run_as' => 'root',
      'hostname' => $target.name
    )
  }
}
