#!/usr/bin/env bash


#### VARIABLES / options
# Detect AMD EPYC and Ryzen CPU and Apply Fixes
if [ -z "$MY_AMDFIXES" ] ; then
    MY_AMDFIXES="no"
fi

# Force APT to use IPv4
if [ -z "$my_APTIPV4" ] ; then
    APTIPV4="yes"
fi
# Update proxmox and install various system utils
if [ -z "$MY_APTUPGRADE" ] ; then
    MY_APTUPGRADE="yes"
fi
# Customise bashrc
if [ -z "$MY_BASHRC" ] ; then
    MY_BASHRC="yes"
fi
# Add the latest ceph provided by proxmox
if [ -z "$MY_CEPH" ] ; then
    MY_CEPH="no"
fi
# Disable portmapper / rpcbind (security)
if [ -z "$MY_DISABLERPC" ] ; then
    MY_DISABLERPC="yes"
fi
# Ensure Entropy Pools are Populated, prevents slowdowns whilst waiting for entropy
if [ -z "$MY_ENTROPY" ] ; then
    MY_ENTROPY="yes"
fi
# Protect the web interface with fail2ban
if [ -z "$MY_FAIL2BAN" ] ; then
    MY_FAIL2BAN="yes"
fi

# Install ifupdown2 for a virtual internal network allows rebootless networking changes (not compatible with openvswitch-switch)
if [ -z "$MY_IFUPDOWN2" ] ; then
    MY_IFUPDOWN2="yes"
fi
# Limit the size and optimise journald
if [ -z "$MY_JOURNALD" ] ; then
    MY_JOURNALD="yes"
fi
# Install kernel source headers
if [ -z "$MY_KERNELHEADERS" ] ; then
    MY_KERNELHEADERS="yes"
fi
# Ensure ksmtuned (ksm-control-daemon) is enabled and optimise according to ram size
if [ -z "$MY_KSMTUNED" ] ; then
    MY_KSMTUNED="yes"
fi
# Set language, if changed will disable MY_NOAPTLANG
if [ -z "$MY_LANG" ] ; then
    MY_LANG="en_US.UTF-8"
fi
# Enable restart on kernel panic, kernel oops and hardlockup
if [ -z "$MY_KERNELPANIC" ] ; then
    MY_KERNELPANIC="yes"
fi
# Increase max user watches, FD limit, FD ulimit, max key limit, ulimits
if [ -z "$MY_LIMITS" ] ; then
    MY_LIMITS="yes"
fi
# Optimise logrotate
if [ -z "$MY_LOGROTATE" ] ; then
    MY_LOGROTATE="yes"
fi
# Lynis security scan tool by Cisofy
if [ -z "$MY_LYNIS" ] ; then
    MY_LYNIS="yes"
fi
# Increase Max FS open files
if [ -z "$MY_MAXFS" ] ; then
    MY_MAXFS="yes"
fi
# Optimise Memory
if [ -z "$MY_MEMORYFIXES" ] ; then
    MY_MEMORYFIXES="yes"
fi
# Pretty MOTD BANNER
if [ -z "$MY_MOTD" ] ; then
    MY_MOTD="yes"
fi
# Enable Network optimising
if [ -z "$MY_NET" ] ; then
    MY_NET="yes"
fi
# Save bandwidth and skip downloading additional languages, requires MY_LANG="en_US.UTF-8"
if [ -z "$MY_NOAPTLANG" ] ; then
    MY_NOAPTLANG="yes"
fi
# Disable enterprise proxmox repo
if [ -z "$MY_NOENTREPO" ] ; then
    MY_NOENTREPO="yes"
fi
# Remove subscription banner
if [ -z "$MY_NOSUBBANNER" ] ; then
    MY_NOSUBBANNER="yes"
fi
# Install openvswitch for a virtual internal network
if [ -z "$MY_OPENVSWITCH" ] ; then
    MY_OPENVSWITCH="no"
fi
# Detect if this is an OVH server and install OVH Real Time Monitoring
if [ -z "$MY_OVHRTM" ] ; then
    MY_OVHRTM="no"
