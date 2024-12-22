# VPN-Azure

1. 创建或者git clone `setup_shadowsocks.sh` 的脚本
```shell
touch setup_shadowsocks.sh
chmod +x setup_shadowsocks.sh
code setup_shadowsocks.sh
```
2. 运行 `setup_shadowsocks.sh` 的脚本
```shell
sudo chmod +x setup_shadowsocks.sh
sudo ./setup_shadowsocks.sh
```
3. Azure新建入站规则

   <img width="575" alt="image" src="https://github.com/user-attachments/assets/0c1be5e1-78fa-4326-a817-13c2aa0b6941" />

5. 本地检测是否可以成功连接
```shell
nc -zv <IP> 460
```


旧版手工配置shadowsocks：[Azure搭建服务器.md](https://github.com/cpa2001/VPN-Azure/blob/main/Azure%E6%90%AD%E5%BB%BA%E6%9C%8D%E5%8A%A1%E5%99%A8.md)
