#!/bin/bash
. /tmp/firstrun.utils
FILE=/tmp/firstrun.log
if [ ! -e $FILE ]
 then
     touch $FILE
     nohup $0 0<&- &>/dev/null &
     exit
fi
exec 1<&-
exec 2<&-
exec 1<>$FILE
exec 2>&1
date
checkStatusnoret
export Instance_ID=`curl http://169.254.169.254/latest/meta-data/instance-id`
echo 'starting tmsh config'
tmsh modify sys global-settings gui-setup disabled
tmsh modify sys httpd auth-pam-validate-ip off
tmsh modify auth password-policy policy-enforcement disabled
tmsh modify auth user admin password ${Instance_ID}
tmsh create auth user BigIPk8s partition-access add { all-partitions { role admin }} password ${Instance_ID}
tmsh save /sys config
date
echo 'provisioning required modules'
tmsh modify sys provision avr asm level nominal
tmsh save /sys config
checkStatusnoret
echo 'configure self-ip'
for mac in `curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/`
    do
        device_number=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac:0:-1}/device-number`
        case $device_number in
        0)
            ;;
        1)
            dev1_cdr=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac:0:-1}/subnet-ipv4-cidr-block`
            dev1_pfx=${dev1_cdr#*/}
            dev1_int=`tmsh list net interface one-line | grep -i ${mac:0:-1} | awk '{print $3}'`
            ;;
        2)
            dev2_cdr=`curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac:0:-1}/subnet-ipv4-cidr-block`
            dev2_pfx=${dev2_cdr#*/}
            dev2_int=`tmsh list net interface one-line | grep -i ${mac:0:-1} | awk '{print $3}'`
            ;;
        esac
    done
tmsh create net vlan external interfaces add { ${dev1_int} { untagged} }
tmsh create net vlan internal interfaces add { ${dev2_int} { untagged} }
{ Fn::Sub: [ tmsh create net self ${Self_IP}, { Self_IP: { Fn::Select : [1, {Fn::GetAtt : [ ENAPublicBigIP02 , SecondaryPrivateIpAddresses ]} ] } }]}, /${dev1_pfx}  vlan external allow-service none traffic-group traffic-group-local-only
{ Fn::Sub: [ tmsh create net self ${Self_IP}, { Self_IP: { Fn::Select : [0, {Fn::GetAtt : [ ENAPublicBigIP02 , SecondaryPrivateIpAddresses ]} ] } }]}, /${dev1_pfx}  vlan external allow-service none traffic-group traffic-group-1
{ Fn::Sub: [ tmsh create net self ${Self_IP}, { Self_IP: { Fn::Select : [1, {Fn::GetAtt : [ ENAPrivateBigIP01 , SecondaryPrivateIpAddresses ]} ] } }]}, /${dev2_pfx}  vlan internal allow-service default traffic-group traffic-group-local-only
{ Fn::Sub: [ tmsh create net self ${Self_IP}, { Self_IP: { Fn::Select : [0, {Fn::GetAtt : [ ENAPrivateBigIP01 , SecondaryPrivateIpAddresses ]} ] } }]}, /${dev2_pfx}  vlan internal allow-service default traffic-group traffic-group-1
date
echo 'create virtual-servers'
{ Fn::Sub: [ tmsh create ltm virtual k8s_vip_https destination ${Destination_IP}:443  profiles add { http {} clientssl { context clientside } } vlans add { external } source-address-translation { type automap } { Destination_IP: {Fn::GetAtt : [ ENAPublicBigIP02 , PrimaryPrivateIpAddress ]} }]},
date
# typically want to remove firstrun.config after first boot
# rm /tmp/firstrun.config
