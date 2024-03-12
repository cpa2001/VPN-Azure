使用Azure可以搭建连接Openai的服务器，地区选择丰富，包括美国、欧洲、日本、非洲等，我人在香港，因此选择离得最近的可以使用ChatGPT的日本搭建我的VPN服务器。

整体搭建过程非常简单，需要最基本的Linux基础和简单Python基础，大概耗时20-30分钟。

**注意：**
PPTPD和Shadowsocks是两种不同的VPN技术，它们的设置和参数是不同的。如果服务器设置的是PPTPD，那么不应在Shadowsocks客户端中配置它。反之亦然，如果使用的是Shadowsocks服务，那么应该在Shadowsocks客户端中配置，而不是PPTPD的设置。需要确定服务器是运行PPTPD还是Shadowsocks，并使用相应的客户端和配置参数。

**以下为配置shadowsocks的全部步骤：**

# **1. 生成Azure虚拟机**

## 1.1 浏览器搜索azure student，可以注册学生账户

## 1.2 登录自己的账户，在里面选择新建虚拟机，配置如下，选择学生免费的B1s服务器即可，需要公共IP地址！


# 2. **配置服务器环境**

## 2.1 更新系统软件包列表

```Plain
sudo apt update
```

## 2.2 安装Conda环境

```C++
conda create -n ssenv python && conda activate ssenv
```

## 2.3 安装Shadowsocks服务器

```Plain
sudo apt install shadowsocks
```

此处如果报错：

```Plain
vpn@Azure-Servive:~$ sudo apt install shadowsocks
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
No apt package "shadowsocks", but there is a snap with that name.
Try "snap install shadowsocks"
E: Unable to locate package shadowsocks
```

更换同名Snap包：

```Plain
sudo snap install shadowsocks
```

## 2.4 创建Shadowsocks的配置文件

```
pip install shadowsocks
```

通常是`/etc/shadowsocks.json`

```Plain
sudo vi /etc/shadowsocks.json
```

配置以下内容：

```Plain
{
    "server":"0.0.0.0",
    "server_port":460,
    "local_address": "127.0.0.1",
    "local_port":1080,
    "password":"your_password",
    "timeout":300,
    "method":"aes-256-cfb",
    "fast_open": false,
    "workers": 1
}
```

- **`"server"`**: 服务器的IP地址。
- **`"server_port"`**: 希望Shadowsocks监听的端口。
- **`"password"`**: 设置的密码。
- **`"method"`**: 加密方法，例如**`"aes-256-cfb"`**。

服务器看不到自己的公网IP，所以这里使用`0.0.0.0`作为`server`字段的值，这样服务器就会监听所有可用接口

## 2.5 启动Shadowsocks服务

```Plain
sudo ssserver -c /etc/shadowsocks.json -d start
```

运行成功显示正常运行并开始监听：

```C++
root@Azure-Servive:/etc# ssserver -c /etc/shadowsocks.json
INFO: loading config from /etc/shadowsocks.json
2024-01-11 05:49:52 INFO     loading libcrypto from libcrypto.so.3
2024-01-11 05:49:52 INFO     starting server at 0.0.0.0:460
```

**如果此处报错：**

```C++
vpn@Azure-Servive:~$ sudo ssserver -c /etc/shadowsocks.json -d start
Traceback (most recent call last):
  File "/usr/local/bin/ssserver", line 5, in <module>
    from shadowsocks.server import main
  File "/usr/local/lib/python3.10/dist-packages/shadowsocks/server.py", line 27, in <module>
    from shadowsocks import shell, daemon, eventloop, tcprelay, udprelay, \
  File "/usr/local/lib/python3.10/dist-packages/shadowsocks/udprelay.py", line 71, in <module>
    from shadowsocks import encrypt, eventloop, lru_cache, common, shell
  File "/usr/local/lib/python3.10/dist-packages/shadowsocks/lru_cache.py", line 34, in <module>
    class LRUCache(collections.MutableMapping):
AttributeError: module 'collections' has no attribute 'MutableMapping'
```

这个问题是由于Python 3.10中的`collections`模块发生了变化导致的。`MutableMapping`现在已经移到了`collections.abc`中。

**解决方法：**

修改shadowsocks代码中的导入语句，从`collections.abc`导入`MutableMapping`。

