---
toc: true
toc_label: "Linux 的使用 - firewalld"
toc_icon: "laptop"
title: "Linux 的使用 - firewalld"
tags: linux firewalld 防火墙
categories: "tools"
classes: wide
excerpt: ""
header:
  overlay_image: /assets/images/header/linux.jpg
  overlay_filter: rgba(0, 0, 0, 0.6)
---







## 29.2 firewalld

![image-center](/assets/images/firewalld-structur.png){: .align-center}

从 CentOS 7 开始，默认防火墙成为 `firewalld`，停用原 `iptables` 服务。有人接受，直接使用 firewalld；有人禁用 firewalld，安装 iptables。二者不可同时使用。
{: .notice}

firewalld 是一个可以 **动态管理** 的防火墙，支持网络 “**地带**” （zone）的概念，用于为某个网络及其相关连接、接口、来源分配一个 **信任级别**。firewalld 支持 IPv4、IPv6、以太网桥、IPSet 的设置。

>ipset 是 iptables 的扩展，允许创建匹配整个地址集的规则，它与普通的 iptables 规则链不同，它不是线性存储和过滤，ip 地址被集中存储在带索引的数据结构中，这种结构即使比较大，也能胜任高效的查找。如果有成千上万的地址需要创建规则，在 iptables 中可以直接引用 IPset，无需逐个创建规则。

firewalld 对于运行时和永久配置是分开管理的，同时还提供了接口给服务和软件，允许通过它们增加规则。




### 29.2.1 基本概念

Firewalld 是一个防火墙管理的解决方案，作为 **iptables 的前端** 存在于多个发行版中。



#### firewalld 结构

![image-center](/assets/images/firewalld-structure.png){: .align-center}

firewalld 包含两层：内核层和 D-Bus 层。

内核层负责处理配置，以及后端服务，如 iptables，ip6tables，ebtables，ipset，模块等。

firewalld 的 D-Bus 接口是修改及创建配置的主要途径。该接口被所有 firewalld 的工具使用，如 `firewall-cmd`，`firewallctl`，`firewall-config`，`firewall-applet`。

`firewall-offline-cmd` 不会与 firewalld 对话，而是借助 IO 处理器，直接使用 firewalld 内核来修改和创建配置文件。`firewall-offline-cmd` 虽然可以在 firewalld 运行的时候使用，但不建议这么做，因为经它修改的配置，需要 5 秒钟才能在 firewall 中看到。

firewalld 不依赖 NetworkManager，但仍建议使用。如果没有使用 NetworkManager，会有一些限制：

当有网络设备更名时，firewalld 不会接到通知。如果网络连接建立以后才启动的 firewalld，该连接以及手动创建的接口不会绑定到某个地带，可以使用命令来完成绑定。




#### 地带

ZONE

firewalld 服务按组来管理规则，这些组称为地带。每个地带基本上就是若干组规则，用来规范给哪些流量放行，这些限定是基于 **对所连接的网络的信任程度** 的。可以把网络接口分配给某个地带，来规范防火墙针对该接口的行为。

对于像笔记本这样会经常在不同网络之间切换的，可以通过地带，依据环境的变化，灵活地切换对应的规则。

一个连接、接口、源地址只能同时出现在一个地带，一个地带可包含多个网络连接、接口和源地址。

地带定义了 **该地带中所启用的防火墙功能**。


##### 系统预置的地带

firewalld 内置了几个地带，从不信任到信任：

###### drop

入站包均被丢弃，没有回应，只有可能有出站连接。

###### block

入站包均被拒绝，IPv4 回应 `icmp-host-prohibited` 消息，IPv6 回应 ` icmp6-adm-prohibited` 消息。只允许从本机生成的连接。

###### public

用于公共空间。不信任网络上其他主机，选择性地接受入站连接。

###### external

仅用于启用伪装的外部网络，尤其是路由器。不信任网络上的其他主机，选择性地接受入站连接。

###### dmz

用于可以公开访问的主机，可以有限地访问内部网络，选择性地接受入站连接。

###### work

用于工作场合，信任网络上的大部分主机，选择性地接受入站连接。

###### home

用于家庭环境，信任网络上的大部分主机，选择性地接受入站连接。

###### internal

用于内部网络，信任网络上的大部分主机，选择性地接受入站连接。

###### trusted

信任所有网络连接。



##### 连接、接口、源

可以在地带中绑定 **连接、接口、源地址**。

