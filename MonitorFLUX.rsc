/system script
add dont-require-permissions=no name="Monitor FLUX" owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    FLUX NODES data\r\
    \n:local fluxNames {\"FLUX-1\";\"FLUX-2\";\"FLUX-3\"};\r\
    \n:local fluxIP {\"192.168.111.10\";\"192.168.111.11\";\"192.168.111.12\"}\
    ;\r\
    \n:local fluxPort {16127;16137;16147};\r\
    \n\r\
    \n#Discord Webhook URL\r\
    \n:local discordhook \"https://discord.com/api/webhooks/......\"
    \r\
    \n\r\
    \n#Variables\r\
    \n:local httpdata \"\";\r\
    \n:global fluxNodeStatus;\r\
    \n:if ([:typeof \$fluxNodeStatus] = \"nothing\") do={\r\
    \n\t:global fluxNodeStatus ({});\r\
    \n}\r\
    \n:global fluxTierStatus;\r\
    \n:if ([:typeof \$fluxTierStatus] = \"nothing\") do={\r\
    \n\t:global fluxTierStatus ({});\r\
    \n}\r\
    \n\r\
    \n#Function for sending alerts\r\
    \n:local sendAlert do={\r\
    \n\t:local httpdata \"\";\r\
    \n\t# Open JSON series\r\
    \n\t:set httpdata (\$httpdata.\"{\\\"username\\\": \\\"Mikrotik Watchdog\\\
    \",\\\"avatar_url\\\": \\\"https://cdn.shopify.com/s/files/1/0653/8759/395\
    3/files/512.png\?v=1657867177\\\",\\\"content\\\": \\\"FLUX node alert\\\"\
    ,\");\r\
    \n\t#add to JSON series\r\
    \n\t:set httpdata (\$httpdata.\"\\\"embeds\\\": [{ \\\"title\\\": \\\":lou\
    dspeaker: \".\$alertTitle.\"\\\",\\\"description\\\": \\\"\".\$datetime.\"\
    \\\",\\\"color\\\": \".\$alertColor.\",\\\"fields\\\": [{\\\"name\\\": \\\
    \"Name\\\",\\\"value\\\": \\\"\".\$node.\"\\\"},{\\\"name\\\": \\\"IP\\\",\
    \\\"value\\\": \\\"\".\$ip.\"\\\"},{\\\"name\\\": \\\"Description\\\",\\\"\
    value\\\": \\\"\".\$alertDescription.\"\\\"}]}]}\");\r\
    \n\t#send alert\r\
    \n    /tool fetch keep-result=no mode=https http-method=post http-header-f\
    ield=\"Content-Type:application/json\" http-data=\$httpdata url=\$url;\r\
    \n}\r\
    \n\r\
    \n#check FLUX nodes availability\r\
    \n:foreach index,node in=\$fluxNames do={\r\
    \n\t:local datetime ([/system clock get date].\" \".[/system clock get tim\
    e]);\r\
    \n\t:local ip (\$fluxIP->\$index);\r\
    \n\t:local pings ([/ping count=5 \$ip interval=1s])\r\
    \n\r\
    \n\t:if (\$pings = 0) do={\r\
    \n\t#The Node is DOWN (no ping response)\r\
    \n\t\r\
    \n\t\t#check if went from UP -> DOWN send alert\r\
    \n\t\t:if ((\$fluxNodeStatus->\$index) != \"DOWN\") do={\r\
    \n\t\t\t:set (\$fluxNodeStatus->\$index) \"DOWN\";\r\
    \n\t\t\t\$sendAlert ip=\$ip node=\$node url=\$discordhook datetime=\$datet\
    ime alertTitle=\"Flux Node is DOWN (PING)\" alertColor=16453151 alertDescr\
    iption=\"NO ping response from the node.\";\r\
    \n\t\t\t\t\r\
    \n\t\t#Else just set to DOWN just in case \$fluxNodeStatus was not defined\
    \_yet\r\
    \n\t\t} else={\r\
    \n\t\t\t:set (\$fluxNodeStatus->\$index) \"DOWN\";\r\
    \n\t\t}\r\
    \n\r\
    \n\t} else={\r\
    \n\t#The Node is UP\r\
    \n\r\
    \n\t\t#check if went DOWN -> UP and send alert\r\
    \n\t\t:if ((\$fluxNodeStatus->\$index) != \"UP\") do={\r\
    \n\t\t\t:set (\$fluxNodeStatus->\$index) \"UP\"\t\r\
    \n\t\t\t\$sendAlert ip=\$ip node=\$node url=\$discordhook datetime=\$datet\
    ime alertTitle=\"Flux Node is back UP (PING)\" alertColor=3198567 alertDes\
    cription=\"Got ping response from the node.\";\r\
    \n\t\t\t\r\
    \n\t\t#Else just set to UP just in case \$fluxNodeStatus was not defined y\
    et\r\
    \n\t\t} else={\r\
    \n\t\t\t:set (\$fluxNodeStatus->\$index) \"UP\";\r\
    \n\t\t}\r\
    \n\t\r\
    \n\t\t# Next check if Flux OS is responding and node tier is valid\r\
    \n\t\t:local port (\$fluxPort->\$index);\r\
    \n\t\t:local fetchNodeStatus;\r\
    \n\t\t:local nodeTier;\r\
    \n\t\t:do { :set fetchNodeStatus [/tool fetch url=\"http://\$ip:\$port/flu\
    x/nodetier\" output=user as-value]; } on-error={ :set fetchNodeStatus \"HT\
    TP connection failed\"};\r\
    \n\t\t:if (\$fetchNodeStatus=\"HTTP connection failed\") do={\r\
    \n\t\t\t:set nodeTier \$fetchNodeStatus;\r\
    \n\t\t} else={\r\
    \n\t\t\t:set nodeTier [:pick (\$fetchNodeStatus->\"data\") ([:find (\$fetc\
    hNodeStatus->\"data\") \"data\"]+7) ([:find (\$fetchNodeStatus->\"data\") \
    \"}\"]-1)]\r\
    \n\t\t}\r\
    \n\t\r\
    \n\t\t:if (([:find \$nodeTier \"cumulus\"] >= 0) || ([:find \$nodeTier \"n\
    imbus\"] >= 0) || ([:find \$nodeTier \"stratus\"] >= 0)) do={\r\
    \n\t\t#The Flux OS is UP (node tier is valid)\r\
    \n\t\t\r\
    \n\t\t\t#check if went from DOWN -> UP and send alert\r\
    \n\t\t\t:if ((\$fluxTierStatus->\$index) != \"UP\") do={\r\
    \n\t\t\t\t:set (\$fluxTierStatus->\$index) \"UP\"\t\t\r\
    \n\t\t\t\t\$sendAlert ip=\$ip node=\$node url=\$discordhook datetime=\$dat\
    etime alertTitle=\"Flux Node is back UP (API)\" alertColor=3198567 alertDe\
    scription=(\"Node tier status: \".\$nodeTier);\r\
    \n\t\t\t\t\r\
    \n\t\t\t#Else just set to UP just in case \$fluxTierStatus was not defined\
    \_yet\r\
    \n\t\t\t} else={\r\
    \n\t\t\t\t:set (\$fluxTierStatus->\$index) \"UP\";\r\
    \n\t\t\t}\r\
    \n\t\t\r\
    \n\t\t} else={\r\
    \n\t\t#The FluxOS is DOWN (node tier not valid)\r\
    \n\t\t\r\
    \n\t\t\t#check if went from UP -> DOWN and send alert\r\
    \n\t\t\t:if ((\$fluxTierStatus->\$index) != \"DOWN\") do={\r\
    \n\t\t\t\t:set (\$fluxTierStatus->\$index) \"DOWN\"\r\
    \n\t\t\t\t\$sendAlert ip=\$ip node=\$node url=\$discordhook datetime=\$dat\
    etime alertTitle=\"Flux Node is DOWN (API)\" alertColor=16453151 alertDesc\
    ription=(\"Node tier status: \".\$nodeTier);\r\
    \n\t\t\t\t\r\
    \n\t\t\t#Else just set to UP just in case \$fluxTierStatus was not defined\
    \_yet\r\
    \n\t\t\t} else={\r\
    \n\t\t\t\t:set (\$fluxTierStatus->\$index) \"DOWN\";\r\
    \n\t\t\t}\t\t\r\
    \n\t\t}\r\
    \n\t}\r\
    \n}"
