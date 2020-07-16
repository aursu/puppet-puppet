plan puppet::bootstrap (
  TargetSpec $targets,
  Stdlib::Fqdn
            $master,
) {
  run_plan('puppet::agent5::install', $targets)
}
