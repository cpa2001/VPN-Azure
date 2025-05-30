# VPN-Azure

1. Azure for Student 认证 && 创建 Azure 虚拟机（建议使用学校邮箱注册 Azure 方便学生认证）
   ![image](https://github.com/user-attachments/assets/c8b8599e-0f91-4b89-9a4f-27a79bf1aa23)
2. 创建配置注意点：
  - 可以选择较低配置，这样azure for student最多可以创建三个免费的VM
  - 需要公网IP
  - 此脚本目前在`ubuntu 22.04`上部署，没有测试过其他OS
3. 进入 VM，并git clone 此 repo，或手动复制 `setup_shadowsocks.sh` 的脚本
```shell
touch setup_shadowsocks.sh
chmod +x setup_shadowsocks.sh
code setup_shadowsocks.sh
```
4. 运行 `setup_shadowsocks.sh` 的脚本
```shell
sudo chmod +x setup_shadowsocks.sh
sudo ./setup_shadowsocks.sh
```
5. Azure新建入站规则

   <img width="575" alt="image" src="https://github.com/user-attachments/assets/0c1be5e1-78fa-4326-a817-13c2aa0b6941" />

6. 本地检测是否可以成功连接
```shell
nc -zv <IP> 460
```


旧版手工配置shadowsocks：[Azure搭建服务器.md](https://github.com/cpa2001/VPN-Azure/blob/main/Azure%E6%90%AD%E5%BB%BA%E6%9C%8D%E5%8A%A1%E5%99%A8.md)