fi
# Set pigz to replace gzip, 2x faster gzip compression
if [ -z "$MY_PIGZ" ] ; then
    MY_PIGZ="yes"
fi
# Bugfix: high swap usage with low memory usage
if [ -z "$MY_SWAPPINESS" ] ; then
    MY_SWAPPINESS="yes"
fi
# Enable TCP BBR congestion control
if [ -z "$MY_TCPBBR" ] ; then
    MY_TCPBBR="yes"
fi
# Enable TCP fastopen
if [ -z "$MY_TCPFASTOPEN" ] ; then
    MY_TCPFASTOPEN="yes"
fi
# Enable testing proxmox repo
if [ -z "$MY_TESTREPO" ] ; then
    MY_TESTREPO="no"
fi
# Automatically Synchronize the time
if [ -z "$MY_TIMESYNC" ] ; then
    MY_TIMESYNC="yes"
fi
# Set Timezone, empty = set automatically by IP
if [ -z "$MY_TIMEZONE" ] ; then
    MY_TIMEZONE=""
fi
# Install common system utilities
if [ -z "$MY_UTILS" ] ; then
    MY_UTILS="yes"
fi
# Increase vzdump backup speed
if [ -z "$MY_VZDUMP" ] ; then
    MY_VZDUMP="yes"
fi
# Optimise ZFS arc size accoring to memory size
if [ -z "$MY_ZFSARC" ] ; then
    MY_ZFSARC="yes"
fi
# Install zfs-auto-snapshot
if [ -z "$MY_ZFSAUTOSNAPSHOT" ] ; then
    MY_ZFSAUTOSNAPSHOT="no"
fi

#################  D O   N O T   E D I T  ######################################

echo "Processing .... "

# Set the local
if [ "$MY_LANG" == "" ] ; then
    MY_LANG="en_US.UTF-8"
fi
export LANG="$MY_LANG"
export LC_ALL="C"

# enforce proxmox
if [ ! -f "/etc/pve/.version" ] ; then
  echo "ERROR: This script only supports Proxmox"
  exit 1
fi

if [ -f "/etc/proxmox-post-install" ] ; then
  echo "ERROR: Script can only be run once"
  exit 1
fi

# SET VARIBLES

OS_CODENAME="$(grep "VERSION_CODENAME=" /etc/os-release | cut -d"=" -f 2 | xargs )"
RAM_SIZE_GB=$(( $(vmstat -s | grep -i "total memory" | xargs | cut -d" " -f 1) / 1024 / 1000))

if [ "${MY_LANG}" == "en_US.UTF-8" ] && [ "${MY_NOAPTLANG,,}" == "yes" ] ; then
    # save bandwidth and skip downloading additional languages
    echo -e "Acquire::Languages \"none\";\\n" > /etc/apt/apt.conf.d/99-xs-disable-translations
fi

if [ "${MY_APTIPV4,,}" == "yes" ] ; then
    # force APT to use IPv4
    echo -e "Acquire::ForceIPv4 \"true\";\\n" > /etc/apt/apt.conf.d/99-xs-force-ipv4
fi

if [ "${MY_NOENTREPO,,}" == "yes" ] ; then
    # disable enterprise proxmox repo
    if [ -f /etc/apt/sources.list.d/pve-enterprise.list ]; then
      sed -i "s/^deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list
    fi
    # enable free public proxmox repo
    if [ ! -f /etc/apt/sources.list.d/proxmox.list ] && [ ! -f /etc/apt/sources.list.d/pve-public-repo.list ] && [ ! -f /etc/apt/sources.list.d/pve-install-repo.list ] ; then
      echo -e "deb http://download.proxmox.com/debian/pve ${OS_CODENAME} pve-no-subscription\\n" > /etc/apt/sources.list.d/pve-public-repo.list
    fi
    if [ "${MY_TESTREPO,,}" == "yes" ] ; then
        # enable testing proxmox repo
        echo -e "deb http://download.proxmox.com/debian/pve ${OS_CODENAME} pvetest\\n" > /etc/apt/sources.list.d/pve-testing-repo.list
    fi
fi

