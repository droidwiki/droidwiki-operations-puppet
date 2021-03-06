# Module, which manages the certbot automatic renewel
# of certificates. Unfortunately, currently does not
# handle the the process of getting a new certificate.
class certbot(
  $mode = 'webroot',
  $hook = Undef,
) {
  apt::ppa { 'ppa:certbot/certbot': }

  package { 'certbot':
    ensure  => 'present',
    require => [
      Apt::Ppa['ppa:certbot/certbot'],
      Exec['apt_update'],
    ]
  }

  package { 'python3-certbot-dns-rfc2136':
    ensure  => 'present',
    require => [
      Apt::Ppa['ppa:certbot/certbot'],
      Exec['apt_update'],
    ]
  }

  package { 'python3-certbot-dns-cloudflare':
    ensure  => 'absent',
  }

  if ($mode == 'standalone') {
    firewall { '305 accept incoming http traffic':
      proto  => 'tcp',
      dport  => '80',
      action => 'accept',
    }

    firewall { '305 accept incoming http traffic IPv6':
      proto    => 'tcp',
      dport    => '80',
      action   => 'accept',
      provider => 'ip6tables',
    }
  }

  $command = '/usr/bin/certbot renew --quiet --no-self-upgrade'
  if ($hook != Undef) {
    $params = " --deploy-hook \"${hook}\""
  }

  cron { 'letsencrypt renew cron':
    command => "${command}${params}",
    user    => root,
    hour    => 2,
    minute  => 30,
    weekday => 1,
  }
}
