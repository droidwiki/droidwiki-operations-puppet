# vhost and locations for ops.go2tech.de
class role::nginx::ops_go2tech {
  droidwiki::nginx::mediawiki { 'ops.go2tech.de':
    vhost_url   => 'ops.go2tech.de',
    server_name => [ 'ops.go2tech.de' ],
  }
}