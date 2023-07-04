# Flux-mikrotik-discord
Monitoring Flux nodes from Mikrotik router and send alerts to Discord (webhook).

The script does the following:
- Ping the NODE IP and sends alert to Discord if node becomes unreachable,
- if ping is successfull it also checks the node tier status via HTTP API. If tier is not either cumulus|stratus|nimbus, it sends alert to Discord.

There are two types of alerts, the DOWN and UP (recovery) alert.

You can use Mikrotik built-in scheduler to run the script in intervals.

## Requirements
- Mikrotik router with RouterOS v6.2+
- Discord Webhook - you can use the one you already use for FLUX nodes or create new one (https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks)

## Usage
- use "**MonitorFLUX.rsc**" to import the script on Mikrotik or create it from the Winbox and paste the script content from "**MonitorFLUX.txt**".
- Edit the script, change the FLUX node details and insert your webhook address.
- create scheduler `add interval=1m name="Monitor FLUX nodes" on-event=/system script run "Monitor FLUX"`

## Screenshots
![image](https://github.com/outlawww/Flux-mikrotik-discord/assets/30106075/eedfd9ca-25b7-4f63-beaf-14d64f93a59f)
![image](https://github.com/outlawww/Flux-mikrotik-discord/assets/30106075/a0253bf0-a315-46a7-b677-a3408aa6b0f8)

