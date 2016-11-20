# defines hosts and locations for kibana.go2tech.de
# ALWAYS PAIR WITH CERTBOT!
class role::nginx::kibana_go2tech {
  file { '/data/www/kibana.go2tech.de':
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  file { '/data/www/kibana.go2tech.de/public_html':
    ensure => 'directory',
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0755',
  }

  nginx::resource::vhost { 'kibana.go2tech.de':
    use_default_location => false,
    ipv6_enable          => true,
    ipv6_listen_options  => '',
    server_name          => [ 'kibana.go2tech.de' ],
    listen_port          => 443,
    ssl_port             => 443,
    ssl                  => true,
    ssl_cert             => '/etc/letsencrypt/live/blog.go2tech.de/fullchain.pem',
    ssl_key              => '/etc/letsencrypt/live/blog.go2tech.de/privkey.pem',
    ssl_dhparam          => $sslcert::params::dhparampempath,
    ssl_stapling         => true,
    ssl_stapling_verify  => true,
    http2                => on,
  }

  nginx::resource::vhost { 'kibana.go2tech.de.80':
    server_name          => [ 'kibana.go2tech.de' ],
    listen_port          => 80,
    ipv6_enable          => true,
    ipv6_listen_options  => '',
    ssl                  => false,
    add_header           => {
      'X-Delivered-By' => $facts['fqdn'],
    },
    index_files          => [],
    use_default_location => false,
  }

  nginx::resource::location { 'kibana.go2tech.de/':
    vhost                 => 'kibana.go2tech.de',
    ssl                   => true,
    ssl_only              => true,
    location              => '/',
    auth_basic            => 'Private data, login only',
    auth_basic_user_file  => '/data/www/kibana.go2tech.de/users.htpasswd',
    proxy                 => 'http://127.0.0.1:5601',
    proxy_set_header      => [
      'Host $host',
      'X-Real-IP $remote_addr',
      'X-Forwarded-For $remote_addr',
    ],
    proxy_connect_timeout => '300',
    location_cfg_append   => {
      'port_in_redirect' => 'off',
    },
  }

  nginx::resource::location { 'kibana.go2tech.de/.well-known':
    vhost    => 'kibana.go2tech.de.80',
    location => '^~ /.well-known/acme-challenge/',
    www_root => '/data/www/kibana.go2tech.de/public_html/',
  }

  nginx::resource::location { 'kibana.go2tech.de.80/':
    vhost               => 'kibana.go2tech.de.80',
    location            => '/',
    location_custom_cfg => {
      'return ' => '301 https://kibana.go2tech.de$request_uri',
    },
  }
}
