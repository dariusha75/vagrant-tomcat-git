# Class: tomcat
#
# This class does the following:
# - installs Tomcat6 from system package manager
# - installs 'tomcat-user' package from system package manager (Ubuntu/Debian specific)
# - installs 'tomcat-admin' package from system package manager (Ubuntu/Debian specific)
#
# Requires:
# - Java must be installed
#
# Tested on:
# - Ubuntu 12.04
#
# Sample Usage:
#  include tomcat
#
class tomcat ($tomcat = "tomcat6") 
{
  # Default to requiring all packages be installed
  Package {
    ensure => installed,
  }

  # Require these base packages are installed
  package { 'tomcat':
    name => $tomcat,
  }
  # NOTE: tomcat-user package is Ubuntu specific!!
  # It lets us quickly install Tomcat to any directory (see instance.pp)
  package { 'tomcat-user':
    name    => "${tomcat}-user",
    require => Package['tomcat'],
  }

  package { 'tomcat-admin':
    name    => "${tomcat}-admin",
    require => Package['tomcat'],
  }
  
  # Ensure the tomcat home directory exists
  file { "/usr/share/${tomcat}":
    ensure  => directory,
    require => Package['tomcat'],
  }
  
  # Copy user config file tomcat-users.xml via puppet:///
  file { "/etc/${tomcat}/tomcat-users.xml":
    ensure  => present,
	source  => "puppet:///modules/tomcat//tomcat-users.xml",
    require => Package['tomcat'],
  }

  # install the package, but disable the default Tomcat service
  service { 'tomcat':
    name      => $tomcat,
    subscribe => File["/etc/${tomcat}/tomcat-users.xml"],
    ensure    => running
  }
}
