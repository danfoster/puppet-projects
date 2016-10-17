# == Resource type: project
#
# A top level project type.
define projects::project (
  $apache = {},
  $tomcat = {},
  $mysql = {},
  $apache_common = {},
  $uid = undef,
  $gid = undef,
  $users = [],
  $ensure = undef,
  $description = ""
) {

  # If least one project definition exists for this host, creaste the base structure
  if ($apache != {} or
      $mysql != {} or
      $tomcat !={} or
      $ensure == 'present') {
    user { $title:
      comment => $description,
      uid     => $uid,
      gid     => $gid,
      home    => "$::projects::basedir/$title"
    }

    group { $title:
      gid     => $gid,
      members => $users,
    }

    project_user { $users:
      group => $title
    }

    file { [
           "$::projects::basedir/$title",
           ] :
      ensure => directory,
      owner  => $uid,
      group  => $gid,
      mode   => '0755',
    }

    file { [
           "$::projects::basedir/$title/var",
           "$::projects::basedir/$title/lib",
           "$::projects::basedir/$title/etc",
           ] :
      ensure => directory,
      owner  => $uid,
      group  => $gid,
      mode   => '0775',
      require => File["$::projects::basedir/$title"],
    }

    file { "$::projects::basedir/$title/var/log":
      ensure  => directory,
      owner   => $uid,
      group   => $gid,
      mode    => '0750',
      seltype => 'var_log_t',
      require => File["$::projects::basedir/$title/var"],
    }

    concat { "${::projects::basedir}/${title}/README":
      owner => $title,
      group => $title,
      mode  => '0640',
    }

    concat::fragment { "${title} header":
      target  => "${::projects::basedir}/${title}/README",
      content => "Project: ${title}\n\n",
      order   => '01'
    }

  }

  # Create apache vhosts
  if ($apache != {}) {
    projects::project::apache { $title:
      vhosts        => $apache,
      apache_common => $apache_common,
    }
  }

  # Create Tomcat services
  if ($tomcat != {}) {
    projects::project::tomcat { $title:
      ajp_port      => pick($tomcat[ajp_port],'8009')
    }
  }

  # Create MySQL server
  if ($mysql != {}) {
    projects::project::mysql { $title:
      user     => $title,
      password => pick($mysql[password],'changeme'),
      host     => pick($mysql[host],'localhost'),
      grant    => pick($mysql[grant],['ALL']),
    }
  }

  sudo::conf { "${title}-reset-perms":
    content => "%${title} ALL=(ALL) NOPASSWD: /usr/local/bin/reset-perms"
  }
}

define project_user (
  $group = undef
) {
  User <| title == $title |> {
    groups +> $group,
  }
}
