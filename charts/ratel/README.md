# Ratel

Ratel is a [SPA](https://wikipedia.org/wiki/Single-page_application) ([single-page-application](https://wikipedia.org/wiki/Single-page_application)) [React](https://react.dev/) client that runs locally from your web browser.  The server component is a small web server that hosts the client application, which is then downloaed into your browser locally. There is no server-to-server connection. 

For best practices, this small web server should be installed in a namespace that is separate from Dgraph server. If your Kubernetes cluster supports the [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) feature, such as [Calico](https://www.tigera.io/project-calico/), you can use these to restrict traffic between the web service hosting Ratel and Dgraph servers.

In order for the Ratel client to connect to the Dgraph Alpha server, you can connect through a tunnel, such as VPN, or connect Dgraph Alpha to an endpoint, such as [service](https://kubernetes.io/docs/concepts/services-networking/service/) of type [LoadBalancer](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer) or use an [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) resource.  See Dgraph helm chart for further information on such configurations.
