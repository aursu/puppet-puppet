# @summary Puppet agent cron settings
#
# Puppet agent cron settings
#
# @example
#   include puppet::agent::schedule
class puppet::agent::schedule (
  String  $job_name             = 'puppet agent run',
  Array[String]
          $job_arguments        = [
            '--onetime',
            '--verbose',
            '--no-daemonize',
            '--no-usecacheonfailure',
            '--detailed-exitcodes',
            '--no-splay',
          ],
  Boolean $reboot_job           = true,
  Boolean $file_backups_cleanup = true,
  Integer $file_backups_ttl     = 45,
)
{
  $agent_run_minute = fqdn_rand(60, $job_name)
  $agent_run_arguments = join($job_arguments, ' ')

  cron { $job_name:
    command     => "/opt/puppetlabs/bin/puppet agent ${agent_run_arguments}",
    hour        => absent,
    minute      => $agent_run_minute,
    month       => absent,
    monthday    => absent,
    user        => 'root',
    weekday     => absent,
    environment => 'PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin',
  }

  if $reboot_job {
    cron { "${job_name} on boot":
      command     => "/opt/puppetlabs/bin/puppet agent ${agent_run_arguments}",
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
