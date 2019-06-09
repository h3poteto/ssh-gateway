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

package { 'sudo':
  ensure => installed,
  require => Exec['apt-get update'],
}

package { 'python3-pip':
  ensure => installed,
  require => Exec['apt-get update'],
}

exec { 'awscli':
  command => "/usr/bin/pip3 install awscli --upgrade",
  require => Package['python3-pip'],
}

package { 'awscli':
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
    groups => ["developer", "sudo"],
    shell => "/bin/bash",
    password => '!!',
  }

  file { "/home/${user}/.ssh":
    ensure => directory,
    mode => "0700",
    owner => $user,
    group => "developer",
  }

  exec { "github_key_${user}":
    command => "/usr/bin/wget -q https://github.com/${user}.keys -O /home/${user}/.ssh/authorized_keys",
    creates => "/home/${user}/.ssh/authorized_keys",
    require => File["/home/${user}/.ssh"],
  }

  file { "/home/${user}/.ssh/authorized_keys":
    mode => "0600",
    owner => $user,
    group => "developer",
    require => Exec["github_key_${user}"],
  }

  $sudoers = "${user}    ALL=(ALL)    NOPASSWD: ALL"

  file { "/etc/sudoers.d/${user}":
    ensure => present,
    content => $sudoers,
  }
}


exec { "private_ssh_key":
  command => "/usr/bin/aws ssm get-parameters --names ssh_private_key --with-decryption --region ap-northeast-1 --query \"Parameters[0].Value\" --output text > /usr/local/bin/.ssh.pem",
  creates => "/usr/local/bin/.ssh.pem",
}

file { "/usr/local/bin/.ssh.pem":
  mode => "0666",
  require => Exec["private_ssh_key"],
}
