plan bootstrap_assets::upload (
  TargetSpec $targets = 'puppetservers',
  Stdlib::Unixpath $path = '/root/bootstrap',
) {
  run_plan(facts, $targets)

  apply($targets) {
    file { $path: ensure => directory }
  }

  upload_file('bootstrap_assets/gitservers.txt', "${path}/gitservers.txt", $targets)
  upload_file('bootstrap_assets/r10k.yaml', "${path}/r10k.yaml", $targets)
}
