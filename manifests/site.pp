# site.pp
node 'eclair.dwnet' {
  include droidwiki::default
  include role::gitlab
  include role::mariadb
  include role::webserver
  include role::mediawiki
  include role::mailserver
  include mailgraph
  include role::ircbot
  include role::jenkinsmaster
  include role::puppetmaster
  include role::deploymenthost
  include certbot

  include role::nginx::go2tech
  include role::nginx::www_go2tech
  include role::nginx::blog_go2tech
  include jenkins
  include role::nginx::ops_go2tech
  include role::nginx::dev_go2tech
  include role::nginx::ganglia_go2tech
  include role::nginx::gerrit_go2tech
  include role::nginx::git_go2tech
  include role::nginx::puppetboard_go2tech

  include role::puppetboard

  include role::ganglia

  include role::profilinghost
  include role::xhgui

  include role::elasticsearch
  include role::logstash
  include role::kibana

  include role::nodejs
  include zotero
  include citoid
}

node 'donut.dwnet' {
  include droidwiki::default
  include role::mariadb
  include role::parsoid
  include role::webserver
  include role::mediawiki
  include role::logstash
  include role::jobrunner
  include role::ganglia
  include certbot
  include role::nfs_server
  include role::nodejs
  include restbase
  include cxserver

  include role::nginx::droidwiki
  include role::nginx::data_droidwiki
  include role::datawiki
  include role::nginx::donut_go2tech
  include role::nginx::missionrhode_go2tech

  role::nginx::wiki{ 'endroidwikiwiki':
    domain      => 'en.droidwiki.org',
    server_name => [ 'en.droidwiki.org' ]
  }
}
