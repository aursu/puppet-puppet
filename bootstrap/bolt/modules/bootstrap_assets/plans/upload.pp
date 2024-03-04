plan bootstrap_assets::upload (
  TargetSpec $targets = 'puppetservers',
  Stdlib::Unixpath $path = '/root/bootstrap',
) {
  run_plan(facts, $targets)

  run_task(bootstrap_assets::assets_dir, $targets)

  upload_file('bootstrap_assets/gitservers.txt', "${path}/gitservers.txt", $targets)
  upload_file('bootstrap_assets/r10k.yaml', "${path}/r10k.yaml", $targets)
}
