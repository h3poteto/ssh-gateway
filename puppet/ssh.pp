$users = [
  "h3poteto",
  "denzow"
]



exec { "apt-get update":
  command => "/usr/bin/apt-get update",
  onlyif  => "/bin/sh -c '[ ! -f /var/cache/apt/pkgcache.bin ] || /usr/bin/find /etc/apt/* -cnewer /var/cache/apt/pkgcache.bin | /bin/grep . > /dev/null'",
}

package { 'ssh':
  ensure => installed,
  require => Exec['apt-get update'],
}

package { 'wget':
  ensure => installed,
  require => Exec['apt-get update'],
}

group { "developer":
  gid => 518,
  ensure => present
}

$users.each |String $user| {
  user { $user:
    ensure => present,
    home => "/home/${$user}",
    managehome => true,
    gid => 518,
    shell => "/bin/bash",
    password => '!!'
  }

  file { "/home/${user}/.ssh":
    ensure => directory,
    mode => "0700",
    owner => $user,
    group => "developer",
  }

  exec{ "github_key_${user}":
    command => "/usr/bin/wget -q https://github.com/${user}.keys -O /home/${user}/.ssh/authorized_keys",
    creates => "/home/${user}/.ssh/authorized_keys",
  }

  file{ "/home/${user}/.ssh/authorized_keys":
    mode => "0600",
    owner => $user,
    group => "developer",
    require => Exec["github_key_${user}"],
  }
}
