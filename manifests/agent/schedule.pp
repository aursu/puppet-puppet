# @summary Puppet agent cron settings
#
# Puppet agent cron settings
#
# @example
#   include puppet::agent::schedule
#
# @param enable
# @param job_name
# @param job_arguments
# @param verbose
# @param reboot_job
# @param file_backups_cleanup
# @param file_backups_ttl
#
# @param puppet_path
#   Puppet agent binary path
#
# @param disable_daemon
#   Whether to stop and mask the Puppet agent *daemon*. Left `undef` it follows
#   `$enable`, which is the honest coupling: cron and the daemon are two ways of
#   scheduling the same agent, and running both means they collide.
#
#   The collision is not theoretical. The agent takes a run lock, so whichever
#   mechanism starts second exits non-zero: at boot the daemon finds the
#   cron-driven run's `agent_catalog_run.lock`, gives up, and systemd records
#   `puppet.service` as **failed** for the rest of the host's life. Agent runs
#   are unaffected, but the host carries a permanently failed unit — and a fleet
#   where every host has one is a fleet where `systemctl --failed` no longer
#   means anything.
#
#   ⚠ The agent package **enables the daemon on install**, so this is not a
#   one-time cleanup: without management it comes back on the next agent
#   upgrade. That is why the disabled branch uses `mask` rather than `false`.
#
#   Set it explicitly to `false` on a host that genuinely wants the daemon while
#   still having `$enable` true for the reboot job, and to `true` on a host with
#   no cron schedule that should nonetheless not run the daemon.
#
# @param daemon_service_name
#   Name of the agent daemon service. `puppet` on every currently supported
#   platform; parameterised rather than hardcoded so a rename does not require
#   a module change.
#
class puppet::agent::schedule (
  Boolean $enable = true,
  String $job_name = 'puppet agent run',
  Array[String] $job_arguments = [
    '--onetime',
    '--no-daemonize',
    '--no-usecacheonfailure',
    '--detailed-exitcodes',
    '--no-splay',
  ],
  Boolean $verbose = true,
  Boolean $reboot_job = true,
  Boolean $file_backups_cleanup = true,
  Integer $file_backups_ttl = 45,
  Stdlib::Unixpath $puppet_path = $puppet::globals::puppet_path,
  Optional[Boolean] $disable_daemon = undef,
  String[1] $daemon_service_name = 'puppet',
) inherits puppet::globals {
  # ⚠ `Optional[Boolean]` cannot be resolved with plain truthiness here the way
  # an `Optional[Integer]` can: `false` is both a falsy value and a meaningful
  # answer, so `if $disable_daemon` would silently treat "explicitly do not
  # disable" as "not specified". The undef test has to be explicit.
  if $disable_daemon =~ NotUndef {
    $manage_daemon_disabled = $disable_daemon
  }
  else {
    $manage_daemon_disabled = $enable
  }

  # Managed in BOTH directions on purpose. Declaring the resource only in the
  # disabled branch would leave a masked unit behind the moment somebody set
  # `disable_daemon => false` — the resource would simply vanish from the
  # catalogue and Puppet would never unmask what it had masked.
  #
  # The provider is named explicitly because Puppet's default on Debian is
  # `debian`, which wraps update-rc.d, has no `maskable` feature and fails
  # outright on `enable => mask`. A `.service` is a systemd unit and nothing
  # else can manage one on the platforms this module supports.
  if $manage_daemon_disabled {
    service { 'puppet-agent-daemon':
      ensure   => stopped,
      name     => $daemon_service_name,
      enable   => mask,
      provider => systemd,
    }
  }
  else {
    service { 'puppet-agent-daemon':
      ensure   => running,
      name     => $daemon_service_name,
      enable   => true,
      provider => systemd,
    }
  }

  $agent_run_minute = fqdn_rand(60, $job_name)

  if $verbose {
    $verbose_argument = ['--verbose']
  }
  else {
    $verbose_argument = []
  }

  $agent_run_arguments = join($job_arguments + $verbose_argument, ' ')

  if $enable {
    cron { $job_name:
      command     => "${puppet_path} agent ${agent_run_arguments}",
      hour        => absent,
      minute      => $agent_run_minute,
      month       => absent,
      monthday    => absent,
      user        => 'root',
      weekday     => absent,
      environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    }
  }

  if $enable and $reboot_job {
    cron { "${job_name} on boot":
      command     => "${puppet_path} agent ${agent_run_arguments}",
      special     => 'reboot',
      user        => 'root',
      environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
    }
  }

  if $file_backups_cleanup {
    cron { 'clientbucket cleanup':
      command => "find /opt/puppetlabs/puppet/cache/clientbucket -type f -mtime +${file_backups_ttl} -delete",
      hour    => '5',
      minute  => fqdn_rand(60, 'clientbucket cleanup'),
    }
  }
}
