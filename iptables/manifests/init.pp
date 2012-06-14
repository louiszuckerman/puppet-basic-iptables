class iptables ($ruleset_name, $ip_forward = false) {

    service {
        "iptables-persistent" :
            ensure => stopped,
            enable => true,
            hasstatus => false,
            require => [Package["iptables-persistent"],
            File["/etc/iptables/rules.v4"]] ;
    }
    if $ip_forward {
        exec {
            "start procps" :
                refreshonly => true,
                before => Service["iptables-persistent"],
                subscribe => File["/etc/sysctl.d/60-ipforward.conf"],
                require => File["/etc/sysctl.d/60-ipforward.conf"] ;
        }
        file {
            "/etc/sysctl.d/60-ipforward.conf" :
                content => template("iptables/ipforward.sysctl"),
                ensure => present,
                replace => true,
                require => File["/etc/iptables/rules.v4"] ;
        }
    }
    exec {
        "start-iptables-persistent" :
            command => "service iptables-persistent start",
            refreshonly => true,
            require => File["/etc/iptables/rules.v4"] ;
    }
    file {
        "/etc/iptables/rules.v4" :
            content => template("iptables/${ruleset_name}.iptables-save"),
            ensure => present,
            replace => true,
            notify => Exec["start-iptables-persistent"],
            require => Package["iptables-persistent"] ;
    }
    package {
        "iptables-persistent" :
            ensure => present,
            responsefile => "/var/tmp/iptables-persistent.debconf",
            require => File["/var/tmp/iptables-persistent.debconf"] ;
    }
    file {
        "/var/tmp/iptables-persistent.debconf" :
            content => template("iptables/iptables-persistent.debconf"),
            ensure => present,
            replace => true ;
    }
}