# rebuild and add non-free to /etc/apt/sources.list
cat <<EOF > /etc/apt/sources.list
deb https://ftp.debian.org/debian ${OS_CODENAME} main contrib
deb https://ftp.debian.org/debian ${OS_CODENAME}-updates main contrib
# non-free
deb https://httpredir.debian.org/debian/ ${OS_CODENAME} main contrib non-free
# security updates
deb https://security.debian.org/debian-security ${OS_CODENAME}-security main contrib
EOF

# Refresh the package lists
apt-get update > /dev/null 2>&1

# Remove conflicting utilities
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge ntp openntpd systemd-timesyncd

# Fixes for common apt repo errors
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install apt-transport-https debian-archive-keyring ca-certificates curl

if [ "${MY_APTUPGRADE,,}" == "yes" ] ; then
    # update proxmox and install various system utils
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' dist-upgrade
    pveam update
fi

# Install packages which are sometimes missing on some Proxmox installs.
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install zfsutils-linux proxmox-backup-restore-image chrony

if [ "${MY_UTILS,,}" == "yes" ] ; then
# Install common system utilities
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install \
    axel \
    build-essential \
    curl \
    dialog \
    dnsutils \
    dos2unix \
    git \
    gnupg-agent \
    grc \
    htop \
    iftop \
    iotop \
    iperf \
    ipset \
    iptraf \
    mlocate \
    msr-tools \
    nano \
    net-tools \
    omping \
    software-properties-common \
    sshpass \
    tmux \
    unzip \
    vim \
    vim-nox \
    wget \
    whois \
    zip \
	pigz \
	wget \
	curl \
	ethtool \
	mailutils \
	cifs-utils						
fi

if [ "${MY_CEPH,,}" == "yes" ] ; then
    # Add the latest ceph provided by proxmox
    echo "deb http://download.proxmox.com/debian/ceph-pacific ${OS_CODENAME} main" > /etc/apt/sources.list.d/ceph-pacific.list
    ## Refresh the package lists
    apt-get update > /dev/null 2>&1
    ## Install ceph support
    echo "Y" | pveceph install
fi

if [ "${MY_LYNIS,,}" == "yes" ] ; then
    # Lynis security scan tool by Cisofy
    wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | apt-key add -
    ## Add the latest lynis
    echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" > /etc/apt/sources.list.d/cisofy-lynis.list
    ## Refresh the package lists
    apt-get update > /dev/null 2>&1
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install lynis
fi

if [ "${MY_OPENVSWITCH,,}" == "yes" ] && [ "${MY_IFUPDOWN2}" == "no" ] ; then
    ## Install openvswitch for a virtual internal network
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install ifenslave ifupdown
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' remove ifupdown2
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install openvswitch-switch
else
    ## Install ifupdown2 for a virtual internal network allows rebootless networking changes (not compatible with openvswitch-switch)
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge openvswitch-switch
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install ifupdown2
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' remove ifenslave ifupdown
fi

if [ "${MY_ZFSAUTOSNAPSHOT,,}" == "yes" ] ; then
    ## Install zfs-auto-snapshot
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install zfs-auto-snapshot
    # make 5min snapshots , keep 12 5min snapshots
    if [ -f "/etc/cron.d/zfs-auto-snapshot" ] ; then
      sed -i 's|--keep=[0-9]*|--keep=12|g' /etc/cron.d/zfs-auto-snapshot
      sed -i 's|*/[0-9]*|*/5|g' /etc/cron.d/zfs-auto-snapshot
    fi
    # keep 24 hourly snapshots
    if [ -f "/etc/cron.hourly/zfs-auto-snapshot" ] ; then
      sed -i 's|--keep=[0-9]*|--keep=24|g' /etc/cron.hourly/zfs-auto-snapshot
    fi
    # keep 7 daily snapshots
    if [ -f "/etc/cron.daily/zfs-auto-snapshot" ] ; then
      sed -i 's|--keep=[0-9]*|--keep=7|g' /etc/cron.daily/zfs-auto-snapshot
    fi
    # keep 4 weekly snapshots
    if [ -f "/etc/cron.weekly/zfs-auto-snapshot" ] ; then
      sed -i 's|--keep=[0-9]*|--keep=4|g' /etc/cron.weekly/zfs-auto-snapshot
    fi
    # keep 3 monthly snapshots
    if [ -f "/etc/cron.monthly/zfs-auto-snapshot" ] ; then
      sed -i 's|--keep=[0-9]*|--keep=3|g' /etc/cron.monthly/zfs-auto-snapshot
    fi
