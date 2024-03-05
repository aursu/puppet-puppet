plan bootstrap_assets::upload (
  TargetSpec $targets = 'puppetservers',
  Stdlib::Unixpath $path = '/root/bootstrap',
) {
  run_task(bootstrap_assets::assets_dir, $targets, path => $path)

  upload_file('bootstrap_assets/gitservers.txt', "${path}/gitservers.txt", $targets)
  upload_file('bootstrap_assets/r10k.yaml', "${path}/r10k.yaml", $targets)

  $eyaml_keys = ['keys/private_key.pkcs7.pem', 'keys/public_key.pkcs7.pem']
  $eyaml_keys.each |$key| {
    if file::exists("bootstrap_assets/${key}") {
      upload_file("bootstrap_assets/${key}", "${path}/${key}", $targets)
    }
  }

  $pki_components = ['ca/ca_key.pem', 'ca/ca_crt.pem', 'ca/ca_crl.pem']
  $pki_components.each |$comp| {
    if file::exists("bootstrap_assets/${comp}") {
      upload_file("bootstrap_assets/${comp}", "${path}/${comp}", $targets)
    }
  }
}
