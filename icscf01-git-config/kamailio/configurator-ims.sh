#!/bin/bash
# TISMI 2021
# Ronald Brakeboer
# Version 3.1
# Based on the https://open5gs.org/open5gs/docs/tutorial/02-VoLTE-setup 
# where the configurator was used to alter (only) the HSS scripts.
# This script is rebuild to do the same for the Kamaili scripts.

# Initialization & global vars for setting up the configuration files for a IMS provisioning
#(E.g for PCSCSF - ICSCF or SCSCF based on the templated Kamailio IMS files Tismi are using)
# if you execute this script for the second time
# you should change these variables to the latest
# domain name and ip address

# Example 
#$_PUBLIC_IP_ 		        (0.0.0.0 for all interfaces)
#$_NAT_IP_ 			(IP To send when UE is behind double NAT)
#$_IP_			        (Internal or LAN IP) 
#$_FQDN_HOSTNAME_		(Fully Qualified Domain name e.g pscsf01.ims.mnc009.mcc234.3gppnetwork.org)
#$_FQDN_HOSTNAME_ESCAPED_	(\Fully\.\Qualified\.\Domain\.\name\ e.g "scscf01\.ims\.mnc009\.mcc234\.3gppnetwork\.org")
#$_DOMAIN_ESCAPED_		(Domain\.name\.tld e.g "ims\.mnc009\.mcc234\.3gppnetwork\.org")
#$_DOMAIN_			(Domain name e.g ims.mnc009.mcc234.3gppnetwork.org)
#$_ALIAS_HOSTNAME_		(Alias hostname e.g pcscf01.oam.as62167.net)
#$_PCRF_REALM_		        (pcrf realm, e.g epc.mnc009.mcc234.3gppnetwork.org)
#$_TRF_HOSTNAME_		(Optional - trf hostname)
#$_HSS_FQDN_HOSTNAME_		(HSS hostname e.g hss.ims.mnc009.mcc234.3gppnetwork.org)
#$_INTERFACE_			(0.0.0.0 for all interfaces)
#$_WEBSOCKET_WEBSERVER_	        (Optional - for incoming Webrtc traffic)
#$_UDP_LISTEN_IP_ 		(upd listening IP)
#$_TCP_LISTEN_IP_ 		(tcp listening IP)
#$_IPSEC_LISTEN_IP_		(Optional - IPSec listening IP)
#$_TLS_LISTEN_IP_		(Optional - TLS listening IP)
#$_RX_AF_SIGNALLING_IP_	(Optional - RX AF Signalling IP)

# End of example

#Maybe optional feature
# Ask user if PCSCF ICSCF or SCSCF config
#
#printf "PCSCF ICSCF or SCSCFf?" 
# Do something with the input
#cd /usr/local/etc/
# tbd sudo git clone git.tismi.com/some-dir/ims/kamailio-templates /usr/local/etc/
# cd kamailio
# For now we just copy them manually 
#
#
#Basic and lazy check if files are there
CONFFILES=`ls -Lhar *.cfg *.xml kamctlrc 2>/dev/null`
FILESFOUND=$(ls -Lhar *.cfg *.xml kamctlrc)
DIRFOUND=$(pwd) 
SUB='kamailio'

case $DIRFOUND in

  *"$SUB"*)
    echo -n "************** Kamailio dir found *********"
    ;;
 *)
    printf "%s\n"
    printf "%s\n*****ERROR*****%s\n"
    printf "Kamailio dir not found !!!"
    printf "%s\n!!!Script will abort now !!!"
    printf "%s\n"
    printf "%s\n!!!Make sure to execute this script in the Kamailio dir!!!"  
  exit 1
    ;;
esac

printf "%s\n$DIRFOUND"
printf "%s\n*************** FILES found: ***************" 
printf "%s\n$FILESFOUND"
printf "%s\n"
printf "%s\n************** Looks ok *********" 
printf "%s\n"
printf "************** if it's not ok press ctrl-c within 5 seconds *********"
sleep 5
printf "%s\n"
printf "%s\n"
printf "%s\nAllright, here we go!%s\n"
printf "%s\n"

# Interaction
printf "Domain: (default: ims.mnc009.mcc234.3gppnetwork.org)" domain
read domain 
domain=${domain:-ims.mnc009.mcc234.3gppnetwork.org}
echo $domain

printf "fqdn domain escaped: (Default ims\.mnc009\.mcc234\.3gppnetwork\.org)" fqdn_domain_escaped
read fqdn_domain_escaped 
fqdn_domain_escaped=${fqdn_domain_escaped:-ims\.mnc009\.mcc234\.3gppnetwork\.org}
echo $fqdn_domain_escaped

printf "fqdn hostname: (default: icscf01.ims.mnc009.mcc234.3gppnetwork.org)" fqdn_hostname
read fqdn_hostname
fqdn_hostname=${fqdn_hostname:-icscf01.ims.mnc009.mcc234.3gppnetwork.org}
echo $fqdn_hostname