fi

if [ "${MY_KSMTUNED,,}" == "yes" ] ; then
    ## Ensure ksmtuned (ksm-control-daemon) is enabled and optimise according to ram size
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install ksm-control-daemon
    if [[ RAM_SIZE_GB -le 16 ]] ; then
        # start at 50% full
        KSM_THRES_COEF=50
        KSM_SLEEP_MSEC=80
    elif [[ RAM_SIZE_GB -le 32 ]] ; then
        # start at 60% full
        KSM_THRES_COEF=40
        KSM_SLEEP_MSEC=60
    elif [[ RAM_SIZE_GB -le 64 ]] ; then
        # start at 70% full
        KSM_THRES_COEF=30
        KSM_SLEEP_MSEC=40
    elif [[ RAM_SIZE_GB -le 128 ]] ; then
        # start at 80% full
        KSM_THRES_COEF=20
        KSM_SLEEP_MSEC=20
    else
        # start at 90% full
        KSM_THRES_COEF=10
        KSM_SLEEP_MSEC=10
    fi
    sed -i -e "s/\# KSM_THRES_COEF=.*/KSM_THRES_COEF=${KSM_THRES_COEF}/g" /etc/ksmtuned.conf
    sed -i -e "s/\# KSM_SLEEP_MSEC=.*/KSM_SLEEP_MSEC=${KSM_SLEEP_MSEC}/g" /etc/ksmtuned.conf
    systemctl enable ksmtuned
fi

if [ "${MY_AMDFIXES,,}" == "yes" ] ; then
    ## Detect AMD EPYC and Ryzen CPU and Apply Fixes
    if [ "$(grep -i -m 1 "model name" /proc/cpuinfo | grep -i "EPYC")" != "" ]; then
      echo "AMD EPYC detected"
    elif [ "$(grep -i -m 1 "model name" /proc/cpuinfo | grep -i "Ryzen")" != "" ]; then
      echo "AMD Ryzen detected"
    else
        MY_AMDFIXES="no"
    fi

    if [ "${MY_AMDFIXES,,}" == "yes" ] ; then
      #Apply fix to kernel : Fixes random crashing and instability
        if ! grep "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | grep -q "idle=nomwait" ; then
            echo "Setting kernel idle=nomwait"
            sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="idle=nomwait /g' /etc/default/grub
            update-grub
        fi
        ## Add msrs ignore to fix Windows guest on EPIC/Ryzen host
        echo "options kvm ignore_msrs=Y" >> /etc/modprobe.d/kvm.conf
        echo "options kvm report_ignored_msrs=N" >> /etc/modprobe.d/kvm.conf

        echo "Installing kernel 5.15"
        /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install pve-kernel-5.15
    fi
fi

if [ "${MY_KERNELHEADERS,,}" == "yes" ] ; then
    ## Install kernel source headers
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install pve-headers module-assistant
fi

# if [ "$MY_KEXEC" == "yes" ] ; then
#     ## Install kexec, allows for quick reboots into the latest updated kernel set as primary in the boot-loader.
#     # use command 'reboot-quick'
#     echo "kexec-tools kexec-tools/load_kexec boolean false" | debconf-set-selections
#     /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install kexec-tools
#     cat <<'EOF' > /etc/systemd/system/kexec-pve.service
# [Unit]
# Description=Loading new kernel into memory
# Documentation=man:kexec(8)
# DefaultDependencies=no
# Before=reboot.target
# RequiresMountsFor=/boot
# #Before=shutdown.target umount.target final.target

# [Service]
# Type=oneshot
# RemainAfterExit=yes
# ExecStart=/sbin/kexec -d -l /boot/pve/vmlinuz --initrd=/boot/pve/initrd.img --reuse-cmdline

# [Install]
# WantedBy=default.target
# EOF
#     systemctl enable kexec-pve.service
#     echo "alias reboot-quick='systemctl kexec'" >> /root/.bash_profile
# fi

