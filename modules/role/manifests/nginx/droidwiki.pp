# nginx vhost droidwiki.de
class role::nginx::droidwiki {
  file { '/data/www/droidwiki.de':
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  file { '/data/www/droidwiki.de/public_html':
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  droidwiki::nginx::mediawiki { 'www.droidwiki.de':
    vhost_url             => 'www.droidwiki.de',
    server_name           => [ 'www.droidwiki.de' ],
    manage_directories    => false,
    html_root             => '/data/mediawiki/mw-config/mw-config/docroot',
    listen_port           => 443,
    ssl                   => true,
    ssl_cert              => '/data/www/droidwiki.de/droidwiki.de.2017.crt',
    ssl_key               => '/data/www/droidwiki.de/droidwiki.de.decrypted.key',
    manage_http_redirects => false,
    mediawiki_scriptpath  => '',
    mediawiki_articlepath => '',
  }

  # some redirects
  nginx::resource::vhost {
    default:
      listen_port          => 443,
      ssl_port             => 443,
      ssl                  => true,
      ssl_cert             => '/data/www/droidwiki.de/droidwiki.de.2017.crt',
      ssl_key              => '/data/www/droidwiki.de/droidwiki.de.decrypted.key',
      ssl_dhparam          => $sslcert::params::dhparampempath,
      http2                => on,
      add_header           => {
        'X-Delivered-By'            => $facts['fqdn'],
        'Strict-Transport-Security' => '"max-age=31536000; includeSubdomains; preload"',
      },
      use_default_location => false,
    ;
    'droidwiki.de':
      server_name      => [ '.droid.wiki', '.droidwiki.de' ],
      vhost_cfg_append => {
        'return' => '301 https://www.droidwiki.de$request_uri',
      },
    ;
    'droidwiki.de.80':
      server_name      => [ '.droid.wiki', '.droidwiki.de' ],
      listen_port      => 80,
      ssl              => false,
      add_header       => {
        'X-Delivered-By' => $facts['fqdn'],
      },
      vhost_cfg_append => {
        'return' => '301 https://www.droidwiki.de$request_uri',
      },
      index_files      => [],
    ;
  }
}
