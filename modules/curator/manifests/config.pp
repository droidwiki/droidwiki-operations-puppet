# Creates a configuration file for elasticsearch-curator.
define curator::config(
    $ensure  = present,
    $content = undef,
    $source  = undef,
) {
    file { "/etc/curator/${title}.yaml":
        ensure  => $ensure,
        content => $content,
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

}