###### 为连接配置地带

可以在 `ifcfg-*` 文件中保存地带，用 `ZONE=public` 的形式指定。如果没有指定，则使用默认地带。

如果使用 NetworkManager 来管理连接，可以用 `nm-connection-editor` 来修改地带的配置。

###### NetworkManger 管理的网络连接

Linux 内核中的防火墙无力管控 NetworkManager 所涉及的网络连接，它只能管理连接所用的 **网络接口**。
{: .notice--success}

鉴于此，NetworkManager 会通知 firewalld **把网络接口分配给** 该连接配置中设定的 **地带**，而且在使用接口之前就要分配好。

该连接的配置可以是 NetworkManager 的配置文件，也可以是 ifcfg 的配置文件。

如果配置文件中没有配置地带，这些接口会被分配给默认地带。

如果某个连接包含一个以上的接口，所有的接口都要交给 firewalld。

接口的更名也要由 NetworkManager 管理并交予 firewalld。

因此说，这些连接是用来帮助分配地带的。

如果连接丢失，NetworkManager 也会告知 firewalld 从地带中移除连接。

如果 firewalld 被 sytemd 启动或重启，NetworkManager 会得到通知，连接会被分配给相应的地带。

###### 由网络脚本管理的网络连接

对于由网络脚本管理的网络连接，存在着一定的限制：

没有什么守护进程会通知 firewalld 把连接加到地带中去，完全是由 `ifcfg-post` 脚本完成的。因此 ，在这之后如果发生了更名，就无法提交给 firewalld。

同样地，在连接激活的情况下启动或重启 firewalld，也会导致连接与 firewalld 关系的丢失。有一些补救的办法，最简单的是把所有连接堆到默认地带。



##### 地带的使用

###### 该用哪个地带？

比如公共 WIFI 网络连接应该视为不信任，家庭网络连接应该视为信任。

如此，根据信任等级来选择合适的地带。

###### 如何配置地带

要配置或增加地带，可以用以下任意一种 firewalld 的配置接口：

* 图形化配置工具 `firewall-config`
* 命令行工具 `firewall-cmd`
* D-Bus 编程接口，见 `FIREWALLD.DBUS(5)` 帮助文档
* 编辑配置文件，见 `FIREWALLD.ZONE(5)` 帮助文档






#### 运行时配置与永久配置

firewalld 的配置被分为运行时配置与永久配置。

可以把运行时配置理解为动态配置（保存在内存中），永久配置理解为静态配置（保存在磁盘中）。
{: .notice--success}

##### 运行时配置

runtime configuration

运行时配置是实际生效的配置，它被应用到内核的防火墙中。在 firewalld 服务启动时，永久配置成为运行时配置。对运行时配置所做的修改不会自动保存到永久配置中。

firewalld 服务停止时，运行时配置即丢失。重启 friewalld 会用永久配置来覆盖运行时配置，修改过的地带绑定也会被恢复。

##### 永久配置

永久配置保存在配置文件里，在每次主机启动、服务启动、服务重启时，都会成为新的运行时配置。很好理解，每次都要从磁盘读写到内存中。

##### 把运行时配置保存为永久配置

运行时的环境变量也可以用来生成配置文件。

如果修改后的配置能够按预期正常工作，则可以将其保存到配置文件中：

`firewall-cmd --runtime-to-permanet`

如果修改后配置没有达到预期，可以通过重启 firewalld 来回滚之前的配置。




#### 规则的持久性

在 firewalld 中，规则可以是持久的，也可以是临时的。当修改规则时，默认只会影响运行时配置，即 **当前运行** 的防火墙行为。重启后，又会恢复到以前的规则，新规则 **丢失**。

多数的 `firewall-cmd` 操作都可以使用 `--permanet` 标签，即保存到永久配置，修改就会在重启后仍然保留。

这个特点告诉我们，可以在 **运行时** 进行防火墙规则的 **测试**，如果测试失败也没关系，重启即恢复。












### 29.2.2 查看当前规则


#### 默认规则


##### 查看默认地带

查看当前 **默认** 使用的是哪个 **地带**：

```bash
$ firewall-cmd --get-default-zone
public
```


##### 查看启用的地带

初始状态下，当我们没有对防火墙做出修改时，只有一个默认的 **启用的地带**。而且也没有网络接口被绑定到其他地带中，因此 **所有网络接口的流量** 都由这个地带来控制：

