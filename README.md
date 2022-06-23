# osm-edge-demo-rest2grpc
## 运行环境要求

- OS: **Ubuntu 20.04**
- ARCH: **arm64/amd64**
- K8s tools: **kubectl、helm**

可参考 [cybwan/scripts](https://github.com/cybwan/scripts) 部署k8s-tools

## 下载demo工程

```
git clone https://github.com/cybwan/osm-edge-demo-rest2grpc.git
cd osm-edge-demo-rest2grpc
```
## 安装osm edge cli

```
make install-osm-cli
```
或
amd64运行

```
./scripts/install-osm-cli.sh amd64 linux
```
arm64运行
```
./scripts/install-osm-cli.sh arm64 linux
```
或者 [Release v1.1.0 · flomesh-io/osm-edge](https://github.com/flomesh-io/osm-edge/releases/tag/v1.1.0)手动下载安装

## 调整环境变量

```
make .env
#调整变量
vi .env
export K8S_INGRESS_NODE=osm-worker   #指定为要部署ingress的node
export CTR_REGISTRY_USERNAME=flomesh #按需设定
export CTR_REGISTRY_PASSWORD=flomesh #按需设定
```

如果本地没有k8s环境，执行下面指令启动kind集群:

```
make kind-up
```

## demo部署

```
./demo/run-osm-demo.sh
```

## 打开client端口转发

```
./scripts/port-forward-rest2grpc-client.sh
```

## 打开ingress端口转发

```
./scripts/port-forward-rest2grpc-ingress-pipy.sh
```

## 测试 

127.0.0.1调整为ingress所在node的ip

### ingress <=> client

```
curl http://127.0.0.1:80/client-only
curl http://127.0.0.1:80/client-only?name=tom
```

### ingress <=> client <=> server

```
curl http://127.0.0.1:80/client-server
curl http://127.0.0.1:80/client-server?name=tom
```

## 日志

### client 业务容器日志

```
./demo/tail-rest2grpc-client.sh
```

### client sidecar容器日志

```
./demo/tail-rest2grpc-client-sidecar.sh
```

### server 业务容器日志

```
./demo/tail-rest2grpc-server.sh
```

### server sidecar容器日志

```
./demo/tail-rest2grpc-server-sidecar.sh
```

## 卸载

```
./demo/clean-kubernetes.sh
```

