# Istio Gateways

- Run the **istio-gateway-start.sh** script to create cluster whose services are accessible within it but used ingress to make them accessible from outside cluster. It manages and filters out the traffic according to the configuration.

- Kubernetes resources will be installed through helm-chart which creates chart using template engine. These contains all the resources needed to deploy an application in a Kubernetes cluster. These charts could be uploaded to the repositories as well for future use to install.

- Pods will be pulled image through remote docker public repository. https://hub.docker.com/repositories/karan1801

- Hostname will be added **asset-management.com** for the local machine associating minikube's metallb loadbalancer endpoint.

## Egress Gateway
- Istio sidecar proxy will be blocking request to outbound traffic from our cluster's pod to which they are installed. The configuration applied is to block all domains except the given entries to pass through. For our example, *Google* domain is whitelisted.
> ``` kubectl exec -it $(kubectl get pod -l app=asset-management-frontend-pod -o jsonpath='{.items[0].metadata.name}' -n asset) -n asset -it -- curl -I https://www.google.com ```

**This will allowing fetching google requested page and show response headers for it.**

> ``` kubectl exec -it $(kubectl get pod -l app=asset-management-frontend-pod -o jsonpath='{.items[0].metadata.name}' -n asset) -n asset -it -- curl -I https://www.facebook.com ```

**This request to facebook would be cancelled due to connection error as our egress gateway is configured.** 

> curl: (35) OpenSSL SSL_connect: Connection reset by peer in connection to www.facebook.com:443
> command terminated with exit code 35

## Ingress Gateway
- Istio ingress gateway would be accepting requests from the given hosts mentioned in the configuration installed.
> ``` curl -H "Host:asset-management.com" http://asset-management.com/login ``` 

**This will allowing fetching our application page with 200 status code.**

> ``` curl -IH "Host:unknown.com" http://asset-management.com/login ``` 

**This request would be declined as Ingress Gateway needs to know which services to route the incoming requests to based on the specified host.**

> HTTP/1.1 404 Not Found\
> date: Sun, 07 Jan 2024 00:24:29 GMT\
> server: istio-envoy\
> transfer-encoding: chunked

## Rate Limiting

- Istio provides rate-limiting via Envoy to limit network traffic to prevent users from exhausting system resources.

**Global Rate limit Configuration is applied for our entire service mesh. Our /api can be accessed 5 times within one minute which will be refilled/renewed.**

> ``` curl -IH "Host:asset-management.com" http://asset-management.com/api ```

**Results after reaching the limit -**

> HTTP/1.1 429 Too Many Requests\
> x-envoy-ratelimited: true\
> x-ratelimit-limit: 5, 5;w=60 : requests allowed per 60 secs\
> x-ratelimit-remaining: 0 : remaining requests for the given time\
> x-ratelimit-reset: 53 : remaining time for requests refill\
> date: Fri, 26 Jan 2024 01:20:07 GMT\
> server: istio-envoy\
> transfer-encoding: chunked

![Screen Shot 2022-12-23 at 7 46 50 PM](https://user-images.githubusercontent.com/77373766/209420202-7007780a-630e-48d8-9b61-b14faa518eab.png)
