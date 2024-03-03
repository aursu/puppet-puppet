# @summary Implements a local Bolt module for assets storage.
#
# Designed to store assets in the module's files directory, this module facilitates
# the secure transfer of these assets to the Puppet server using the file_upload function in Bolt.
# It's ideal for managing and deploying configuration files, scripts, and other necessary assets
# required for Puppet server bootstrap.
#
# @example
#   upload_file('bootstrap_assets/gitservers.txt', '/root/bootstrap/gitservers.txt', $target)
class bootstrap_assets {
}
