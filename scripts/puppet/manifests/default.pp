# Install tomcat and start tomcat service in default port 8080, add new tomcat user: root/vagrant with manager role
include tomcat
# Install git and git-daemon package, start git-daemon service in default port 9418, add new repository and allow git:// protocol from host machine
include git

# put this somewhere global, like site.pp
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

cron { auto-commit:
  command  => "sudo bash /tmp/vagrant-puppet/manifests/commit.sh",
  user     => root,
  hour     => ['0-23'],
  minute   => '*/3'
}

cron { auto-deploy:
  command  => "sudo bash /tmp/vagrant-puppet/manifests/deploy.sh",
  user     => root,
  hour     => ['0-23'],
  minute   => '*/5'
}