plan puppet::repo (
  TargetSpec $targets,
  Puppet::Platform $collection = 'puppet8',
) {
  run_plan(facts, $targets)

  return apply($targets) {
    run_task(
      'puppet::repo',
      $target,
      "Install Puppet platform repo on ${target_name}",
      '_catch_errors' => true,
      '_run_as'       => 'root',
      'collection'    => $collection
    )
  }
}