**配置完成：**

```C++
(ssenv) vpn@Azure-Servive:~$ sudo ssserver -c /etc/shadowsocks.json -d start
INFO: loading config from /etc/shadowsocks.json
2024-01-11 05:21:11 INFO     loading libcrypto from libcrypto.so.3
started
```

## 2.6 检查服务状态

```C++
sudo systemctl status shadowsocks
```

查看Shadowsocks服务是否正在运行。

**运行成功显示：**

```C++
root@Azure-Servive:/etc# sudo systemctl start shadowsocks

● shadowsocks.service - Shadowsocks
     Loaded: loaded (/etc/systemd/system/shadowsocks.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-01-11 05:46:44 UTC; 49ms ago
   Main PID: 34868 (ssserver)
      Tasks: 1 (limit: 1055)
     Memory: 2.9M
        CPU: 19ms
     CGroup: /system.slice/shadowsocks.service
             └─34868 /usr/bin/python3 /usr/local/bin/ssserver -c /etc/shadowsocks.json

Jan 11 05:46:44 Azure-Ubuntu-VPN systemd[1]: Started Shadowsocks.
```

**如果此处报错：**

```C++
(ssenv) vpn@Azure-Servive:~$ sudo systemctl status shadowsocks
Unit shadowsocks.service could not be found.
```

需要手动创建一个systemd服务文件来管理Shadowsocks服务

### 2.6.1 创建一个systemd服务文件来管理Shadowsocks服务

1. 创建一个新的systemd服务文件`/etc/systemd/system/shadowsocks.service`。
2. 在该文件中添加以下内容（根据环境适当修改路径和用户）：

```TOML
[Unit]
Description=Shadowsocks

[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

3. 重新载入systemd的配置文件：

```Plaintext
sudo systemctl daemon-reload
```

4. 启动Shadowsocks服务：

```SQL
sudo systemctl start shadowsocks
```

**此时如果报错，需要检查sssever路径：**

```C++
(ssenv) vpn@Azure-Servive:~$ sudo systemctl status shadowsocks
× shadowsocks.service - Shadowsocks
     Loaded: loaded (/etc/systemd/system/shadowsocks.service; enabled; vendor preset: enabled)
     Active: failed (Result: exit-code) since Thu 2024-01-11 05:32:16 UTC; 12s ago
   Main PID: 34295 (code=exited, status=203/EXEC)
        CPU: 817us