```bash
$ firewall-cmd --get-active-zones
public
	interfaces: eth0 eth1
```

可以看到，有两个网络接口受控于默认地带 public，基于默认规则来管理其流量。


##### 查看默认地带的规则

```bash
$ sudo firewall-cmd --list-all
public (default, active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources:
  services: ssh dhcpv6-client
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

可以看到，该地带放行的服务有 ssh 和 dhcpv6。




#### 查看其他地带


##### 查看可用地带

```bash
$ firewall-cmd --get-zones
work drop internal external trusted home dmz public block
```


##### 查看特定地带的规则

查看默认地带规则是 `firewall-cmd --list-all`，要查看特定地带的规则需要用 **`--zone=`** 明确指定地带名称。

```bash
$ sudo firewall-cmd --zone=home --list-all
home
  target: default
  icmp-block-inversion: no
  interfaces:
  sources:
  services: dhcpv6-client mdns samba-client ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  sourceports:
  icmp-blocks:
  rich rules:
```

要想查看所有地带的所有规则，可以用 `sudo firewall-cmd --list-all-zones | less`。












### 29.2.3 为接口选择地带

在防火墙刚刚启用时，**所有接口** 都会被放到 **默认地带** 来管理。




#### 修改接口所处的地带

会话期间，接口可以在不同的地带之间迁移，用 `--zone=` 指定要迁移的地带，`--change-interface=` 指定接口。

```bash
$ sudo firewall-cmd --zone=home --change-interface=eth0
success
```

给接口切换地带时，要注意一下不同地带中放行的服务是否有区别，否则会造成有些服务不可用。
{: .notice--info}

此时再查看一下当前启用的地带，会看到 home 地带也被启用了：

```bash
$ firewall-cmd --get-active-zones
home
  interfaces: eth0
public
  interfaces: eth1
```



#### 调整默认地带

如果所有的网络接口可以用一个地带来管理，则可以选择一个最好的地带，用它来设置。

用 `--set-default-zone=` 来选择默认地带，用该参数运行后，会立即生效，默认地带中的所有接口都会立即切换到新地带中。

```bash
$ sudo firewall-cmd --set-default-zone=home
success
```











### 29.2.4 为程序设置规则




#### 把服务加到地带中

要想为某个服务或端口 **放行**，最简单的办法就是把它们 **加到某个地带**。


##### 查看当前系统可用服务

```bash
$ firewall-cmd --get-services
RH-Satellite-6 amanda-client amanda-k5-client bacula bacula-client ceph ceph-mon dhcp dhcpv6 dhcpv6-client dns docker-registry dropbox-lansync freeipa-ldap freeipa-ldaps freeipa-replication ftp high-availability http https imap imaps ipp ipp-client ipsec iscsi-target kadmin kerberos kpasswd ldap ldaps libvirt libvirt-tls mdns mosh mountd ms-wbt mysql nfs ntp openvpn pmcd pmproxy pmwebapi pmwebapis pop3 pop3s postgresql privoxy proxy-dhcp ptp pulseaudio puppetmaster radius rpc-bind rsyncd samba samba-client sane smtp smtps snmp snmptrap squid ssh synergy syslog syslog-tls telnet tftp tftp-client tinc tor-socks transmission-client vdsm vnc-server wbem-https xmpp-bosh xmpp-client xmpp-local xmpp-server
```

要想了解这些服务的细节，可以查看 `/usr/lib/firewalld/services` 目录中的 `.xml` 文件。


##### 把服务加到地带

使用 `--add-service=` 参数，可以把服务加到地带中。

使用 `--zone=` 指明要加入的地带，不指明则加入默认地带。

使用 `--permanet` 参数可以把改动保存到永久配置，否则只应用于当前的防火墙会话（运行时配置）。

例如，把 HTTP 流量加到 public 地带：

```bash
$ sudo firewall-cmd --zone=public --add-service=http
```

用 `--list-services` 参数来查看修改后的结果：

```bash
$ sudo firewall-cmd --zone=public --list-services
dhcpv6-client http ssh
```


##### 把添加服务保存到永久配置

```bash
sudo firewall-cmd --zone=public --permanent --add-service=http
success
```

要想单独查看永久配置，在查看时也需要加上 `--permanent` 参数：

```bash
sudo firewall-cmd --zone=public --permanet --list-services
dhcpv6-client http ssh
```

这样，public 地带就允许 HTTP 网页流量通过端口 80 了。如果网页服务器使用了 SSL/TLS，则需要把服务 https 添加进去：

```bash
$ sudo firewall-cmd --zone=public --permanent --add-service=https
$ sudo firewall-cmd --zone=public --add-service=https
```




#### 没有合适的服务怎么办？

随 firewalld 安装预置的防火墙服务是通常在系统中最常用到的，很有可能你要使用的程序不在这个列表里。此时你有两个选择：


##### 为地带打开一个端口

为程序打开某个端口，最容易的方法是在合适的地带中打开端口。例如某个程序使用 TCP 5000 端口，可以用 `--add-port=` 参数将其加到 public 地带中：


###### 添加一个端口

```bash
$ sudo firewall-cmd --zone=public --add-port=5000/tcp
success
```

用 `--list-ports` 参数来确认端口已经打开：

```bash
$ sudo firewall-cmd --zone=public --list-ports
5000/tcp
```

###### 添加端口范围

```bash
$ sudo firewall-cmd --zone=public --add-port=4990-4999/udp
```

加到永久配置：

```bash
$ sudo firewall-cmd --zone=public --permanent --add-port=5000/tcp
$ sudo firewall-cmd --zone=public --permanent --add-port=4990-4999/udp
$ sudo firewall-cmd --zone=public --permanent --list-ports
```


##### 新定义一个服务

为某个地带打开端口是很简单的，但要想持续追踪哪个端口是做什么的就比较难了。如果某个服务被撤下来了，要想摸清楚原来打开的端口有哪些还要继续使用，这是个比较麻烦的事儿。要想避免陷入这种情况，我们可以新定义一个服务。

**定义服务** 只需指定其使用的 **端口、名称及描述**。


###### 复制定义文件

最方便的定义服务的办法是在现有的服务上直接修改，另存为一个新服务。

firewalld 预置的服务脚本在 `/usr/lib/firewalld/services` 目录中，均为 `.xml` 文件。可以把这里的文件复制到 `/etc/firewalld/services` 目录中，防火墙会从该目录中查找对非标准服务的定义。

例如，我们可以复制 SSH 服务的定义文件，然后进行修改：

```bash
$ sudo cp /usr/lib/firewalld/services/ssh.xml /etc/firewalld/services/example.xml
$ sudo vi /etc/firewalld/services/example.xml
```

###### 修改文件内容

修改文件中的 <short>、<description>、<port> 标签：

```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Example Service</short>
  <description>This is just an example service.  It probably shouldn't be used on a real system.</description>
  <port protocol="tcp" port="7777"/>
  <port protocol="udp" port="8888"/>