printf "fqdn hostname escaped: (default: icscf01\.ims\.mnc009\.mcc234\.3gppnetwork\.org)" fqdn_hostname_escaped
read fqdn_hostname_escaped
fqdn_hostname_escaped=${fqdn_hostname_escaped:-icscf01\.ims\.mnc009\.mcc234\.3gppnetwork\.org}
echo $fqdn_hostname_escaped

printf "alias hostname: (default: icscf01.oam.as62167.net)" alias_hostname
read alias_hostname
alias_hostname=${alias_hostname:-icscf01.oam.as62167.net}
echo $alias_hostname

printf "pcrf realm: (default: epc.mnc009.mcc234.3gppnetwork.org)" pcrf_realm
read pcrf_realm   
pcrf_realm=${pcrf_realm:-epc.mnc009.mcc234.3gppnetwork.org}
echo $pcrf_realm

printf "trf hostname: (default: trf.epc.mnc009.mcc234.3gppnetwork.org)" trf_hostname
read trf_hostname  
trf_hostname=${tfr_hostname:-trf.epc.mnc009.mcc234.3gppnetwork.org}
echo $trf_hostname

printf "hss fqdn hostname: (default: hss01.ims.mnc009.mcc234.3gppnetwork.org)" hss_fqdn_hostname
read hss_fqdn_hostname  
hss_fqdn_hostname=${hss_fqdn_hostname:-hss01.ims.mnc009.mcc234.3gppnetwork.org} 
echo $hss_fqdn_hostname

printf "ip of interface: (default 0.0.0.0)" interface
read interface  
interface=${interface:-0.0.0.0}
echo $interface

printf "websocket webserver: (default 0.0.0.0)" websocket_webserver
read websocket_webserver
websocket_webserver=${websocket_webserver:-0.0.0.0}
echo $websocket_webserver

printf "Public IP Address: (default: 11.22.33.44)" public_ip
read public_ip
public_ip=${public_ip:-11.22.33.44}
echo $public_ip

printf "NAT IP Address: (default 11.22.33.44)" nat_ip
read nat_ip
nat_ip=${nat_ip:-11.22.33.44}
echo $nat_ip

printf "Listening IP Address udp: (default 0.0.0.0)" udp_listen_ip
read udp_listen_ip
udp_listen_ip=${udp_listen_ip:-0.0.0.0}
echo $udp_listen_ip

printf "Listening IP address tcp: (default 0.0.0.0)" tcp_listen_ip
read tcp_listen_ip
tcp_listen_ip=${tcp_listen_ip:-0.0.0.0}
echo $tcp_listen_ip

printf "Listening IPSEC IP address (defaults to default interface IP)" ipsec_listen_ip
read ipsec_listen_ip
ipsec_listen_ip=${ipsec_listen_ip:-$interface}
echo $ipsec_listen_ip

printf "Listening TLS IP address (defaults to default interface IP)" tls_listen_ip
read tls_listen_ip
tls_listen_ip=${tls_listen_ip:-$interface}
echo $tls_listen_ip

printf "Listening RX AF SIGNALLING IP address (defaults to default interface IP)" rx_af_listen_ip
read rx_af_listen_ip
rx_af_listen_ip=${rx_af_listen_ip:-$interface}
echo $rx_af_listen_ip


