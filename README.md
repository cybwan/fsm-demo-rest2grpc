# osm-edge-demo-rest2grpc
## 运行环境要求

#
- OS: **Ubuntu 20.04**
- ARCH: **arm64/amd64**
- K8s tools: **kubectl、helm**
- 下载工具: **axel**

安装 k8s-tools：

参考 [cybwan/scripts](https://github.com/cybwan/scripts)

## 下载demo工程

```
git clone https://github.com/cybwan/osm-edge-demo-rest2grpc.git
cd osm-edge-demo-rest2grpc
```
## 安装osm edge cli

```
make bin/osm
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

**注意:**

部署脚本会对K8S_INGRESS_NODE环境变量所指定的node打ingress-ready=true标签，查看当前的node节点：

```
kubectl get nodes
```

如果本地没有k8s环境，执行下面指令部署&启动kind集群:

```
make kind-up
```

## demo部署

```
make demo-up
```

## 测试 

### 开放PIPY INGRESS对外访问

```
make demo-forward
```

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

## 开放PIPY REPO对外访问

```
./scripts/port-forward-osm-repo.sh
```

127.0.0.1调整为osm edge controller所在node的ip

```
http://127.0.0.1:6060
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
make demo-reset
```

