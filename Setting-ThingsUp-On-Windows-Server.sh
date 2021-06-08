#Run this on a Kubernetes node to get cert and token to join a node.
kubeadm token create --print-join-command

#ssh administrator@10.0.0.182
######################################################################Docker#####################################################################################################
ssh administrator@10.0.0.184

Install-WindowsFeature -Name containers
Restart-Computer -Force

Install-Module DockerMsftProvider -Force
	#Uninstall-Package Docker -ProviderName DockerMsftProvider

Install-Package Docker -ProviderName DockerMsftProvider -Force  
    #-RequiredVersion 19.03.14
	#UnInstall-Package Docker

Restart-Computer -Force

Set-Service -Name docker -StartupType 'Automatic'
	

curl.exe -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/PrepareNode.ps1
#** Modify PrepareNode.ps1 and replace "mcr.microsoft.com/oss/kubernetes/pause:1.4.1" with "mcr.microsoft.com/oss/kubernetes/pause:3.4.1".
((Get-Content -path PrepareNode.ps1 -Raw) -replace 'mcr.microsoft.com/oss/kubernetes/pause:1.4.1','mcr.microsoft.com/oss/kubernetes/pause:3.4.1') | Set-Content -Path PrepareNode.ps1

.\PrepareNode.ps1 -KubernetesVersion v1.21.1 
#v1.19.0 #v1.20.0 #v1.21.1

#Join the cluster:
kubeadm join 10.0.0.149:6443 --token t5cp6n.4qkhcsrei04h9h82 --discovery-token-ca-cert-hash sha256:db974d3a68a9a0562cd6c6af9a72e830c3ce42e12aacfb249f1b2cd2146be61f

#Install kubectl
curl https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe -O kubectl.exe
cp .\kubectl.exe C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps

#Deploy a sample container 
kubectl apply -f .\win-sample.yaml

#Check the pod
kubectl get pods -o wide 

#Verify the service
kubectl get services


#Test app, Note: Must specify one of Linux nodes IP address
curl http://10.0.0.149:32276 -UseBasicParsing


#Confirm second Windows worker node is up  
kubectl get nodes -o wide

#Scale the POD to 2
kubectl scale --replicas=4 deployment/win-sample

#Check the pod
kubectl get pods -o wide











kubectl -n kube-system get pods -l app=flannel -o wide




docker run mcr.microsoft.com/windows/servercore:2004
########################################################################################################################################################

#######################################################################ContainerD######################################################################################


#Set nested virtulaization on VM itself to true. Must run this on Hyper-V host when the VM is shut down.
set-vmprocessor -vmname WIN-ContD-Dell -ExposeVirtualizationExtensions $true


#Downlaod "crictl-v1.21.0-windows-386.tar.gz" from:
https://github.com/kubernetes-sigs/cri-tools/releases
#It is downlaoded here:
C:\temp

#"C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps" is on the Windows path.
scp c:\temp\crictl.exe administrator@10.0.0.141:C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps

#**Must install containers, Hyper-V, and Hyper-V Powershell Modules

#Install Windows containers
Install-WindowsFeature -Name containers
Restart-Computer -Force

#Install Hyper-v
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
Restart-Computer -Force

#Install Hyper-v module
Install-WindowsFeature -Name Hyper-V-PowerShell

curl.exe -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/Install-Containerd.ps1 
.\Install-Containerd.ps1 v1.4.4
	#Done - please remember to add '--cri-socket "npipe:////./pipe/containerd-containerd"' to your kubeadm join command

curl.exe -LO https://github.com/kubernetes-sigs/sig-windows-tools/releases/latest/download/PrepareNode.ps1
.\PrepareNode.ps1 -KubernetesVersion v1.21.1 -ContainerRuntime containerD
 	WARNING: The names of some imported commands from the module 'hns' include unapproved verbs that might make them less discoverable. To find the commands with unapproved verbs, run the
	Import-Module command again with the Verbose parameter. For a list of approved verbs, type Get-Verb.

kubeadm join 10.0.0.139:6443 --cri-socket "npipe:////./pipe/containerd-containerd" --token kcnemm.lgs1a4dg1tdxuthn --discovery-token-ca-cert-hash sha256:f9da8d97a7cba15844d6375830ccce16e922d7364e67a765acae8cd2f73811b0
###################################################################################################################

################################################Installing kubectl#################################################
curl https://dl.k8s.io/release/v1.21.0/bin/windows/amd64/kubectl.exe -O kubectl.exe
cp .\kubectl.exe C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps

#Copy .kube folder. It automatically creates ".kube" folder
scp -r ~/.kube administrator@10.0.0.177:/Users/Administrator/.kube
###################################################################################################################


Get-EventLog -LogName System -EntryType Error
Clear-EventLog "System"

#Enable LinuxKit system for running Linux containers
[Environment]::SetEnvironmentVariable("LCOW_SUPPORTED", "1", "Machine")

#Restart Docker Service after the change.
Restart-Service docker

#Pull a test docker image.
docker run -it --rm ubuntu /bin/bash