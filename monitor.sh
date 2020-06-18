#!/bin/bash

# IFTTT API key to authenticate the use of the webhook
IFTTT_KEY="[your_key]"
IFTTT_EVENT="gwMonitor"

# Configure the gatweays to be monitored
# Format
# ttn_gateway_is, name diplayed on webhook, Monitoring ON/OFF, last gateway state (OK at start)
gatewaysConf=$(cat <<-END
eui-7276ff000805029f,kerlink-bib,ON,OK@
eui-fcc23dfffe207d3d,lorix,ON,OK@
laird-disk91-1,laird-home,ON,OK@
laird-disk91-3,laird-perfect,ON,OK@
eui-58a0cbfffe801791,ttig-solar,ON,OK@
eui-3235313219004700,mikroTik-1,ON,OK@
laird-disk91-2,laird-stock,OFF,OK@
END
)

# tmp file to save the gateway state
TMPFILE=/tmp/LoRaWanGwMonitor.tmp
LOGFILE=/tmp/LoRaWanGwLog.tmp

# timeout to detect disconnection
TIMEOUT_S=900

#
# as a parameter $1, the TTN gateway id
function checkOneGateway {
  delta=0
  d=`./ttnctl-linux-amd64 gateways status $1 | grep "Last seen" | tr -s " " | cut -d " " -f 4,5,7 | sed "s/^\(.*\)\.\(.*\) \(.*\)$/\1 \3/"`
  if [ -z "$d" ] ; then
   # sometime the date is invalid from the API
   return 2
  fi 

  t=`date --date="${d}" +"%s"`
  now=`date "+%s"`
  delta=`echo "$now - $t" | bc `
  if [ $delta -gt $TIMEOUT_S ] ; then
     return 1
  fi
  return 0
}

#
# Update the gwLastState for the gwId $1 with the new state $2
function changeGatewayStatus {
  gateways=`echo $gateways | sed -e "s/\(^.*$1,[^,]\+,[^,]\+,\)[^@]\+\(@.*$\)/\1$2\2/"`
}

#
# Fire the IFTTT Alert
# Param 1 : gwName
# Param 2 : gwLastState
function fireIFTTT {
   curl -d "{ \"value1\":\"$1\", \"value2\":\"$2\" }" -H "Content-Type: application/json" -X POST https://maker.ifttt.com/trigger/${IFTTT_EVENT}/with/key/${IFTTT_KEY} > /dev/null
}

function main {
  if [ -f $TMPFILE ] ; then
    gateways="`cat $TMPFILE`"
  else
    gateways="$gatewaysConf" 
  fi

  for gw in $(echo $gateways | sed "s/@/ /g"); do
    gwId=`echo $gw | cut -d "," -f 1`
    gwName=`echo $gw | cut -d "," -f 2`
    gwMonitor=`echo $gw | cut -d "," -f 3`
    gwLastState=`echo $gw | cut -d "," -f 4`

    #echo ">> $gwId $gwName $gwMonitor $gwLastState ($gw)"
    if [ $gwMonitor == "ON" ] ; then
      if checkOneGateway $gwId ; then
        if [ $gwLastState == "KO" ] ; then
          changeGatewayStatus $gwId "OK"
 	  echo "Gateway $gwName is back online on `date`">> $LOGFILE
	  fireIFTTT $gwName "online"
        fi
      else
        if [ $? -eq 1 ] ; then 
          if [ $gwLastState == "OK" ] ; then
            changeGatewayStatus $gwId "KO"
	    echo "gateway $gwName has stopped on `date`">> $LOGFILE
	    fireIFTTT $gwName "offline"
          fi
        fi
      fi
    fi
  done 
  echo $gateways > $TMPFILE
}

main
