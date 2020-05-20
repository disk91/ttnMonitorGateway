# Monitor a list of TheThingsNetwork gateways and send alert over IFTTT
The purpose of the little bash script is to monitor a group of TheThingsNetwork gateways and report an alarm when one of them is down / up. The trigger is reported over IFTTT webhook so it is easy to get an email, a phone push or a light color changing on a such event with the IFTTT integration.

To use the script, make the configuration, run it with a cron at the desired frequency. The script is using bash with no more depencies than curl and the ttn cli.

## Prerequisites
* You need to download the TTN CLI - [read this post on configuring the CLI client](https://www.disk91.com/2020/technology/lora/monitor-a-gateway-connected-to-the-things-network/)
* You need to create a webhook on IFTTT - [read this post on how to configure an IFTTT webhook](https://www.disk91.com/2019/technology/lora/alarm-your-thethingsnetwork-gateway/)

## Setup
* clone / copy the script into the same directory as the TTN CLI
* make it executable
```bash
chmod +x ./monitor.sh
```
* edit the script and update the parameters:
	- The *IFTTT_KEY* [see the post about IFTTT webhook setup](https://www.disk91.com/2019/technology/lora/alarm-your-thethingsnetwork-gateway/) 
	- The *IFTTT_EVENT* is the name of the IFTTT event like "If Maker Event "XXXXXX", then..."
	- List your gateways to monitor in the *gatewaysConf* 
	- Eventually change the *TIMEOUT_S* in second if your gateway is not stable
* add an entry in crontab
```bash 
*/5  *  *  *  * root    /path/to/the/script/monitor.sh
```
* relaunch the crond deamon

## Change the configuration
If you want to change the list of the monitored gateways, you need to make it in the **monitor.sh** file and you also need to remove the */tmp/LoRaWanGwMonitor.tmp* file.