if [ "${MY_DISABLERPC,,}" == "yes" ] ; then
    ## Disable portmapper / rpcbind (security)
    systemctl disable rpcbind
    systemctl stop rpcbind
fi

if [ "${MY_TIMEZONE}" == "" ] ; then
    ## Set Timezone, empty = set automatically by ip
    this_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
    timezone="$(curl "https://ipapi.co/${this_ip}/timezone")"
    if [ "$timezone" != "" ] ; then
        echo "Found $timezone for ${this_ip}"
        timedatectl set-timezone "$timezone"
    else
        echo "WARNING: Timezone not found for ${this_ip}, set to UTC"
        timedatectl set-timezone UTC
    fi
else
    ## Set Timezone to MY_TIMEZONE
    timedatectl set-timezone "$MY_TIMEZONE"
fi

if [ "${MY_TIMESYNC,,}" == "yes" ] ; then
    timedatectl set-ntp true
fi

if [ "${MY_GUESTAGENT,,}" == "yes" ] ; then
    ## Detect if is running in a virtual machine and install the relavant guest agent
    if [ "$(dmidecode -s system-manufacturer | xargs)" == "QEMU" ] || [ "$(systemd-detect-virt | xargs)" == "kvm" ] ; then
      echo "QEMU Detected, installing guest agent"
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install qemu-guest-agent
    elif [ "$(systemd-detect-virt | xargs)" == "vmware" ] ; then
      echo "VMware Detected, installing vm-tools"
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install open-vm-tools
    elif [ "$(systemd-detect-virt | xargs)" == "oracle" ] ; then
      echo "Virtualbox Detected, installing guest-utils"
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install virtualbox-guest-utils
    fi
fi

if [ "${MY_PIGZ,,}" == "yes" ] ; then
    ## Set pigz to replace gzip, 2x faster gzip compression
    sed -i "s/#pigz:.*/pigz: 1/" /etc/vzdump.conf
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install pigz
    cat  <<EOF > /bin/pigzwrapper
#!/bin/sh
# eXtremeSHOK.com
PATH=/bin:\$PATH
GZIP="-1"
exec /usr/bin/pigz "\$@"
EOF
    mv -f /bin/gzip /bin/gzip.original
    cp -f /bin/pigzwrapper /bin/gzip
    chmod +x /bin/pigzwrapper
    chmod +x /bin/gzip
fi

if [ "${MY_OVHRTM,,}" == "yes" ] ; then
    ## Detect if this is an OVH server by getting the global IP and checking the ASN, then install OVH RTM (real time monitoring)"
    if [ "$(whois -h v4.whois.cymru.com " -t $(curl ipinfo.io/ip 2> /dev/null)" | tail -n 1 | cut -d'|' -f3 | grep -i "ovh")" != "" ] ; then
      echo "Deteted OVH Server, installing OVH RTM (real time monitoring)"
      # http://help.ovh.co.uk/RealTimeMonitoring
      # https://docs.ovh.com/gb/en/dedicated/install-rtm/
      wget -qO - https://last-public-ovh-infra-yak.snap.mirrors.ovh.net/yak/archives/apply.sh | OVH_PUPPET_MANIFEST=distribyak/catalog/master/puppet/manifests/common/rtmv2.pp bash
    fi
fi

if [ "${MY_FAIL2BAN,,}" == "yes" ] ; then
    ## Protect the web interface with fail2ban
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install fail2ban
    # shellcheck disable=1117
