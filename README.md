# SimpleFrame

基于skynet的游戏服务端框架的简单干净的demo。主要是学习的目的,提取了其他github项目对skynet封装的部分,删除了所有逻辑和架构相关的处理。仅保留基础部分。后面再慢慢完善

## 参考项目
https://github.com/dqzg12300/RillServer 
https://github.com/cloudfreexiao/RillServer 
https://github.com/zhanjunxiong/RillServer 

## 目录介绍
* config 策划配置文件
* etc 服务端相关配置
* luaclib c模块的部分
* lualib lua模块,skynet封装部分,最核心的地方
* mod 游戏逻辑模块
* proto 协议文件目录
* service 服务入口
* skynet skynet框架

## 启动方式
* git submodule update --init --recursive
* yum install autoconf``
* ./make.sh all
* 需要先装好protobuf。如碰到警告 No syntax specified for the proto file.这种不用管,是由于例子里面没有syntax="proto2"

## 数据库相关
默认的runconfig配置的db节点的enable是false，则不会加载数据库。如已经装好数据库。可以配置好后设置为true启用。

## protobuf相关错误
如果出现error while loading shared libraries: libprotobuf.so.17: cannot open shared object file: No such file or directory。  
这种情况需要是没有安装protobuf或者是没有加入到环境变量  
可以临时加下export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib  
或者自行加到bash_profile中