# input domain is to be slashed for cfg regexes 
fqdn_hostname_escaped=`echo $fqdn_hostname_escaped | sed 's/\./\\\\\\\\\./g'`
fqdn_domain_escaped=`echo $fqdn_domain_escaped | sed 's/\./\\\\\\\\\./g'`

  if [ $# != 0 ] 
  then 
  printf "changing: "
      for j in $* 
      do
sed -i -e  "s/\$_PUBLIC_IP_/$public_ip/g" $j
sed -i -e  "s/\$_NAT_IP_/$nat_ip/g" $j
sed -i -e  "s/\$_FQDN_HOSTNAME_/$fqdn_hostname/g" $j
sed -i -e  "s/\$_FQDN_HOSTNAME_ESCAPED_/$fqdn_hostname_escaped/g" $j    
sed -i -e  "s/\$_DOMAIN_ESCAPED_/$domain_escaped/g" $j      
sed -i -e  "s/\$_DOMAIN_/$domain/g" $j
sed -i -e  "s/\$_ALIAS_HOSTNAME_/$alias_hostname/g" $j
sed -i -e  "s/\$_PCRF_REALM_/$pcrf_realm/g" $j
sed -i -e  "s/\$_TRF_HOSTNAME_/$trf_hostname/g" $j
sed -i -e  "s/\$_HSS_FQDN_HOSTNAME_/$hss_fqdn_hostname/g" $j            
sed -i -e  "s/\$_INTERFACE_/$interface/g" $j            
sed -i -e  "s/\$_WEBSOCKET_WEBSERVER_/$websocket_webserver/g" $j 
sed -i -e  "s/\$_UDP_LISTEN_IP_/$udp_listen_ip/g" $j 
sed -i -e  "s/\$_TCP_LISTEN_IP_/$tcp_listen_ip/g" $j 
sed -i -e  "s/\$_IPSEC_LISTEN_IP_/$ipsec_listen_ip/g" $j
sed -i -e  "s/\$_TLS_LISTEN_IP_/$tls_listen_ip/g" $j
sed -i -e  "s/\$_RX_AF_SIGNALLING_IP_/$rx_af_listen_ip/g" $j


    printf "$j " 
      done
  echo 
  else 
  printf "File to change [\"all\" for everything, \"exit\" to quit]:"
  # loop
      while read filename ;
      do
        if [ "$filename" = "exit" ] 
        then 
        printf "exitting...\n"
        break ;

      elif [ "$filename" = "all" ]
      then    
          printf "changing: "
         for i in $CONFFILES 
         do
sed -i -e   "s/\$_PUBLIC_IP_/$public_ip/g" $i
sed -i -e   "s/\$_NAT_IP_/$nat_ip/g" $i
sed -i -e   "s/\$_FQDN_HOSTNAME_/$fqdn_hostname/g" $i
sed -i -e   "s/\$_FQDN_HOSTNAME_ESCAPED_/$fqdn_hostname_escaped/g" $i    
sed -i -e   "s/\$_DOMAIN_ESCAPED_/$domain_escaped/g" $i      
sed -i -e   "s/\$_DOMAIN_/$domain/g" $i
sed -i -e   "s/\$_ALIAS_HOSTNAME_/$alias_hostname/g" $i
sed -i -e   "s/\$_PCRF_REALM_/$pcrf_realm/g" $i
sed -i -e   "s/\$_TRF_HOSTNAME_/$trf_hostname/g" $i
sed -i -e   "s/\$_HSS_FQDN_HOSTNAME_/$hss_fqdn_hostname/g" $i           
sed -i -e   "s/\$_INTERFACE_/$interface/g" $i            
sed -i -e   "s/\$_WEBSOCKET_WEBSERVER_/$websocket_webserver/g" $i 
sed -i -e   "s/\$_UDP_LISTEN_IP_/$udp_listen_ip/g" $i
sed -i -e   "s/\$_TCP_LISTEN_IP_/$tcp_listen_ip/g" $i
sed -i -e  "s/\$_IPSEC_LISTEN_IP_/$ipsec_listen_ip/g" $i
sed -i -e  "s/\$_TLS_LISTEN_IP_/$tls_listen_ip/g" $i
sed -i -e  "s/\$_RX_AF_SIGNALLING_IP_/$rx_af_listen_ip/g" $i

        printf "$i " 
         done 
         echo 
         break;

        elif [ -w $filename ] 
       then
            printf "changing $filename \n"

sed -i -e "s/\$_PUBLIC_IP_/$public_ip/g" $filename 
sed -i -e "s/\$_NAT_IP_/$nat_ip/g" $filename 
sed -i -e "s/\$_FQDN_HOSTNAME_/$fqdn_hostname/g" $filename 
sed -i -e "s/\$_FQDN_HOSTNAME_ESCAPED_/$fqdn_hostname_escaped/g" $filename     
sed -i -e "s/\$_DOMAIN_ESCAPED_/$domain_escaped/g" $filename 
sed -i -e "s/\$_DOMAIN_/$domain/g" $filename 
sed -i -e "s/\$_ALIAS_HOSTNAME_/$alias_hostname/g" $filename 
sed -i -e "s/\$_PCRF_REALM_/$pcrf_realm/g" $filename 
sed -i -e "s/\$_TRF_HOSTNAME_/$trf_hostname/g" $filename 
sed -i -e "s/\$_HSS_FQDN_HOSTNAME_/$hss_fqdn_hostname/g" $filename             
sed -i -e "s/\$_INTERFACE_/$interface/g" $filename 
sed -i -e "s/\$_WEBSOCKET_WEBSERVER_/$websocket_webserver/g" $filename  
sed -i -e "s/\$_UDP_LISTEN_IP_/$udp_listen_ip/g" $filename
sed -i -e "s/\$_TCP_LISTEN_IP_/$tcp_listen_ip/g" $filename 
sed -i -e  "s/\$_IPSEC_LISTEN_IP_/$ipsec_listen_ip/g" $filename
sed -i -e  "s/\$_TLS_LISTEN_IP_/$tls_listen_ip/g" $filename
sed -i -e  "s/\$_RX_AF_SIGNALLING_IP_/$rx_af_listen_ip/g" $filename


          else 
          printf "cannot access file $filename. skipping... \n" 
        fi
        printf "File to Change:"
      done 
  fi
