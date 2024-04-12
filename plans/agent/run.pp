plan puppet::agent::run (
  TargetSpec $targets,
  Boolean $noop = false,
  # run.rb:145:in `environment': undefined method `length' for nil:NilClass
  Optional[String[1]] $environment = 'x',
) {
  $results = run_plan('puppet_agent::run', $targets, 'noop' => $noop, 'environment' => $environment)

  $results.ok_set.each |$ok_result| {
    out::message("Run Puppet agent on ${ok_result.target} with success")
    out::message($ok_result.message)
  }

  $results.error_set.each |$err_result| {
    out::message("Run Puppet agent on ${err_result.target} with failure")
    out::message($err_result.error.message)
  }
}
