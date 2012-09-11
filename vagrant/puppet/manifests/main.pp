class apt_update {
    exec { "aptGetUpdate":
        command => "sudo apt-get update",
        path => ["/bin", "/usr/bin"]
    }
}

class apache {
    package { "apache2-mpm-prefork":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "libapache2-mod-php5":
        ensure => latest,
        require => Package["apache2-mpm-prefork"],
        notify => Service["apache2"],
    }

    service { "apache2":
        ensure => running,
        require => Package["apache2-mpm-prefork"],
        subscribe => File["main-vhost.conf", "httpd.conf", "mod_rewrite", "mod_actions"]
    }

    file { "main-vhost.conf":
        path => '/etc/apache2/conf.d/main-vhost.conf',
        ensure => file,
        content => template('default/main-vhost.conf'),
        require => Package["apache2-mpm-prefork"]
    }

    file { "httpd.conf":
        path => "/etc/apache2/httpd.conf",
        ensure => file,
        content => template('default/httpd.conf'),
        require => Package["apache2-mpm-prefork"]
    }

    file { "mod_rewrite":
        path => "/etc/apache2/mods-enabled/rewrite.load",
        ensure => "link",
        target => "/etc/apache2/mods-available/rewrite.load",
        require => Package["apache2-mpm-prefork"]
    }

    file { "mod_actions":
        path => "/etc/apache2/mods-enabled/actions.load",
        ensure => "link",
        target => "/etc/apache2/mods-available/actions.load",
        require => Package["apache2-mpm-prefork"]
    }

    file { "mod_actions_conf":
        path => "/etc/apache2/mods-enabled/actions.conf",
        ensure => "link",
        target => "/etc/apache2/mods-available/actions.conf",
        require => Package["apache2-mpm-prefork"]
    }
}

class php5 {

    package { "php5-cli":
        ensure => latest,
        require => Exec["aptGetUpdate"],
    }

    package { "php5-xdebug":
        ensure => latest,
        require => Package["libapache2-mod-php5"],
        notify => Service["apache2"]
    }

    package { "php5-intl":
        ensure => latest,
        require => Package["libapache2-mod-php5"]
    }

    package { "php5-suhosin":
        ensure => purged,
        notify => Service["apache2"]
    }

    package { "php5-sqlite":
        ensure => latest,
        require => Package["libapache2-mod-php5"]
    }

    file { "php-timezone.ini":
        path => "/etc/php5/cli/conf.d/30-timezone.ini",
        ensure => file,
        content => template('default/php-timezone.ini'),
        require => Package["php5-cli"]
    }
}

class php54dotdeb {
    file { "dotdeb.list":
        path => "/etc/apt/sources.list.d/dotdeb.list",
        ensure => file,
        owner => "root",
        group => "root",
        content => "deb http://ftp.ch.debian.org/debian squeeze main contrib non-free\ndeb http://packages.dotdeb.org squeeze all\ndeb-src http://packages.dotdeb.org squeeze all\ndeb http://packages.dotdeb.org squeeze-php54 all\ndeb-src http://packages.dotdeb.org squeeze-php54 all",
        notify => Exec["dotDebKeys"],
    }

#there's a conflict when you upgrade from 5.3 to 5.4 in xdebug.ini.
 file { "xdebug.ini":
        path => "//etc/php5/conf.d/20-xdebug.ini",
        ensure => "link",
        target => "/usr/share/php5/xdebug/xdebug.ini",
    }

    exec { "dotDebKeys":
        command => "wget -q -O - http://www.dotdeb.org/dotdeb.gpg | sudo apt-key add -",
        path => ["/bin", "/usr/bin"],
        notify => Exec["aptGetUpdate"],
        unless => "apt-key list | grep dotdeb"
    }

    package { "php5-apc":
        ensure => latest,
        require => Package["libapache2-mod-php5"],
        notify => Service["apache2"],
    }

    package { "phpapi-20090626":
        ensure => purged,
    }

    package { "php-apc":
        ensure => purged,
    }
}

class php53debian {
    package { "php-apc":
        ensure => latest,
        require => Package["libapache2-mod-php5"]
    }

    file { "dotdeb.list":
        path => "/etc/apt/sources.list.d/dotdeb.list",
        ensure => absent,
        notify => Exec["aptGetUpdate"],
    }
}

class symfony {

    exec { "vendorsInstall":
        cwd => "/vagrant",
        command => "php composer.phar install",
        timeout => 1200,
        path => ["/bin", "/usr/bin"],
        creates => "/vagrant/vendor",
        logoutput => true,
        require => Exec["composerPhar"],
    }
}

class composer {
    exec { "composerPhar":
        cwd => "/vagrant",
        command => "curl -s http://getcomposer.org/installer | php",
        path => ["/bin", "/usr/bin"],
        creates => "/vagrant/composer.phar",
        require => Package["php5-cli", "curl", "git"],
    }
}

class groups {
    group { "puppet":
        ensure => present,
    }
}

class otherstuff {
     package { "git":
        ensure => latest,
    }
     package { "curl":
        ensure => present,
    }
    package {"nfs-common":
        ensure => present,
    }
}



include apt_update
include php5
include php54dotdeb
#include php53debian
include otherstuff
include apache
include groups
include composer
include symfony
