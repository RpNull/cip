# Check to see if root level permissions
if [[ $(/usr/bin/id -u) -eq 0 ]]; then
    echo -e "\e[1;31mThis script needs to be ran as the primary user, not root. Please deelevate.\e[0m"
    exit
fi


# Allow nonroot user to manage the cluster
USER_1K=$(getent passwd 1000 | cut -d':' -f1)
mkdir -p /home/$USER_1K/.kube
sudo cp -i /etc/kubernetes/admin.conf home/$USER_1K/.kube/config
sudo chown $(id -u):$(id -g) /home/$USER_1K/.kube/config


# Allow workers to operate on master node
kubectl taint nodes --all node-role.kubernetes.io/master-

# create flannel network
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml 

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
kubectl apply -f ../Charts/dashboard/.

BLOB=kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"

echo "Dashboard created, the following gibberish is your access token. You may access the dashboard by using the command 'kubectl proxy' and browsing to: \n
'http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login' \n\n
$BLOB"




echo "The Cluster has initialized, you may deploy your charts."