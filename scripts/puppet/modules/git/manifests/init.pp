# Class: tomcat
#
# This class does the following:
# - installs Git-core from system package manager
# - installs git-daemon-run
# - create /home/vagrant/git/repository
# - git init /home/vagrant/git/repository
# - commit some samples file into /home/vagrant/git/repository
# Tested on:
# - Ubuntu 12.04
#
# Sample Usage:
#  include git
#
class git  
{
  # Default to requiring all packages be installed
  Package {
    ensure => installed,
  }

  # Install package git-core
  package { 'git-core':}
  
  # Install package git-daemon-run
  package { 'git-daemon-run':
    name    => 'git-daemon-run',
    require => Package['git-core'],
  }

  
  # Ensure the git directory exists
  file { '/home/vagrant/git':
    ensure  => directory,
    require => Package['git-daemon-run'],
  }
  
  file { '/home/vagrant/git/repository':
    ensure  => directory,
    require => File['/home/vagrant/git'],
  }
  
  
  # Copy service run file to /etc/service/git-daemon/ via puppet:///
  file { '/etc/service/git-daemon/run':
    ensure  => present,
	source  => 'puppet:///modules/git/run',
    require => Package['git-daemon-run'],
  }

  # Make sure git-daemon service is restart and using new run file
  service { 'git-daemon':
    name      	=> 'git-daemon',
	path      	=> ['/etc/service','/usr/lib/git-core'],
    subscribe  	=> File['/etc/service/git-daemon/run'],
    ensure    	=> running
  }
  
  # Git init repo /home/vagrant/git/repository
  exec { 'init-repo':
	command     => 'git init /home/vagrant/git/repository',
	path        => ['/usr/lib/git-core'],
	subscribe   => File['/home/vagrant/git/repository']
  }
}
