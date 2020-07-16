plan puppet::agent5::install (
  TargetSpec $targets,
)
{
  return run_task('puppet_agent::install', $targets, collection => 'puppet5', stop_service => true)
}
