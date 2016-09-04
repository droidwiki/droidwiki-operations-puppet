# template for nginx conifguration for a standard
# mediawiki host.
define droidwiki::nginx::mediawiki (
  $vhost_url             = undef,
  $manage_directories    = true,
  $server_name           = undef,
  $html_root             = undef,
  $listen_port           = 80,
  $ssl                   = false,
  $ssl_port              = 443,
  $ssl_cert              = undef,
  $ssl_key               = undef,
  $http2                 = 'on',
  $manage_http_redirects = true,
  $mediawiki_wwwroot     = '/data/mediawiki/main',
  $mediawiki_scriptpath  = 'w/',
  $mediawiki_articlepath = 'wiki/',
) {
  validate_string($vhost_url)
  validate_string($mediawiki_wwwroot)
  validate_string($mediawiki_scriptpath)
  validate_string($mediawiki_articlepath)
  validate_bool($manage_directories)
  validate_bool($ssl)

  # ssl config is slightly different
  if ( $ssl ) {
    validate_string($ssl_cert)
    validate_string($ssl_key)
    validate_string($http2)
    # FIXME: make HSTS configurable, currently any https mediawiki host uses HSTS
    $add_header = {
      'X-Delivered-By'            => $facts['fqdn'],
      'Strict-Transport-Security' => '"max-age=31536000; includeSubdomains; preload"',
    }
  } else {
    $add_header = {
      'X-Delivered-By' => $facts['fqdn'],
    }
  }

  if ( $manage_directories ) {
    file { "/data/www/${vhost_url}":
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755',
    }

    file { "/data/www/${vhost_url}/public_html":
      ensure => 'directory',
      owner  => 'www-data',
      group  => 'www-data',
      mode   => '0755',
    }
    $public_html = "/data/www/${vhost_url}/public_html"
  } else {
    $public_html = $html_root
  }

  if ( $server_name != undef ) {
    validate_array($server_name)
    $server_names = $server_name
  } else {
    $server_names = [ $vhost_url ]
  }

  nginx::resource::vhost { $vhost_url:
    listen_port          => $listen_port,
    ssl                  => $ssl,
    ssl_port             => $ssl_port,
    ssl_cert             => $ssl_cert,
    ssl_key              => $ssl_key,
    ssl_dhparam          => $sslcert::params::dhparampempath,
    http2                => $http2,
    add_header           => $add_header,
    use_default_location => false,
    server_name          => $server_names,
    www_root             => $mediawiki_wwwroot,
    index_files          => [ 'index.php' ],
    vhost_cfg_append     => {
      'error_page 500 502 503 504' => '/500.html',
      'error_page 403'             => '/403.html',
      'gzip'                       => 'on',
      'gzip_comp_level'            => '2',
      'gzip_http_version'          => '1.0',
      'gzip_proxied'               => 'any',
      'gzip_min_length'            => '1100',
      'gzip_buffers'               => '16 8k',
      # disable gzip for IE < 6 because of known problems
      'gzip_disable'               => '"MSIE [1-6].(?!.*SV1)"',
      'gzip_vary'                  => 'on',
    },
    gzip_types           => 'text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript',
  }

  if ( $ssl and $manage_http_redirects ) {
    nginx::resource::vhost { "${vhost_url}.80":
      server_name          => $server_names,
      listen_port          => 80,
      ssl                  => false,
      add_header           => {
        'X-Delivered-By' => $facts['fqdn'],
      },
      vhost_cfg_append     => {
        'return' => "301 https://${vhost_url}\$request_uri",
      },
      index_files          => [],
      use_default_location => false,
    }
  }

  nginx::resource::location {
    default:
      vhost               => $vhost_url,
      location_custom_cfg => {},
      ssl                 => $ssl,
      ssl_only            => $ssl,
    ;
    "${vhost_url}/500.html":
      location => '= /500.html',
      www_root => $public_html,
    ;
    "${vhost_url}/403.html":
      location => '= /403.html',
      www_root => $public_html,
    ;
    "${vhost_url}/":
      location            => '/',
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => "\$uri @rewrite",
      }
    ;
    "${vhost_url} @rewrite":
      location            => '@rewrite',
      location_custom_cfg => {
        'rewrite' => "^/(.*)\$ /${mediawiki_scriptpath}index.php?title=\$1&\$args",
      }
    ;
    "${vhost_url}/${mediawiki_scriptpath}images":
      location    => "/${mediawiki_scriptpath}images",
      # workaround for missing way for locations in location
      # https://github.com/jfryman/puppet-nginx/issues/692
      raw_prepend => [
        "location ~ ^/${mediawiki_scriptpath}images/thumb/(archive/)?[0-9a-f]/[0-9a-f][0-9a-f]/([^/]+)/([0-9]+)px-.*\$ {",
        '   try_files $uri $uri/ @thumb;',
        '}',
      ],
    ;
    "${vhost_url}/${mediawiki_scriptpath}images/deleted":
      location            => "^~ /${mediawiki_scriptpath}images/deleted",
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/${mediawiki_scriptpath}cache":
      location            => "^~ /${mediawiki_scriptpath}cache",
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/${mediawiki_scriptpath}languages":
      location            => "^~ /${mediawiki_scriptpath}languages",
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/${mediawiki_scriptpath}maintenance":
      location            => "^~ /${mediawiki_scriptpath}maintenance/",
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/${mediawiki_scriptpath}serialized":
      location            => "^~ /${mediawiki_scriptpath}serialized",
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/ .svn .git":
      location            => '~ /.(svn|git)(/|$)',
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    ;
    "${vhost_url}/ .ht":
      location      => '~ /.ht',
      location_deny => [ 'all' ],
    ;
    "${vhost_url}/ @thumb":
      location      => '@thumb',
      rewrite_rules => [
        "^/${mediawiki_scriptpath}images/thumb/[0-9a-f]/[0-9a-f][0-9a-f]/([^/]+)/([0-9]+)px-.*\$ /${mediawiki_scriptpath}thumb.php?f=\$1&width=\$2",
        "^/${mediawiki_scriptpath}images/thumb/archive/[0-9a-f]/[0-9a-f][0-9a-f]/([^/]+)/([0-9]+)px-.*\$ /${mediawiki_scriptpath}thumb.php?f=\$1&width=\$2&archived=1",
      ],
      fastcgi_param => {
        'SCRIPT_FILENAME' => '$document_root/thumb.php',
      },
      fastcgi       => '127.0.0.1:9000',
    ;
  }

  # without a different script and article path, the / location already exists. Duplicate locations
  # aren't allowed, which is why the both locations are in an if clause.
  if ( $mediawiki_scriptpath != $mediawiki_articlepath ) {
    nginx::resource::location { "${vhost_url}/${mediawiki_articlepath}":
      vhost         => $vhost_url,
      ssl           => $ssl,
      ssl_only      => $ssl,
      location      => "/${mediawiki_articlepath}",
      fastcgi_param => {
        'SCRIPT_FILENAME' => '$document_root/index.php',
      },
      fastcgi       => '127.0.0.1:9000',
    }

    nginx::resource::location { "${vhost_url}/${mediawiki_scriptpath}":
      vhost               => $vhost_url,
      location            => "/${mediawiki_scriptpath}",
      location_custom_cfg => {},
      ssl                 => $ssl,
      ssl_only            => $ssl,
      # workaround for missing way for locations in location
      # https://github.com/jfryman/puppet-nginx/issues/692
      raw_prepend         => [
        'location ~ \.php$ {',
        '   try_files $uri $uri/ =404;',
        '   fastcgi_param HTTP_ACCEPT_ENCODING "";',
        '   include /etc/nginx/fastcgi_params;',
        '   fastcgi_pass 127.0.0.1:9000;',
        '}',
      ],
    }
  } else {
    # otherwise, the .php handler is added to the top level location
    nginx::resource::location { "${vhost_url}/ .php":
      location      => '~ \.php$',
      vhost         => $vhost_url,
      ssl           => $ssl,
      ssl_only      => $ssl,
      try_files     => [ '$uri', '$uri/', '@rewrite' ],
      raw_prepend   => [
        'set $hhvmServer 127.0.0.1:9000;',
        'if ($http_x_droidwiki_debug) {',
        '   set $hhvmServer 188.68.49.74:9000;',
        '   add_header X-Delivered-By eclair.dwnet;',
        '}',
        'if ($http_x_droidwiki_debug = "") {',
        "   add_header X-Delivered-By ${facts['fqdn']};",
        '}',
      ],
      fastcgi       => '$hhvmServer',
      fastcgi_param => {
        'HTTP_ACCEPT_ENCODING' => '""',
      }
    }

    nginx::resource::location { "${vhost_url}/w/":
      location            => '^~ /w/',
      vhost               => $vhost_url,
      ssl                 => $ssl,
      ssl_only            => $ssl,
      # FIXME: https://github.com/jfryman/puppet-nginx/issues/470
      location_custom_cfg => {
        'try_files' => 'fail @rewrite',
      },
      try_files           => [ 'fail', '@rewrite' ],
    }
  }
}