cat <<EOF > /etc/fail2ban/filter.d/proxmox.conf
[Definition]
failregex = pvedaemon\[.*authentication failure; rhost=<HOST> user=.* msg=.*
ignoreregex =
EOF

cat <<EOF > /etc/fail2ban/jail.d/proxmox.conf
[proxmox]
enabled = true
port = https,http,8006,8007
filter = proxmox
logpath = /var/log/daemon.log
maxretry = 3
# 1 hour
bantime = 3600
findtime = 600
EOF

# cat <<EOF > /etc/fail2ban/jail.local
# [DEFAULT]
# banaction = iptables-ipset-proto4
# EOF

    systemctl enable fail2ban

    #     ##testing
    #     #fail2ban-regex /var/log/daemon.log /etc/fail2ban/filter.d/proxmox.conf
fi

if [ "${MY_NOSUBBANNER,,}" == "yes" ] ; then
    ## Remove subscription banner
    if [ -f "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js" ] ; then
      # create a daily cron to make sure the banner does not re-appear
  cat <<'EOF' > /etc/cron.daily/xs-pve-nosub
#!/bin/sh
# eXtremeSHOK.com Remove subscription banner
sed -i "s/data.status !== 'Active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
sed -i "s/checked_command: function(orig_cmd) {/checked_command: function() {} || function(orig_cmd) {/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
EOF
      chmod 755 /etc/cron.daily/xs-pve-nosub
      bash /etc/cron.daily/xs-pve-nosub
    fi
    # Remove nag @tinof
    echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt/apt.conf.d/xs-pve-no-nag && apt --reinstall install proxmox-widget-toolkit
fi

if [ "${MY_MOTD,,}" == "yes" ] ; then
## Pretty MOTD BANNER
  if ! grep -q https "/etc/motd" ; then
    cat << 'EOF' > /etc/motd.new
	   This system is optimised by: eXtremeSHOK.com
EOF

    cat /etc/motd >> /etc/motd.new
    mv /etc/motd.new /etc/motd
  fi
fi

if [ "${MY_KERNELPANIC,,}" == "yes" ] ; then
    # Enable restart on kernel panic
    cat <<EOF > /etc/sysctl.d/99-xs-kernelpanic.conf
# eXtremeSHOK.com
# Enable restart on kernel panic, kernel oops and hardlockup
kernel.core_pattern=/var/crash/core.%t.%p
# Reboot on kernel panic afetr 10s
kernel.panic=10
# Panic on kernel oops, kernel exploits generally create an oops
kernel.panic_on_oops=1
# Panic on a hardlockup
kernel.hardlockup_panic=1
EOF
fi

if [ "${MY_LIMITS,,}" == "yes" ] ; then
    ## Increase max user watches
    # BUG FIX : No space left on device
    cat <<EOF > /etc/sysctl.d/99-xs-maxwatches.conf
# eXtremeSHOK.com
# Increase max user watches
fs.inotify.max_user_watches=1048576
fs.inotify.max_user_instances=1048576
fs.inotify.max_queued_events=1048576
EOF
    ## Increase max FD limit / ulimit
    cat <<EOF >> /etc/security/limits.d/99-xs-limits.conf
# eXtremeSHOK.com
# Increase max FD limit / ulimit
* soft     nproc          1048576
* hard     nproc          1048576
* soft     nofile         1048576
* hard     nofile         1048576
root soft     nproc          unlimited
root hard     nproc          unlimited
root soft     nofile         unlimited
root hard     nofile         unlimited
EOF
    ## Increase kernel max Key limit
    cat <<EOF > /etc/sysctl.d/99-xs-maxkeys.conf
# eXtremeSHOK.com
# Increase kernel max Key limit
kernel.keys.root_maxkeys=1000000
kernel.keys.maxkeys=1000000
EOF
    ## Set systemd ulimits
    echo "DefaultLimitNOFILE=256000" >> /etc/systemd/system.conf
    echo "DefaultLimitNOFILE=256000" >> /etc/systemd/user.conf

    echo 'session required pam_limits.so' >> /etc/pam.d/common-session
    echo 'session required pam_limits.so' >> /etc/pam.d/runuser-l

    ## Set ulimit for the shell user
    echo "ulimit -n 256000" >> /root/.profile
fi

if [ "${MY_LOGROTATE,,}" == "yes" ] ; then
    ## Optimise logrotate
    cat <<EOF > /etc/logrotate.conf
# eXtremeSHOK.com
daily
su root adm
rotate 7
create
compress
size=10M
delaycompress
copytruncate

include /etc/logrotate.d
EOF
    systemctl restart logrotate
fi

if [ "${MY_JOURNALD,,}" == "yes" ] ; then
    ## Limit the size and optimise journald
    cat <<EOF > /etc/systemd/journald.conf
# eXtremeSHOK.com
[Journal]
# Store on disk
Storage=persistent
# Don't split Journald logs by user
SplitMode=none
# Disable rate limits
RateLimitInterval=0
RateLimitIntervalSec=0
RateLimitBurst=0
# Disable Journald forwarding to syslog
ForwardToSyslog=no
# Journald forwarding to wall /var/log/kern.log
ForwardToWall=yes
# Disable signing of the logs, save cpu resources.
Seal=no
Compress=yes
# Fix the log size
SystemMaxUse=64M
RuntimeMaxUse=60M
# Optimise the logging and speed up tasks
MaxLevelStore=warning
MaxLevelSyslog=warning
MaxLevelKMsg=warning
MaxLevelConsole=notice
MaxLevelWall=crit
EOF
    systemctl restart systemd-journald.service
    journalctl --vacuum-size=64M --vacuum-time=1d;
    journalctl --rotate
fi

if [ "${MY_ENTROPY,,}" == "yes" ] ; then
## Ensure Entropy Pools are Populated, prevents slowdowns whilst waiting for entropy
    /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install haveged
    ## Net optimising
    cat <<EOF > /etc/default/haveged
# eXtremeSHOK.com
#   -w sets low entropy watermark (in bits)
DAEMON_ARGS="-w 1024"
EOF
    systemctl daemon-reload
    systemctl enable haveged
fi

if [ "${MY_VZDUMP,,}" == "yes" ] ; then
    ## Increase vzdump backup speed
    sed -i "s/#bwlimit:.*/bwlimit: 0/" /etc/vzdump.conf
    sed -i "s/#ionice:.*/ionice: 5/" /etc/vzdump.conf
fi

if [ "${MY_MEMORYFIXES,,}" == "yes" ] ; then
    ## Optimise Memory
cat <<EOF > /etc/sysctl.d/99-xs-memory.conf
# eXtremeSHOK.com
# Memory Optimising
## Bugfix: reserve 1024MB memory for system
vm.min_free_kbytes=1048576
vm.nr_hugepages=72
# (Redis/MongoDB)
vm.max_map_count=262144
vm.overcommit_memory = 1
EOF
fi

if [ "${MY_TCPBBR,,}" == "yes" ] ; then
## Enable TCP BBR congestion control
cat <<EOF > /etc/sysctl.d/99-xs-kernel-bbr.conf
# eXtremeSHOK.com
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
fi

if [ "${MY_TCPFASTOPEN,,}" == "yes" ] ; then
## Enable TCP fastopen
cat <<EOF > /etc/sysctl.d/99-xs-tcp-fastopen.conf
# eXtremeSHOK.com
# TCP fastopen
net.ipv4.tcp_fastopen=3
EOF
fi

if [ "${MY_NET,,}" == "yes" ] ; then
## Enable Network optimising
cat <<EOF > /etc/sysctl.d/99-xs-net.conf
# eXtremeSHOK.com
net.core.netdev_max_backlog=8192
net.core.optmem_max=8192
net.core.rmem_max=16777216
net.core.somaxconn=8151
net.core.wmem_max=16777216
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_base_mss = 1024
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=240
net.ipv4.tcp_limit_output_bytes=65536
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_rmem=8192 87380 16777216
net.ipv4.tcp_sack=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_wmem=8192 65536 16777216
net.netfilter.nf_conntrack_generic_timeout = 60
net.netfilter.nf_conntrack_helper=0
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 28800
net.unix.max_dgram_qlen = 4096
EOF
fi

if [ "${MY_SWAPPINESS,,}" == "yes" ] ; then
    ## Bugfix: high swap usage with low memory usage
    cat <<EOF > /etc/sysctl.d/99-xs-swap.conf
# eXtremeSHOK.com
# Bugfix: high swap usage with low memory usage
vm.swappiness=10
EOF
fi

if [ "${MY_MAXFS,,}" == "yes" ] ; then
    ## Increase Max FS open files
    cat <<EOF > /etc/sysctl.d/99-xs-fs.conf
# eXtremeSHOK.com
# Max FS Optimising
fs.nr_open=12000000
fs.file-max=9000000
fs.aio-max-nr=524288
EOF
fi

if [ "${MY_BASHRC,,}" == "yes" ] ; then
    ## Customise bashrc (thanks broeckca)
    cat <<EOF >> /root/.bashrc
export HISTTIMEFORMAT="%d/%m/%y %T "
export PS1='\u@\h:\W \$ '
alias l='ls -CF'
alias la='ls -A'
alias ll='ls -alF'
alias ls='ls --color=auto'
source /etc/profile.d/bash_completion.sh
export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\\$ "
EOF
    echo "source /root/.bashrc" >> /root/.bash_profile
fi

if [ "${MY_ZFSARC,,}" == "yes" ] ; then
    ## Optimise ZFS arc size accoring to memory size
    if [ "$(command -v zfs)" != "" ] ; then
      if [[ RAM_SIZE_GB -le 16 ]] ; then
        MY_ZFS_ARC_MIN=536870911
        MY_ZFS_ARC_MAX=536870912
    elif [[ RAM_SIZE_GB -le 32 ]] ; then
        # 1GB/1GB
        MY_ZFS_ARC_MIN=1073741823
        MY_ZFS_ARC_MAX=1073741824
      else
        MY_ZFS_ARC_MIN=$((RAM_SIZE_GB * 1073741824 / 16))
        MY_ZFS_ARC_MAX=$((RAM_SIZE_GB * 1073741824 / 8))
      fi
      # Enforce the minimum, incase of a faulty vmstat
      if [[ MY_ZFS_ARC_MIN -lt 536870911 ]] ; then
        MY_ZFS_ARC_MIN=536870911
      fi
      if [[ MY_ZFS_ARC_MAX -lt 536870912 ]] ; then
        MY_ZFS_ARC_MAX=536870912
      fi
      cat <<EOF > /etc/modprobe.d/99-xs-zfsarc.conf
# eXtremeSHOK.com ZFS tuning

# Use 1/8 RAM for MAX cache, 1/16 RAM for MIN cache, or 1GB
options zfs zfs_arc_min=$MY_ZFS_ARC_MIN
options zfs zfs_arc_max=$MY_ZFS_ARC_MAX

# use the prefetch method
options zfs l2arc_noprefetch=0

# max write speed to l2arc
# tradeoff between write/read and durability of ssd (?)
# default : 8 * 1024 * 1024
# setting here : 500 * 1024 * 1024
options zfs l2arc_write_max=524288000
options zfs zfs_txg_timeout=60
EOF
    fi
fi


# Fix missing /etc/network/interfaces.d include
if ! grep -q 'source /etc/network/interfaces.d/*' "/etc/network/interfaces" ; then
    echo "Added missing include to /etc/network/interfaces"
    echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
fi

if [ "${MY_VFIO_IOMMU,,}" == "yes" ] ; then
    # Enable IOMMU
    cpu=$(cat /proc/cpuinfo)
    if [[ $cpu == *"GenuineIntel"* ]]; then
        echo "Detected Intel CPU"
        sed -i 's/quiet/quiet intel_iommu=on iommu=pt/g' /etc/default/grub
    elif [[ $cpu == *"AuthenticAMD"* ]]; then
        echo "Detected AMD CPU"
        sed -i 's/quiet/quiet amd_iommu=on iommu=pt/g' /etc/default/grub
    else
        echo "Unknown CPU"
    fi

    cat <<EOF >> /etc/modules
# eXtremeSHOK.com
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

EOF
    cat <<EOF >> /etc/modprobe.d/blacklist.conf
# eXtremeSHOK.com
blacklist nouveau
blacklist lbm-nouveau
options nouveau modeset=0
blacklist amdgpu
blacklist radeon
blacklist nvidia
blacklist nvidiafb

EOF

fi

# propagate the settings
update-initramfs -u -k all
update-grub
pve-efiboot-tool refresh

# cleanup
## Remove no longer required packages and purge old cached updates
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoremove
/usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoclean

echo "# proxmox-post-install.sh" > /etc/proxmox-post-install
date >> /etc/proxmox-post-install

## Script Finish
echo -e '\033[1;33m Finished....please restart the system \033[0m'