</service>
```

###### 重启防火墙

```bash
$ sudo firewall-cmd --reload
```

查看可用服务：

```bash
$ firewall-cmd --get-services
```

在结果中应该能看到新定义的服务。









### 29.2.5 创建地带

虽然预置的地带对于大多数人来说已经够用了，但如果能够自定义地带，并用它的功能为其命名，使用起来会非常方便。如新建一个地带名为 publicweb，用于控制网页服务器的流量，还可以创建一个地带名为 privateDNS，用于为内部网络提供 DNS 服务。

如果要增加一个地带，必须将其加到永久配置中，之后可以把它加载到运行时会话。



#### 增加地带

```bash
$ sudo firewall-cmd --permanent --new-zone=publicweb
$ sudo firewall-cmd --permanent --new-zone=privateDNS
```

检查是否在永久配置中出现了新的地带：

```bash
$ sudo firewall-cmd --permanent --get-zones
... privateDNS ... publicweb ...
```

但它还不会出现在防火墙的当前实例中：

```bash
$ firewall-cmd --get-zones
...
```



#### 把新地带加入当前配置

通过重启防火墙，来把这些新地带加入当前配置中：

```bash
$ sudo firewall-cmd --reload
$ firewall-cmd --get-zones
... privateDNS ... publicweb ...
```



#### 在新地带中添加服务

如在 publicweb 地带中添加 SSH、HTTP、HTTPS 服务：

```bash
$ sudo firewall-cmd --zone=publicweb --add-service=ssh
$ sudo firewall-cmd --zone=publicweb --add-service=http
$ sudo firewall-cmd --zone=publicweb --add-service=https
$ sudo firewall-cmd --zone=publicweb --list-all
```

在 privateDNS 地带中添加 DNS 服务：

```bash
$ sudo firewall-cmd --zone=privateDNS --add-service=dns
$ sudo firewall-cmd --zone=privateDNS --list-all
```




#### 把接口移到新地带中

```bash
$ sudo firewall-cmd --zone=publicweb --change-interface=eth0
$ sudo firewall-cmd --zone=privateDNS --change-interface=eth1
```



#### 保存到永久配置

在确认添加成功后，如果想把修改保存到永久配置，可以用 `--permanent` 标签把上面的命令再运行一遍：

```bash
sudo firewall-cmd --zone=publicweb --permanent --add-service=ssh
sudo firewall-cmd --zone=publicweb --permanent --add-service=http
sudo firewall-cmd --zone=publicweb --permanent --add-service=https
sudo firewall-cmd --zone=privateDNS --permanent --add-service=dns
```




#### 重启防火墙

保存到永久配置之后，可以重启网络，重启防火墙服务：

```bash
$ sudo systemctl restart network
$ sudo systemctl reload firewalld
```

确认接口是否正确分配：

```bash
$ firewall-cmd --get-active-zones
privateDNS
  interfaces: eth1
