# jul/22/2026 16:58:38 by RouterOS 6.49.18
# software id = QB6E-ZZG6
#
# model = 2011UiAS
# serial number = 77AD07624875
/interface bridge
add name=bridge1
/interface ethernet
set [ find default-name=ether10 ] poe-out=off
set [ find default-name=sfp1 ] disabled=yes
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik
/snmp community
set [ find default=yes ] addresses=0.0.0.0/0 name=netpaltelecom write-access=\
    yes
/interface bridge port
add bridge=bridge1 interface=ether1
add bridge=bridge1 interface=ether2
add bridge=bridge1 interface=ether3
add bridge=bridge1 interface=ether4
add bridge=bridge1 interface=ether5
add bridge=bridge1 interface=ether6
add bridge=bridge1 interface=ether7
add bridge=bridge1 interface=ether8
add bridge=bridge1 interface=ether9
add bridge=bridge1 interface=ether10
/ip address
add address=192.168.116.22/30 interface=bridge1 network=192.168.116.20
/ip route
add distance=1 gateway=192.168.116.21
/ip service
set telnet disabled=yes port=2323
set ftp address=177.93.240.0/21,177.72.104.0/21,1.1.1.0/24 port=2122
set www address=177.72.104.0/27 disabled=yes port=8858
set ssh address=177.93.240.0/21,177.72.104.0/21,1.1.1.0/24,192.168.115.60/30 \
    port=15320
set api address=177.93.240.0/21,177.72.104.0/21 disabled=yes
set winbox address=177.93.240.0/21,177.72.104.0/21,1.1.1.0/24
set api-ssl disabled=yes
/snmp
set contact=noc@netpal.com.br enabled=yes location="Capivari do Sul"
/system clock
set time-zone-autodetect=no time-zone-name=America/Sao_Paulo
/system identity
set name="RB Bridge Servidores"
/system ntp client
set enabled=yes primary-ntp=192.168.116.10 secondary-ntp=192.168.116.10
/system scheduler
add interval=1w name=backup_ftp on-event="/system script run backup_ftp" \
    policy=ftp,reboot,read,write,policy,test,password,sniff,sensitive \
    start-date=dec/17/2019 start-time=12:00:00
/system script
add dont-require-permissions=yes name=backup_ftp owner=jdf policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":l\
    og warning \"***************************************\"\r\
    \n# Conexao FTP\r\
    \n:global host 177.72.104.131\r\
    \n:global usuario mkbkp\r\
    \n:global senha mkbkp123\r\
    \n# Pega o nome do Router\r\
    \n:global identifica [/system identity get name ];\r\
    \n:global diretorio /Mikrotik\r\
    \n# Gera data no formato AAAA-MM-DD\r\
    \n:global data [/system clock get date]\r\
    \n:global meses (\"jan\",\"feb\",\"mar\",\"apr\",\"may\",\"jun\",\"jul\",\"\
    aug\",\"sep\",\"oct\",\"nov\",\"dec\");\r\
    \n:global ano ([:pick \$data 7 11])\r\
    \n:global mestxt ([:pick \$data 0 3])\r\
    \n:global mm ([ :find \$meses \$mestxt -1 ] + 1);\r\
    \n:if (\$mm < 10) do={ :set mm (\"0\" . \$mm); }\r\
    \n:global mes ([:pick \$ds 7 11] . \$mm . [:pick \$ds 4 6])\r\
    \n:global dia ([:pick \$data 4 6])\r\
    \n:log info \"Gerando backup: \$identifica-\$ano-\$mes-\$dia.backup\";\r\
    \n/system backup save name=\"\$identifica-\$ano-\$mes-\$dia\";\r\
    \n:log info \"Gerando export: \$identifica-\$ano-\$mes-\$dia.rsc\";\r\
    \n/export file=\"\$identifica-\$ano-\$mes-\$dia\"\r\
    \n:log info \"Processando...\";\r\
    \n:delay 5s\r\
    \n:log info \"Conectando FTP Server...\";\r\
    \n:log info \"Enviando Backup [\$identifica-\$ano-\$mes-\$dia.backup] ...\"\
    ;\r\
    \n/tool fetch address=\$host src-path=\"\$identifica-\$ano-\$mes-\$dia.back\
    up\" user=\"\$usuario\" password=\"\$senha\" port=21 upload=yes mode=ftp ds\
    t-path=\"\$diretorio/\$identifica-\$ano-\$mes-\$dia.backup\"\r\
    \n:log info \"Enviando Export [\$identifica-\$ano-\$mes-\$dia.rsc] ...\";\r\
    \n/tool fetch address=\$host src-path=\"\$identifica-\$ano-\$mes-\$dia.rsc\
    \" user=\"\$usuario\" password=\"\$senha\" port=21 upload=yes mode=ftp dst-\
    path=\"\$diretorio/\$identifica-\$ano-\$mes-\$dia.rsc\"\r\
    \n:delay 1\r\
    \n:log info \"Backup enviado com sucesso...\";\r\
    \n:log info \"Removendo arquivos .backup\";\r\
    \n:foreach i in=[/file find] do={:if ([:typeof [:find [/file get \$i name] \
    \".backup\"]]!=\"nil\") do={/file remove \$i}}\r\
    \n:log info \"Removendo arquivos .rsc\";\r\
    \n:foreach i in=[/file find] do={:if ([:typeof [:find [/file get \$i name] \
    \".rsc\"]]!=\"nil\") do={/file remove \$i}}\r\
    \n:log info \"Rotina de backup finalizada...\";\r\
    \n:log warning \"***************************************\";"
