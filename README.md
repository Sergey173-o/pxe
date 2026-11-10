

Получить навыки установки и настройки DHCP, TFTP, PXE загрузчика и автоматической загрузки

##  развернуть  сервер

```bash
vagrant validate
PXE_PASSWORD_HASH=$(openssl passwd -6) &&
  export PXE_PASSWORD_HASH &&
  vagrant up pxeserver --provider=virtualbox
unset PXE_PASSWORD_HASH
```

Если провижининг прервался, снова задайте хеш и выполните `vagrant provision pxeserver`. В репозитории хранится шаблон, а сервер отдаёт сгенерированный хеш по HTTP в лабораторной сети.

##  Проверьте DHCP, TFTP и HTTP

```bash
root@nfsc:~/pxe-hw# vagrant ssh pxeserver -c 'systemctl is-active dnsmasq apache2 nftables'
vagrant ssh pxeserver -c 'sudo ss -lun | grep -E ":(67|69)[[:space:]]"'
curl -fsSI http://127.0.0.1:8080/pxe/ubuntu-24.04.5-live-server-amd64.iso
curl -fsSI http://127.0.0.1:8080/pxe/seed/user-data
curl -fsS http://127.0.0.1:8080/pxe/seed/meta-data
active
active
active
UNCONN 0      0                         0.0.0.0%eth1:67        0.0.0.0:*
UNCONN 0      0                            10.0.0.20:69        0.0.0.0:*
UNCONN 0      0      [fe80::a00:27ff:fe8e:ffde]%eth1:69           [::]:*
HTTP/1.1 200 OK
Date: Mon, 09 Nov 2026 18:06:39 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Sun, 08 Nov 2026 19:11:30 GMT
ETag: "f3374800-65fc89cdcc2df"
Accept-Ranges: bytes
Content-Length: 4080486400
Content-Type: application/x-iso9660-image

HTTP/1.1 200 OK
Date: Mon, 09 Nov 2026 18:06:39 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Sun, 08 Nov 2026 19:26:22 GMT
ETag: "210-65fc8d211d2db"
Accept-Ranges: bytes
Content-Length: 528

instance-id: pxe-ubuntu-noble
local-hostname: pxeclient
root@nfsc:~/pxe-hw#

```

Ожидаются три строки `active`, UDP-порты 67 и 69, HTTP 200 для ISO и `user-data`, а также `instance-id` в `meta-data`. Фактическую передачу TFTP проверяйте по журналу во время загрузки клиента.

##  Установите Ubuntu по PXE в режиме BIOS

В одном терминале запустите просмотр журнала:

```bash
root@nfsc:~/pxe-hw# vagrant ssh pxeserver -c 'sudo journalctl -u dnsmasq -f'
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  1 option: 53 message-type  5
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option: 54 server-identifier  10.0.0.20
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option: 51 lease-time  12h
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option: 58 T1  6h
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option: 59 T2  10h30m
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option:  1 netmask  255.255.255.0
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option: 28 broadcast  10.0.0.255
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size: 13 option: 12 hostname  ubuntu-server
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option:  6 dns-server  10.0.0.20
Nov 10 07:56:49 pxeserver dnsmasq-dhcp[753]: 970380675 sent size:  4 option:  3 router  10.0.0.20

```


```bash
vagrant ssh pxeserver -c 'sudo grep -E "GET /pxe/(ubuntu-.*iso|seed/(user-data|meta-data))" /var/log/apache2/access.log'
State                    Recv-Q                    Send-Q                                         Local Address:Port                                         Peer Address:Port                    Process
10.0.2.2 - - [10/Nov/2026:07:58:15 +0000] "HEAD /pxe/ubuntu-24.04.5-live-server-amd64.iso HTTP/1.1" 200 259 "-" "curl/8.5.0"
10.0.2.2 - - [10/Nov/2026:07:58:15 +0000] "HEAD /pxe/seed/user-data HTTP/1.1" 200 204 "-" "curl/8.5.0"
root@nfsc:~/pxe-hw#

root@nfsc:~/pxe-hw# cd ~/pxe-hw
VBoxManage showvminfo pxeclient-bios --machinereadable |
  grep -E '^(VMState|boot1)='
boot1="net"
VMState="running"
root@nfsc:~/pxe-hw# VBoxManage controlvm pxeclient-bios screenshotpng "$PWD/pxeclient-screen.png"
VBoxManage controlvm pxeclient-bios screenshotpng "$PWD/pxeclient-screen1.png"

```


```bash
VMState="poweroff"
root@nfsc:~/pxe-hw# VBoxManage modifyvm pxeclient-bios --boot1 disk --boot2 none --boot3 none --boot4 none &&
VBoxManage startvm pxeclient-bios --type headless
Waiting for VM "pxeclient-bios" to power on...
VM "pxeclient-bios" has been successfully started.
root@nfsc:~/pxe-hw# VBoxManage controlvm pxeclient-bios screenshotpng "$PWD/pxeclient-disk-boot1.png"
root@nfsc:~/pxe-hw# VBoxManage controlvm pxeclient-bios screenshotpng "$PWD/pxeclient-disk-boot2.png"
root@nfsc:~/pxe-hw# VBoxManage controlvm pxeclient-bios screenshotpng "$PWD/pxeclient-disk-boot4.png"
root@nfsc:~/pxe-hw#
```
<img width="1024" height="768" alt="pxeclient-disk-boot1" src="https://github.com/user-attachments/assets/740c2bd0-903e-4d1d-898e-c3f255df7ac1" />
<img width="1024" height="768" alt="pxeclient-screen" src="https://github.com/user-attachments/assets/e7ea8642-8bd8-4fa6-9bb2-278e4f72af3f" />
<img width="1024" height="768" alt="pxeclient-install" src="https://github.com/user-attachments/assets/2af08061-6556-4d82-bdc3-63978f20d3a6" />
<img width="1024" height="768" alt="pxeclient-disk-boot4" src="https://github.com/user-attachments/assets/29a1c552-8981-495b-948a-3c661297b2e1" />
<img width="1024" height="768" alt="pxeclient-disk-boot2" src="https://github.com/user-attachments/assets/6747097c-caa1-4080-89d1-2b262e0ae53c" />