publicweb
  interfaces: eth0
```

确认服务是否正确分配：

```bash
$ sudo firewall-cmd --zone=publicweb --list-services
http https ssh

$ sudo firewall-cmd --zone=privateDNS --list-services
dns
```

新地带已经配置成功，如果希望将某一个地带设为默认，以便用其来管理其他接口：

```bash
$ sudo firewall-cmd --set-default-zone=publicweb
```





















### 29.2.6 配置文件




#### `firewalld.conf`

`/etc/firewalld/firewalld.conf`  用于 firewalld 的基础配置。

以下为其默认配置：

##### Default Zone

所有没有明确绑定到其它地带的连接或接口都会被绑定到默认地带。

默认的地带为 `public`

##### Minimal Mark

有些规则在不同的表里都会用到，用来正确处理数据包。这些数据包会用 MARK 参数来标记，后面跟一个标记用的数字。`Minimal Mark` 是用来保留一定范围的 MARK 值自用，只能使用大于该值的数字来做标记。

默认的最小标记数字为 100。

##### CleanupOnExit

如果 firewalld 停止，会清除所有规则。如果本项设定为 `no` 或 `false`，则不会清除。

默认值为 `yes` 或 `true`。

##### Lockdown

程序白名单。

如果开启此选项，通过 D-Bus 接口所做的修改将会限制于这里列出的程序列表，即只有它们才能通过 D-Bus 接口来修改规则。

默认不开启，`no` 或 `false`。

##### IPv6_rpfilter

IPv6 Reverse Path Filter

如果开启，对 IPv6 的数据包会进行反向路径测试，如果测试成功，就会接受该数据包，否则丢弃。

默认开启。

>如果主机开启了返回路径过滤，当接收到数据包时，主机首先会检查数据包的源地址，是否可以通过其传入的接口被测试可到达。如果测试成功，才会接受该数据包。

##### IndividualCalls

对配置所做的修改，如果是以 “单独调用” 的方式来应用的话，每次单独调用都会花费一定的时间，如果修改量较大则会导致应用修改、重启服务会花费过多的时间。如果禁用单独调用，则可以使用合并调用，减少不必要的时间浪费。

默认禁用。

##### LogDenied

为拒绝的行为记录日志，默认为禁用。

##### AutomaticHelpers

为了安全地使用 iptables 和连接跟踪助手程序，建立关闭 AutomaticHelpers。但对于使用 netfilter helpers 的程序可能会有副作用。

可用值为 `yes`，`no`，`system`。

默认为 `system`。




#### 配置文件模板

`/usr/lib/firewalld` 包含 firewalld 内置的默认及回滚配置文件，可以理解为系统模板文件。主要为 `icmptypes`，`services`，`zones` 这三类，内置的这些文件建议不要修改，因为在更新 firewalld 安装包时所有的修改都会丢失。

这些配置文件都是以 xml 文件的形式保存的。



#### 自定义配置文件

用户配置文件保存在 `/etc/firewalld` 目录，命令行生成的配置文件以及用户自建的都会保存在这里。这些文件会覆盖默认配置文件的设置。

要想修改系统预定义的配置，可以从默认配置文件目录中把它们复制到 `/etc/firewalld` 对应的目录中，再进行修改。

如果 `/etc/firewalld` 目录不存在，或其中没有配置文件，firewalld 就会使用默认的配置文件。
