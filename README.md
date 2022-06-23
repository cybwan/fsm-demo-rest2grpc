# osm-edge-demo-rest2grpc
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
./scripts/install-osm-cli.sh linux amd64
```
arm64运行
```
./scripts/install-osm-cli.sh linux arm64
```
## 调整环境变量

```
make .env
#调整变量
vi .env
export K8S_INGRESS_NODE=osm-worker   #指定为要部署ingress的node
export CTR_REGISTRY_USERNAME=flomesh #按需设定
export CTR_REGISTRY_PASSWORD=flomesh #按需设定
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

