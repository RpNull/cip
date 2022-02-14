# (Cyber Information Platform)<sup>3</sup>
## Productivity Service Mesh on k8s
![Overview](img/chart.png)
CIP<sup>3</sup> is a multi-node load balanced Kubernetes mesh, utlizing Traefik as an ingress controller and NFS shares for persistent data. 


# Project Documentation

### Dependencies
```
- Ubuntu 20.04.1
- Kubectl   < 1.23.3
- Kubeadm   < 1.23.3
- Kubelet   < 1.23.3
- docker-ce < 1.5-2
- docker    < 1.5-2
- Helm      < 3.8.0-1
- nfs-kernel-server
- nfs-common
```
Install dependencies on all nodes.

### Permissions
Run the following commands as the nonroot user to enable them access to the kube commands. 
```
USER_1K=$(getent passwd 1000 | cut -d':' -f1)
mkdir -p /home/$USER_1K/.kube
sudo cp -i /etc/kubernetes/admin.conf home/$USER_1K/.kube/config
sudo chown $(id -u):$(id -g) /home/$USER_1K/.kube/config
```

### The Docker Daemon
The default configurations for docker will cause the deployment to fail.\
Insert the following values into `/etc/docker/daemon.json`. You may need to create the file if you are doing a fresh install.
```
{
    "exec-opts" : ["native.cgroupdriver=systemd"],
    "metrics-addr" : "0.0.0.0:9293",
    "experimental" : true
} 
```

### ElasticSearch configurations.
ElasticSearch requires memory limitation configuration changes when ran in a virtual enviroment. You will need to repeat this process on each of your nodes.
```
sudo sysctl -w vm.max_map_count=262144
```
Modify `/usr/lib/systemd/system/docker.service`. Change the following line
```
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```
to
```
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock --default-ulimit memlock=-1:-1
```
Restart the service to apply configurations:
```
sudo systemctl daemon-reload
sudo systemctl restart docker.service
```
### SWAP
Kubernetes Clusters are unable to operate on nodes where Swap is enabled. To disable swap, open `/etc/fstab` and comment out any lines starting with /swapfile. Repeat this on all nodes. **This change will require a restart to take affect.**
![swapexample](img/swapfile.png)

### Deploying the Cluster.
With swap disabled, you are able to deploy the cluster. Replace $IP with your master nodes IP. The pod network cidr is the internal network that the cluster will communicate on.
```
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$IP
```
If creation of the cluster fails, follow the error messages and redeploy. You will need to *reset* the kubeadm before you are able to run the init command again.
```
// Only if deployment fails //
sudo kubeadm reset
```
With our cluster officially deployed, we can now apply a networking resource, and the default dashboard for GUI management.
To create the flannel network:
```
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml 
```
To create the dashboard resource:
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
```
We then create the RBAC resources for the dashboard deployment.
```
kubectl apply -f Charts/dashboard/.
```
The dashboard requires a token to access, which you can retrieve with:
```
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```
In a free terminal window, run the command `kubectl proxy`, and then open a browser to the url, entering your token when prompted. *Note, the dashboard may take a few moments to come up, keep refreshing*
```
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
```

### NFS
Create the directory. This directory can be made on any member of the cluster, or even a machine outside of the cluster. 
```
sudo mkdir -p /srv/nfs/kubedata
```
Modify Permissions and ownership
```
sudo chown nobody:nogroup /srv/nfs/kuebdata
sudo chmod 777 /srv/nfs/kubedata
```
Modify `/etc/exports` with the text editor of your choice. Create an entry for each node. Replacing 0.0.0.0 with the IP of the client node.
```
/srv/nfs/kubedata 0.0.0.0((rw,sync,no_subtree_check,no_root_squash))
```
Export the share, and restart the nfs server.
```
sudo exportfs -a
sudo systemctl restart nfs-kernel-server
```
Reload the daemon, and restart the service.
```
sudo systemctl daemon-reload
sudo systemctl restart docker.service
```
**The Following Steps only need to be conducted on the Master Node**\
Install the NFS external provisioner. Replace 'x.x.x.x' with the IP of your NFS server.
```
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path
```
Apply the resources located in `Charts/nfs-charts`\
These resources create the RBAC rules required for the provisioner to allocate persistent volumes on the cluster.
```
kubectl apply -f Charts/nfs-charts/.
```

### Traefik Certs
Traefik will require manual creation of certifications. Replace $DOMAIN in the script below to generate the certificates. $DOMAIN needs to match the 'Hosts' you create in the services `values.yaml` files. The default is just `.local`.
```
mkdir -p $(pwd)/traefik/certs/
echo -e "\e[1;32mCreating self-signed certificate for Traefik\e[0m."
openssl req -newkey rsa:2048 -nodes -keyout /var/data/traefik/certs/cip.key -x509 -sha256 -days 365 -out /var/data/traefik/certs/cip.crt -subj "/C=WK/ST=MOUNTAINS/L=JABARI/O=CIP/OU=SERVICES/CN=*.${DOMAIN}"
```

Create the directory and move the certificates. This should be done on all nodes. *Use the same certificates on all nodes*
```
mkdir -p /var/data/traefik/certs
mkdir -p /var/data/traefik/dynamic
cp $(pwd)/traefik/certs/* /var/data/traefik/certs
cp Configuration_Files/traefik/dynamic/traefik-certs.toml /var/data/traefik/dynamic
```


### Deployment (Helm)

With the cluster prepared, we can now deploy our services. For each service, you will create a package, and then install the package. You may modify values in the services `values.yaml` file to enable or disable functionalities. The following example will deploy traefik.

It is recommended to deploy traefik first, as it will be acting as your ingress controller, and you will not be able to access other services without it.
```
helm package Charts/traefik-charts/
helm install traefik treafik-10.9.1.gz
```
To remove a service:
```
helm uninstall traefik
```


By default all NFS storage sizes are set to 10Gi, for most services this is overkill. You may modify this value in the respective charts `values.yaml` file under 'storage'


### References
[Traefik Documentation](https://doc.traefik.io/traefik/)\
[Kubernetes.io](https://kubernetes.io/docs/home/)\
[Helm Documentation](https://helm.sh/docs/chart_template_guide/)\
[Funky Penguin](https://geek-cookbook.funkypenguin.co.nz/kubernetes/)

### See Also
[CIP Heavy- Docker Swarm](https://github.com/InfinityWatch/cip-heavy)\
[CIP Light- Docker Swarm](https://github.com/InfinityWatch/cip-light)
