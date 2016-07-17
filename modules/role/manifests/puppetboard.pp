# Wrapper for managing puppetboard
class role::puppetboard(
  String $puppetboard_url = undef
) {
  if $puppetboard_url == undef {
    fail( 'No puppetboard url given.' )
  }

  class { 'puppetboard':
    manage_virtualenv => 'latest',
    puppetdb_port     => '8083',
    enable_query      => false,
  }

  package { 'flask':
    ensure   => present,
    provider => 'pip',
  }

  package { 'flask-wtf':
    ensure   => present,
    provider => 'pip',
  }

  package { 'pypuppetdb':
    ensure   => present,
    provider => 'pip',
  }

  file { "/data/www/${puppetboard_url}":
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }
}
