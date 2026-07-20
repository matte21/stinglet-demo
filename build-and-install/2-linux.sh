#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

cfg_local_version="${cfg_local_version:-stinglet-fg-cgroups}"

if [[ $# -gt 1 ]]; then
    echo "Error: at most one argument allowed" >&2
    echo "Usage: $0 [all (default)|build-only|install-only]" >&2
    exit 1
fi
actions="${1:-all}"
if [[ "$actions" != "all" && "$actions" != "build-only" && "$actions" != "install-only" ]]; then
    echo "Unknown argument: $1" >&2
    echo "Usage: $0 [all (default)|build-only|install-only]" >&2
    exit 1
fi

readonly linux_src_tree="components/linux"
cd "$linux_src_tree"

if [[ "$actions" == "all" || "$actions" == "build-only" ]]; then
    # Install build dependencies.
    sudo apt-get update -y
    sudo apt-get install -y flex bison libelf-dev libssl-dev

    # Get a base Linux config from the current one, but updated with default values
    # for the new config parameters.
    sudo make mrproper
    sudo cp "/boot/config-$(uname -r)" .config
    sudo make olddefconfig

    # Make sure that we build only the modules we need, i.e., those currently enabled. 
    readonly mod_file="/tmp/lsmod.now"
    sudo lsmod > $mod_file
    sudo make LSMOD=$mod_file localmodconfig

    sudo scripts/config --set-str CONFIG_LOCALVERSION "$cfg_local_version"

    # Disable a config parameters that causes the build to fail (this is bad for security, but I
    # haven't found a safe workaround yet).
    sudo scripts/config --disable SYSTEM_REVOCATION_KEYS

    # We use CRI-O as a container runtime, which wants the overlay fs module, which requires the
    # following config options.
    sudo scripts/config --module CONFIG_OVERLAY_FS
    sudo scripts/config --enable CONFIG_OVERLAY_FS_REDIRECT_ALWAYS_FOLLOW
    sudo scripts/config --enable CONFIG_OVERLAY_FS_XINO_AUTO

    # CRI-O uses nf_tables, so we need the corresponding modules.
    sudo scripts/config --module CONFIG_NF_CONNTRACK
    sudo scripts/config --module CONFIG_NF_LOG_SYSLOG
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_MARK
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_SECMARK
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_ZONES
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_EVENTS
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_TIMEOUT
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_TIMESTAMP
    sudo scripts/config --enable CONFIG_NF_CONNTRACK_LABELS
    sudo scripts/config --enable CONFIG_NF_CT_PROTO_DCCP
    sudo scripts/config --enable CONFIG_NF_CT_PROTO_GRE
    sudo scripts/config --enable CONFIG_NF_CT_PROTO_SCTP
    sudo scripts/config --enable CONFIG_NF_CT_PROTO_UDPLITE
    sudo scripts/config --module CONFIG_NF_CONNTRACK_AMANDA
    sudo scripts/config --module CONFIG_NF_CONNTRACK_FTP
    sudo scripts/config --module CONFIG_NF_CONNTRACK_H323
    sudo scripts/config --module CONFIG_NF_CONNTRACK_IRC
    sudo scripts/config --module CONFIG_NF_CONNTRACK_BROADCAST
    sudo scripts/config --module CONFIG_NF_CONNTRACK_NETBIOS_NS
    sudo scripts/config --module CONFIG_NF_CONNTRACK_SNMP
    sudo scripts/config --module CONFIG_NF_CONNTRACK_PPTP
    sudo scripts/config --module CONFIG_NF_CONNTRACK_SANE
    sudo scripts/config --module CONFIG_NF_CONNTRACK_SIP
    sudo scripts/config --module CONFIG_NF_CONNTRACK_TFTP
    sudo scripts/config --module CONFIG_NF_CT_NETLINK
    sudo scripts/config --module CONFIG_NF_CT_NETLINK_TIMEOUT
    sudo scripts/config --module CONFIG_NF_CT_NETLINK_HELPER
    sudo scripts/config --module CONFIG_NF_NAT
    sudo scripts/config --module CONFIG_NF_NAT_AMANDA
    sudo scripts/config --module CONFIG_NF_NAT_FTP
    sudo scripts/config --module CONFIG_NF_NAT_IRC
    sudo scripts/config --module CONFIG_NF_NAT_SIP
    sudo scripts/config --module CONFIG_NF_NAT_TFTP
    sudo scripts/config --enable CONFIG_NF_NAT_REDIRECT
    sudo scripts/config --enable CONFIG_NF_NAT_MASQUERADE
    sudo scripts/config --module CONFIG_NF_TABLES
    sudo scripts/config --enable CONFIG_NF_TABLES_INET
    sudo scripts/config --enable CONFIG_NF_TABLES_NETDEV
    sudo scripts/config --module CONFIG_NF_DUP_NETDEV
    sudo scripts/config --module CONFIG_NF_FLOW_TABLE_INET
    sudo scripts/config --module CONFIG_NF_FLOW_TABLE
    sudo scripts/config --enable CONFIG_NF_FLOW_TABLE_PROCFS
    sudo scripts/config --module CONFIG_NF_DEFRAG_IPV4
    sudo scripts/config --module CONFIG_NF_SOCKET_IPV4
    sudo scripts/config --module CONFIG_NF_TPROXY_IPV4
    sudo scripts/config --enable CONFIG_NF_TABLES_IPV4
    sudo scripts/config --enable CONFIG_NF_TABLES_ARP
    sudo scripts/config --module CONFIG_NF_FLOW_TABLE_IPV4
    sudo scripts/config --module CONFIG_NF_DUP_IPV4
    sudo scripts/config --module CONFIG_NF_LOG_ARP
    sudo scripts/config --module CONFIG_NF_LOG_IPV4
    sudo scripts/config --module CONFIG_NF_REJECT_IPV4
    sudo scripts/config --module CONFIG_NF_NAT_SNMP_BASIC
    sudo scripts/config --module CONFIG_NF_NAT_PPTP
    sudo scripts/config --module CONFIG_NF_NAT_H323
    sudo scripts/config --module CONFIG_NF_SOCKET_IPV6
    sudo scripts/config --module CONFIG_NF_TPROXY_IPV6
    sudo scripts/config --module CONFIG_NF_TABLES_IPV6
    sudo scripts/config --module CONFIG_NF_FLOW_TABLE_IPV6
    sudo scripts/config --module CONFIG_NF_DUP_IPV6
    sudo scripts/config --module CONFIG_NF_REJECT_IPV6
    sudo scripts/config --module CONFIG_NF_LOG_IPV6
    sudo scripts/config --module CONFIG_NF_DEFRAG_IPV6
    sudo scripts/config --module CONFIG_NF_TABLES_BRIDGE
    sudo scripts/config --module CONFIG_NF_CONNTRACK_BRIDGE
    sudo scripts/config --module CONFIG_NFT_NUMGEN
    sudo scripts/config --module CONFIG_NFT_CT
    sudo scripts/config --module CONFIG_NFT_FLOW_OFFLOAD
    sudo scripts/config --module CONFIG_NFT_COUNTER
    sudo scripts/config --module CONFIG_NFT_CONNLIMIT
    sudo scripts/config --module CONFIG_NFT_LOG
    sudo scripts/config --module CONFIG_NFT_LIMIT
    sudo scripts/config --module CONFIG_NFT_MASQ
    sudo scripts/config --module CONFIG_NFT_REDIR
    sudo scripts/config --module CONFIG_NFT_NAT
    sudo scripts/config --module CONFIG_NFT_TUNNEL
    sudo scripts/config --module CONFIG_NFT_OBJREF
    sudo scripts/config --module CONFIG_NFT_QUEUE
    sudo scripts/config --module CONFIG_NFT_QUOTA
    sudo scripts/config --module CONFIG_NFT_REJECT
    sudo scripts/config --module CONFIG_NFT_REJECT_INET
    sudo scripts/config --module CONFIG_NFT_COMPAT
    sudo scripts/config --module CONFIG_NFT_HASH
    sudo scripts/config --module CONFIG_NFT_FIB
    sudo scripts/config --module CONFIG_NFT_FIB_INET
    sudo scripts/config --module CONFIG_NFT_XFRM
    sudo scripts/config --module CONFIG_NFT_SOCKET
    sudo scripts/config --module CONFIG_NFT_OSF
    sudo scripts/config --module CONFIG_NFT_TPROXY
    sudo scripts/config --module CONFIG_NFT_SYNPROXY
    sudo scripts/config --module CONFIG_NFT_DUP_NETDEV
    sudo scripts/config --module CONFIG_NFT_FWD_NETDEV
    sudo scripts/config --module CONFIG_NFT_FIB_NETDEV
    sudo scripts/config --module CONFIG_NFT_REJECT_NETDEV
    sudo scripts/config --module CONFIG_NFT_REJECT_IPV4
    sudo scripts/config --module CONFIG_NFT_DUP_IPV4
    sudo scripts/config --module CONFIG_NFT_FIB_IPV4
    sudo scripts/config --module CONFIG_NFT_REJECT_IPV6
    sudo scripts/config --module CONFIG_NFT_DUP_IPV6
    sudo scripts/config --module CONFIG_NFT_FIB_IPV6
    sudo scripts/config --module CONFIG_NFT_BRIDGE_META
    sudo scripts/config --module CONFIG_NFT_BRIDGE_REJECT
    sudo scripts/config --module CONFIG_NFTL
    sudo scripts/config --enable CONFIG_NFTL_RW

    # kubelet needs the netfilter module, so we add the config to enable it.
    sudo scripts/config --enable CONFIG_NETFILTER
    sudo scripts/config --enable CONFIG_NETFILTER_ADVANCED
    sudo scripts/config --enable CONFIG_NETFILTER_INGRESS
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK
    sudo scripts/config --enable CONFIG_NETFILTER_FAMILY_BRIDGE
    sudo scripts/config --enable CONFIG_NETFILTER_FAMILY_ARP
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK_HOOK
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK_QUEUE
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK_ACCT
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK_LOG
    sudo scripts/config --module CONFIG_NETFILTER_NETLINK_OSF
    sudo scripts/config --module CONFIG_NETFILTER_CONNCOUNT
    sudo scripts/config --enable CONFIG_NETFILTER_NETLINK_GLUE_CT
    sudo scripts/config --module CONFIG_NETFILTER_SYNPROXY
    sudo scripts/config --module CONFIG_NETFILTER_XTABLES
    sudo scripts/config --enable CONFIG_NETFILTER_XTABLES_COMPAT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_CONNMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_SET
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_AUDIT
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_CHECKSUM
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_CLASSIFY
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_CONNMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_CONNSECMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_CT
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_DSCP
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_HL
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_HMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_IDLETIMER
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_LED
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_LOG
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_MARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_NAT
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_NETMAP
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_NFLOG
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_NFQUEUE
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_RATEEST
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_REDIRECT
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_MASQUERADE
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_TEE
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_TPROXY
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_TRACE
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_SECMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_TCPMSS
    sudo scripts/config --module CONFIG_NETFILTER_XT_TARGET_TCPOPTSTRIP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_BPF
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CGROUP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CLUSTER
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_COMMENT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CONNBYTES
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CONNLABEL
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CONNLIMIT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CONNMARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CONNTRACK
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_CPU
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_DCCP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_DEVGROUP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_DSCP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_ECN
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_ESP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_HASHLIMIT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_HELPER
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_HL
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_IPCOMP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_IPRANGE
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_IPVS
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_L2TP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_LENGTH
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_LIMIT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_MAC
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_MARK
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_MULTIPORT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_NFACCT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_OSF
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_OWNER
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_POLICY
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_PHYSDEV
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_PKTTYPE
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_QUOTA
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_RATEEST
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_REALM
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_RECENT
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_SCTP
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_SOCKET
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_STATE
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_STATISTIC
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_STRING
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_TCPMSS
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_TIME
    sudo scripts/config --module CONFIG_NETFILTER_XT_MATCH_U32

    # Enable bridge module in KConfig (CRI-O wants it).
    sudo scripts/config --module CONFIG_BRIDGE_NETFILTER
    sudo scripts/config --enable CONFIG_NETFILTER_FAMILY_BRIDGE
    sudo scripts/config --module CONFIG_NF_TABLES_BRIDGE
    sudo scripts/config --module CONFIG_NFT_BRIDGE_META
    sudo scripts/config --module CONFIG_NFT_BRIDGE_REJECT
    sudo scripts/config --module CONFIG_BRIDGE_NF_EBTABLES
    sudo scripts/config --module CONFIG_BRIDGE_EBT_BROUTE
    sudo scripts/config --module CONFIG_BRIDGE_EBT_T_FILTER
    sudo scripts/config --module CONFIG_BRIDGE_EBT_T_NAT
    sudo scripts/config --module CONFIG_BRIDGE_EBT_802_3
    sudo scripts/config --module CONFIG_BRIDGE_EBT_AMONG
    sudo scripts/config --module CONFIG_BRIDGE_EBT_ARP
    sudo scripts/config --module CONFIG_BRIDGE_EBT_IP
    sudo scripts/config --module CONFIG_BRIDGE_EBT_IP6
    sudo scripts/config --module CONFIG_BRIDGE_EBT_LIMIT
    sudo scripts/config --module CONFIG_BRIDGE_EBT_MARK
    sudo scripts/config --module CONFIG_BRIDGE_EBT_PKTTYPE
    sudo scripts/config --module CONFIG_BRIDGE_EBT_STP
    sudo scripts/config --module CONFIG_BRIDGE_EBT_VLAN
    sudo scripts/config --module CONFIG_BRIDGE_EBT_ARPREPLY
    sudo scripts/config --module CONFIG_BRIDGE_EBT_DNAT
    sudo scripts/config --module CONFIG_BRIDGE_EBT_MARK_T
    sudo scripts/config --module CONFIG_BRIDGE_EBT_REDIRECT
    sudo scripts/config --module CONFIG_BRIDGE_EBT_SNAT
    sudo scripts/config --module CONFIG_BRIDGE_EBT_LOG
    sudo scripts/config --module CONFIG_BRIDGE_EBT_NFLOG
    sudo scripts/config --module CONFIG_BRIDGE
    sudo scripts/config --enable CONFIG_BRIDGE_IGMP_SNOOPING
    sudo scripts/config --enable CONFIG_BRIDGE_VLAN_FILTERING
    sudo scripts/config --enable CONFIG_BRIDGE_MRP
    sudo scripts/config --enable CONFIG_BRIDGE_CFM
    sudo scripts/config --enable CONFIG_MLX5_BRIDGE
    sudo scripts/config --enable CONFIG_SSB_B43_PCI_BRIDGE
    sudo scripts/config --module CONFIG_DVB_DDBRIDGE
    sudo scripts/config --enable CONFIG_CIO2_BRIDGE
    sudo scripts/config --module CONFIG_EDAC_SBRIDGE
    sudo scripts/config --module CONFIG_GREYBUS_BRIDGED_PHY
    sudo scripts/config --module CONFIG_FPGA_BRIDGE
    sudo scripts/config --module CONFIG_ALTERA_FREEZE_BRIDGE
    sudo scripts/config --module CONFIG_FPGA_DFL_FME_BRIDGE
    sudo scripts/config --enable CONFIG_DRM_BRIDGE
    sudo scripts/config --enable CONFIG_DRM_PANEL_BRIDGE

    # Enable VETH module in KConfig (CRI-O wants it).
    sudo scripts/config --module CONFIG_VETH

    # Enable ISO module in KConfig to mount cpuspec.
    sudo scripts/config --module CONFIG_ISO9660_FS

    # Now, build the modified kernel, using as many threads as there are CPUs on this machine for speed. 
    sudo make -j`nproc`

    echo "Linux kernel for stinglet successfully built."
fi

if [[ "$actions" == "all" || "$actions" == "install-only" ]]; then
    # Place the built modules and kernel at the folder where they need to be to run that kernel on start up.
    sudo make modules_install install

    # We don't automatically modify the grub config because it's hairy and because it's different on different
    # machines and because I haven't decided yet which config we want by default.
    echo "Linux kernel for stinglet successfully installed."
    echo "Update \"/etc/default/grub\" by making the newly built kernel the default one,"
    echo "run \"sudo update-grub\", reboot, and you're good to go."
fi
