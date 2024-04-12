# @summary Set hostname on target hosts
#
# Set hostname on target hosts
#
# @param targets
#   Nodes for which hostname should be set
#
plan puppet::agent::hostname (
  TargetSpec $targets,
  Optional[Stdlib::Fqdn] $hostname = undef,
) {
  if $hostname and get_targets($targets).size > 1 {
    fail("You can set up the hostname \"${hostname}\" on only one target.")
  }

  get_targets($targets).each |$target| {
    $target_name = $hostname ? {
      Stdlib::Fqdn => $hostname,
      default      => $target.name,
    }

    run_task(
      'puppet::hostname',
      $target,
      "Set hostname on ${target_name}",
      '_catch_errors' => true,
      '_run_as'       => 'root',
      'hostname'      => $target_name,
    )
  }
}