Jan 11 05:32:16 Azure-Ubuntu-VPN systemd[1]: shadowsocks.service: Scheduled restart job, restart counter is at 5.
Jan 11 05:32:16 Azure-Ubuntu-VPN systemd[1]: Stopped Shadowsocks.
Jan 11 05:32:16 Azure-Ubuntu-VPN systemd[1]: shadowsocks.service: Start request repeated too quickly.
Jan 11 05:32:16 Azure-Ubuntu-VPN systemd[1]: shadowsocks.service: Failed with result 'exit-code'.
Jan 11 05:32:16 Azure-Ubuntu-VPN systemd[1]: Failed to start Shadowsocks.
Jan 11 05:32:19 Azure-Ubuntu-VPN systemd[1]: /etc/systemd/system/shadowsocks.service:7: Special user nobody configured, this is not safe!
ChatGPT
```

### 2.6.2 检查sssever路径

1. 确定`ssserver`的确切路径，可以使用`which`命令或者查找特定路径。如果Shadowsocks是通过snap安装的，它的可执行文件通常位于`/snap/bin/`目录下。尝试以下命令：

```Bash
which ssserver
```

我的输出：

```C++
root@Azure-Servive:/snap/shadowsocks/current/bin# which ssserver
/usr/local/bin/ssserver
```

2. 在systemd服务文件中设置`ExecStart`

3. 编辑`shadowsocks.service`文件：

```Bash
sudo vi /etc/systemd/system/shadowsocks.service
```

4. 将`ExecStart`行修改为以下内容：

```TOML
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json
```

5. 保存并退出编辑器。

6. 重新加载systemd以识别对服务文件所做的更改：

```Bash
sudo systemctl daemon-reload
```

7. 尝试再次启动服务：

```Bash
sudo systemctl start shadowsocks
```

8. 检查服务状态看是否正常运行：

```Bash
sudo systemctl status shadowsocks
```

现在显示：

```C++
root@Azure-Servive:/etc# sudo vi /etc/systemd/system/shadowsocks.service
root@Azure-Servive:/etc# sudo systemctl daemon-reload
sudo systemctl start shadowsocks
sudo systemctl status shadowsocks
● shadowsocks.service - Shadowsocks
     Loaded: loaded (/etc/systemd/system/shadowsocks.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-01-11 05:46:44 UTC; 49ms ago
   Main PID: 34868 (ssserver)
      Tasks: 1 (limit: 1055)
     Memory: 2.9M
        CPU: 19ms
     CGroup: /system.slice/shadowsocks.service
             └─34868 /usr/bin/python3 /usr/local/bin/ssserver -c /etc/shadowsocks.json

Jan 11 05:46:44 Azure-Ubuntu-VPN systemd[1]: Started Shadowsocks.
```

服务器配置成功

## 2.7 实现Shadowsocks在后台运行、开机启动和自动启动:

1. 后台运行：使用 `-d start` 参数在后台启动 Shadowsocks：

```Bash
ssserver -c /etc/shadowsocks.json -d start
```

2. 检查Systemd服务（同步骤2.6.1）

创建或检查是否存在一个名为 `shadowsocks.service` 的文件于 `/etc/systemd/system/` 目录，用于控制Shadowsocks服务。文件内容应包括以下：

```TOML
[Unit]
Description=Shadowsocks

[Service]
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

3. 启用服务：启用并启动Systemd服务，以确保在开机时自动启动Shadowsocks：

```Bash
sudo systemctl enable shadowsocks
sudo systemctl start shadowsocks
```

4. 检查服务状态：确认服务是否正常运行：

```Bash
sudo systemctl status shadowsocks
```

**运行成功显示：**

```C++
root@Azure-Servive:/etc# sudo systemctl start shadowsocks

● shadowsocks.service - Shadowsocks
     Loaded: loaded (/etc/systemd/system/shadowsocks.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-01-11 05:46:44 UTC; 49ms ago
   Main PID: 34868 (ssserver)
      Tasks: 1 (limit: 1055)
     Memory: 2.9M
        CPU: 19ms
     CGroup: /system.slice/shadowsocks.service
             └─34868 /usr/bin/python3 /usr/local/bin/ssserver -c /etc/shadowsocks.json

Jan 11 05:46:44 Azure-Ubuntu-VPN systemd[1]: Started Shadowsocks.
```

# 3. 配置本地客户端


- 服务器: 使用服务器的公网IP地址。
- 端口: 使用在服务器配置的端口号，“460”。
- 加密方式: 选择与服务器配置文件中一致的加密方法，“aes-256-cfb”。
- 密码: 输入在服务器配置文件中设置的密码。
- 备注: 这是配置标识，可以自定义。
- 协议: 如果只是使用Shadowsocks而不是ShadowsocksR(SSR)，则通常选择“origin”。
- 混淆: 同上，如果是Shadowsocks，通常选择“plain”。

## **Reference**

**PPTPD（本文不适用，这是另一套方案）：**

[PPTPD搭建VPN服务器](https://superonesfazai.github.io/articles/2016/12/09/(Linux)%E5%9C%A8Ubuntu%E4%B8%8B%E6%90%AD%E5%BB%BAVPN%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E6%96%B9%E6%B3%95.html#:~:text=%28Linux%29%E5%9C%A8Ubuntu%E4%B8%8B%E6%90%AD%E5%BB%BAVPN%E6%9C%8D%E5%8A%A1%E5%99%A8%E7%9A%84%E6%96%B9%E6%B3%95%201%20%E7%94%A8root%E8%B4%A6%E6%88%B7%E7%99%BB%E9%99%86%E6%9C%8D%E5%8A%A1%E5%99%A8%202%20%E5%AE%89%E8%A3%85PPTPD%20apt-get%20install%20pptpd,-j%20MASQUERADE%20...%208%20%E9%87%8D%E6%96%B0%E5%90%AF%E5%8A%A8%E6%9C%8D%E5%8A%A1%20%2Fetc%2Finit.d%2Fpptpd%20restart%20%E6%9B%B4%E5%A4%9A%E9%A1%B9%E7%9B%AE)

