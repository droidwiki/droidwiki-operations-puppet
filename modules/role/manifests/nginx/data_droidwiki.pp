# data.droidwiki.de class
# ALWAYS PAIR WITH CERTBOT!
class role::nginx::data_droidwiki {
  $sslcert = '/etc/letsencrypt/live/droidwiki.de-0001/fullchain.pem';
  $sslkey = '/etc/letsencrypt/live/droidwiki.de-0001/privkey.pem';

  role::nginx::wiki{ 'datawiki':
    domain      => 'data.droidwiki.org',
    server_name => [ 'data.droid.wiki', 'data.droidwiki.org', 'data.droidwiki.de' ]
  }

  # some redirects
  nginx::resource::vhost {
    default:
      listen_port          => 443,
      ipv6_enable          => true,
      ipv6_listen_options  => '',
      ssl_port             => 443,
      ssl                  => true,
      ssl_cert             => $sslcert,
      ssl_key              => $sslkey,
      ssl_stapling         => true,
      ssl_stapling_verify  => true,
      ssl_dhparam          => $sslcert::params::dhparampempath,
      http2                => on,
      add_header           => {
        'X-Delivered-By'            => $facts['fqdn'],
        'Strict-Transport-Security' => '"max-age=31536000; includeSubdomains; preload"',
      },
      vhost_cfg_append     => {
        'return' => '301 https://data.droidwiki.org$request_uri',
      },
      use_default_location => false,
    ;
    'data.droidwiki.de':
      server_name => [ 'data.droid.wiki', 'data.droidwiki.de' ],
    ;
  }
}
