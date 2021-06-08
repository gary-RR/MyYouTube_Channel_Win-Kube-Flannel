#For this demo we'll be installing Kubernetes on two Linux servers: 

ssh Your_User_ID@Your_Designated_Master_IP


##################### Run this on all nodes #######################

#Update the server
sudo apt-get update -y
sudo apt-get upgrade -y

#Install containerd
sudo apt-get install containerd -y

#Configure containerd and start the service
sudo mkdir -p /etc/containerd
sudo su -
containerd config default  /etc/containerd/config.toml
exit

#Next, install Kubernetes. First you need to add the repository's GPG key with the command:
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

#Add the Kubernetes repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

#Install all of the necessary Kubernetes components with the command:
sudo apt-get install kubeadm kubelet kubectl -y

#Modify "sysctl.conf" to allow Linux Node’s iptables to correctly see bridged traffic
sudo nano /etc/sysctl.conf
    #Add this line: net.bridge.bridge-nf-call-iptables = 1

sudo -s
#Allow packets arriving at the node's network interface to be forwaded to pods. 
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
exit

#Enable bridged IPv4 traffic to iptables chains when using Flannel.
sudo sysctl net.bridge.bridge-nf-call-iptables=1

#Reload the configurations with the command:
sudo sysctl --system

#Load overlay and netfilter modules 
sudo modprobe overlay
sudo modprobe br_netfilter

#Add other all nodes to hosts file
    #Add all nodes to hosts file
    #sudo nano /etc/hosts
    
#Disable swap by opening the fstab file for editing 
sudo nano /etc/fstab
    #Comment out "/swap.img"

#Disable swap from comand line also 
sudo swapoff -a

#Pull the necessary containers with the command:
sudo kubeadm config images pull

####### This section must be run only on the Master node#############

sudo kubeadm init --pod-network-cidr=10.244.0.0/16 

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Download Flannel CNI
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml > flannel.yaml
nano flannel.yaml
#If setting this to include Windows worker node(s), do this:
    #Modify the net-conf.json section of the flannel manifest in order to set the VNI 
    #to 4096 and the Port to 4789. It should look as follows:
    net-conf.json: |
    {
      "Network": "10.244.0.0/16",
      "Backend": {
        "Type": "vxlan",
        "VNI": 4096,
        "Port": 4789
      }
    }

#Apply Flannel CNI
kubectl apply -f  ./flannel.yaml 
#To remove flannel: kubectl delete -f flannel.yaml
#If the cluster includes Windows node(s), do this:
curl -L https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/kube-proxy.yml | sed 's/VERSION/v1.21.1/g' | kubectl apply -f -
kubectl apply -f https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/flannel-overlay.yml

#If you are setting up more than one Linux sever, copy teh content of "/.kube" folder to the other server
scp -r $HOME/.kube Your_User_ID@Your_Other_Linux_Node_IP:/home/Your_User_ID

##################### Run this on other nodes #######################
exit

##Do this if you have another Linux node to joint the cluster
ssh Your_User_ID@Your_Other_Linux_Node_IP
    
sudo -i 
    #Paste and the "kubeadm join" command you got when you initiated teh cluster on master. If you can't dind, run this command:
    #kubeadm token create --print-join-command
      
exit

exit

############################################################################Test Cluster#########################################################################
#Get cluster info
kubectl cluster-info

#View nodes (one in our case)
kubectl get nodes

#Untaint maste
#kubectl taint node ubuntu-server1 node-role.kubernetes.io/master-

#Schedule a Kubernetes deployment using a container from Google samples
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0

#View all Kubernetes deployments
kubectl get deployments

#Get pod info
kubectl get pods -o wide

#Create a Kubernetes service to expose our service
kubectl expose deployment hello-world --port=8080 --target-port=8080 --type=NodePort #--type=ClusterIP

#Get all deployments in the current name space
kubectl get services -o wide

  
curl http://ClusterIP:8080

#Test the service using Nodeport
curl   http://Master_IP_Address:NodePort


#Clean up
kubectl delete deployment hello-world
kubectl delete service hello-world
