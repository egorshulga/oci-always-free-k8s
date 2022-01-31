# K8s cluster on Oracle Cloud Always Free Infrastructure (with Terraform)

__This repo describes a way for provisioning free resources in the Oracle Cloud for tenancies with an Always Free subscription.__ 

## Getting started

1. Sign up to Oracle Cloud [here](https://www.oracle.com/cloud/free/). 

Choose home region carefully, as it can't be changed in the future, and Always Free tier tenants can't use other regions to provision resources. Prefer regions with multiple availability domains. Check out the list [here](https://docs.oracle.com/en-us/iaas/Content/General/Concepts/regions.htm#:~:text=the%20following%20table%20lists%20the%20regions%20in%20the%20oracle%20cloud%20infrastructure%20commercial%20realm).

2. Download [Terraform CLI](https://www.terraform.io/downloads) and make it available in path. Check terraform is installed with `terraform -v`.

3. Create Oracle API signing key pair. To do this, login to your Oracle Cloud account, and go to _User Settings_ -> _API Keys_. 

![image](https://user-images.githubusercontent.com/6253488/149008215-f176865e-42b7-4d4a-9df9-c29e6339d72e.png)

Then select _Generate API Key Pair_. Download both public and private keys and put it to `.oci` folder in your home dir (e.g. `~/.oci` or `%USERPROFILE%\.oci`). Click _Add_.

![image](https://user-images.githubusercontent.com/6253488/149004376-8c99fdb6-ad1e-463c-a6ac-0baed829a523.png)

Note configuration keys from the displayed snippet. It will be used to configure Terraform `oci` provider.  

To access the configuration snippet later, press 3 dots button next to key's fingerprint -> _View Configuration file_.

![image](https://user-images.githubusercontent.com/6253488/149008591-cde4f631-7990-45a3-8868-3b3c0b9c388f.png)

4. Prepare ssh keypair.

To generate one, go to `.ssh` folder in your home dir (`mkdir -p ~/.ssh && cd ~/.ssh` or `mkdir %USERPROFILE%\.ssh & cd %USERPROFILE%\.ssh`), and then call `ssh-keygen`.

On Windows it's easier to switch to WSL (run `bash` in `.ssh` dir) to generate the key pair.

```
ssh-keygen -t ed25519 -N "" -b 2048 -C ssh-key -f id_ed25519
```

## Cluster setup

1. Clone the repo.

```
git clone https://github.com/egorshulga/oci-always-free-k8s && cd oci-always-free-k8s
```

2. Copy the file `variables.auto.tfvars.example` into `variables.auto.tfvars`. Set correct values for all of the variables (please note backslash in paths should be escaped: `\ -> \\`).

<table>
<thead>
  <tr>
    <th>Variable</th>
    <th>Example</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>region</td>
    <td>uk-london-1</td>
    <td rowspan="4">Taken from Oracle Cloud API Key configuration snippet (see item 3 above).</td>
  </tr>
  <tr>
    <td>tenancy_ocid</td>
    <td>ocid1.tenancy.oc1...</td>
  </tr>
  <tr>
    <td>user_ocid</td>
    <td>ocid1.user.oc1...</td>
  </tr>
  <tr>
    <td>fingerprint</td>
    <td>60:...:c3</td>
  </tr>
  <tr>
    <td>private_key_path</td>
    <td>C:\Users\...\.oci\oci-tf.pem</td>
    <td>Absolute path to Oracle Cloud private key.</td>
  </tr>
  <tr>
    <td>ssh_key_pub_path</td>
    <td>C:\Users\...\.ssh\id_ed25519.pub</td>
    <td>Absolute path to public ssh key. Is used to configure access to created compute instances.</td>
  </tr>
  <tr>
    <td>ssh_key_path</td>
    <td>C:\Users\...\.ssh\id_ed25519</td>
    <td>Absolute path to private ssh key. Is used to bootstrap k8s and other apps on provisioned compute instances.</td>
  </tr>
  <tr>
    <td>cluster_public_dns_name</td>
    <td>cluster.example.com</td>
    <td>Optional. Specifies a dns name, which the cluster will be available on.</td>
  </tr>
  <tr>
    <td>letsencrypt_registration_email</td>
    <td>email@example.com</td>
    <td>Email address, that is used to register in LetsEncrypt (to issue certificates to secure ingress resources, managed by nginx-ingress-controller).</td>
  </tr>
  <tr>
    <td>windows_overwrite_local_kube_config</td>
    <td>false</td>
    <td>Whether local kube config (%USERPROFILE%\.kube\config) should be overwritten with a new one from the newly created cluster.</td>
  </tr>
  <tr>
    <td>debug_create_cluster_admin</td>
    <td>false</td>
    <td>Whether admin should be created in the cluster and its token printed to output (to access dashboard right after cluster creation).</td>
  </tr>
</tbody>
</table>

3. Run Terraform.

```
terraform init
terraform apply
```

Terraform displays a list of changes it is going to apply to resources. Check it carefully, and then answer `yes`.

<details> <summary>Example output</summary>
  
```
> terraform init
Initializing modules...
- compute in compute
- governance in governance
- k8s in k8s
- k8s_scaffold in k8s-scaffold
- network in network
Downloading registry.terraform.io/oracle-terraform-modules/vcn/oci 3.1.0 for network.vcn...
- network.vcn in .terraform\modules\network.vcn
- network.vcn.drg_from_vcn_module in .terraform\modules\network.vcn\modules\drg

Initializing the backend...

Initializing provider plugins...
- Reusing previous version of hashicorp/null from the dependency lock file
- Reusing previous version of hashicorp/oci from the dependency lock file
- Installing hashicorp/null v3.1.0...
- Installed hashicorp/null v3.1.0 (signed by HashiCorp)
- Installing hashicorp/oci v4.57.0...
- Installed hashicorp/oci v4.57.0 (signed by HashiCorp)

Terraform has made some changes to the provider dependency selections recorded
in the .terraform.lock.hcl file. Review those changes and commit them to your
version control system if they represent changes you intended to make.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

> terraform apply

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

(... lots of resources ...)

Plan: 41 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + cluster_public_ip = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: 
```
</details>

## Verify cluster

1. Open output value of `cluster_public_ip` in browser. Nginx should show page 404.

2. If you've set up a public dns name, go to `http://{cluster_public_address}/dashboard`. It should redirect to https and open a k8s dashboard login page. Https connection should be established successfully, browser should show a secure lock icon in address bar, meaning that a certificate is correctly issued by LetsEncrypt.

3. Run `kubectl cluster-info && kubectl get nodes`

<details> <summary>Example output</summary>

  ```
  Kubernetes control plane is running at https://cluster.example.com:6443
  CoreDNS is running at https://cluster.example.com:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

  To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
  NAME       STATUS   ROLES                  AGE   VERSION
  leader     Ready    control-plane,master   25h   v1.23.1
  worker-0   Ready    worker                 25h   v1.23.1
  worker-1   Ready    worker                 25h   v1.23.1
  worker-2   Ready    worker                 25h   v1.23.1
  ```
</details>

4. SSH to the leader instance

<details> <summary>Example output</summary>

```
> ssh ubuntu@{cluster-public-ip}
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-oracle aarch64)
This is a leader instance, which was provisioned by Terraform
ubuntu@leader:~$
```
</details>

5. SSH to worker instances. This can be achieved by connecting to workers via leader instance, which acts as a bastion.

<details> <summary>Example output</summary>

```
> ssh -J ubuntu@{cluster-public-ip} ubuntu@worker-0.private.vcn.oraclevcn.com
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-oracle aarch64)
This is a worker instance, which was provisioned by Terraform
ubuntu@worker-0:~$
```
</details>

## Consumed Oracle Cloud resources

Below you can see a list of Oracle Cloud resources, that are provisioned as a result of applying the scripts. Limits are provided for reference, they are up to date as of January 14, 2022.

Please note that if you already have some resources in your tenancy, then the scripts may fail due to limits imposed by Oracle. You may need to change some resources values (e.g. change count of provisioned workers in [main.tf](main.tf)).

<table>
<thead>
  <tr>
    <th>Module<br>(as in source code)</th>
    <th>Resource</th>
    <th>Used Count</th>
    <th>Service Limit</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td colspan="2">Compartment</td>
    <td>1</td>
    <td>1000</td>
    <td>Separate compartment is created to hold all of the provisioned resources.</td>
  </tr>
  <tr>
    <td rowspan="8">Network</td>
    <td>VCN</td>
    <td>1</td>
    <td>50</td>
    <td>Compute instances are connected to a Virtual Cloud Network.</td>
  </tr>
  <tr>
    <td>Subnet</td>
    <td>1</td>
    <td>300 (per VCN)</td>
    <td>VCN is configured to have a public subnet.</td>
  </tr>
  <tr>
    <td>Network Load Balancer</td>
    <td>1</td>
    <td>3</td>
    <td>Network Load Balancer serves as an entry point for requests coming to the cluster. It works on OSI layers 3/4, and it has no bandwidth configuration requirement. It is connected to a public subnet.</td>
  </tr>
  <tr>
    <td>Reserved Public IP</td>
    <td>1</td>
    <td>1</td>
    <td>Reserved public IP is assigned to a Network Load Balancer.</td>
  </tr>
  <tr>
    <td>Ephemeral Public IP</td>
    <td>4</td>
    <td>1 (per VNIC), 2 (per VM)</td>
    <td>Ephemeral public IPs are assigned to VMs.</td>
  </tr>
  <tr>
    <td>Internet Gateway</td>
    <td>1</td>
    <td>1 (per VCN)</td>
    <td>Internet gateway enables internet connectivity for resources in a public subnet.</td>
  </tr>
  <tr>
    <td>NAT Gateway</td>
    <td>0</td>
    <td>0</td>
    <td>NAT gateway enables outbound internet connectivity for resources in a private subnet. It is not available in Always Free tier (as of January 2022).</td>
  </tr>
  <tr>
    <td>Service Gateway</td>
    <td>0</td>
    <td>0</td>
    <td>Service gateway enables private subnet resources to access Oracle infrastructure (e.g. for metrics collection). It is not available in Always Free tier (as of January 2022).</td>
  </tr>
  <tr>
    <td rowspan="2">Compute</td>
    <td>Cores for Standard.A1 VMs</td>
    <td>4</td>
    <td>4</td>
    <td rowspan="2">Provisioned resources include 4 ARM-based VMs. Each one has 1 OCPU. Leader instance has 2 GB of memory. There are 3 workers, each one has 7 GB of memory.</td>
  </tr>
  <tr>
    <td>Memory for Standard.A1 VMs</td>
    <td>24</td>
    <td>24</td>
  </tr>
</tbody>
</table>

## Network considerations for Always Free tier

As of January 2022 Oracle _does not_ allow creation of NAT and Service gateways in VCNs, which makes private subnets effectively unusable (as without a NAT gateway they cannot access the internet, and without Service gateway Oracle cannot collect metrics from instances).

That is why in the Always Free tier private subnet is not created. Instead, all compute resources are connected to a public subnet. To allow connections to the Internet, they are assigned with ephemeral public IPs.

Load balancer is assigned with a reserved public IP, so all of the traffic is still balanced between workers.

When the account is switched from the Always Free tier to Pay-as-you-go, the limitation is removed, which allows us to provision proper private subnet, and to hide compute instances from being directly accesible from the internet.

## K8s infrastructure

The script provisions a K8s cluster on the leader and worker VMs. Below you can see a list of resources that are available in the K8s cluster once it is provisioned.

<table>
<thead>
  <tr>
    <th>Resource</th>
    <th>Name</th>
    <th>Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Network plugin</td>
    <td>Flannel</td>
    <td></td>
  </tr>
  <tr>
    <td>Ingress controller</td>
    <td><a href="https://kubernetes.github.io/ingress-nginx/" target="_blank" rel="noopener noreferrer">kubernetes/ingress-nginx</a></td>
    <td>Service is deployed via a NodePort (see ports below)</td>
  </tr>
  <tr>
    <td>ClusterIssuer</td>
    <td>LetsEncrypt</td>
    <td>Uses <a href="https://github.com/jetstack/cert-manager" target="_blank" rel="noopener noreferrer">cert-manager</a></td>
  </tr>
  <tr>
    <td>Dashboard</td>
    <td><a href="https://github.com/kubernetes/dashboard" target="_blank" rel="noopener noreferrer">kubernetes/dashboard</a></td>
    <td>Available on https://{cluster-ip}/dashboard/ or https://{cluster-dns-name}/dashboard/ (the latter uses a LetsEncrypt certificate)</td>
  </tr>
</tbody>
</table>

## Cluster connectivity

As all of the compute instances are connected to a private subnet, it required a NAT gateway for outbound internet connections. There are no egress security rules imposed (outgoing connections are allowed to go to `0.0.0.0/0`).

Ingress connectivity is achieved via Network Load Balancer, which is available from the internet via public IP. Below there is a list of open ports. There are no security rules to limit source IPs (incoming connections are allowed to originate from `0.0.0.0/0`).

<table>
<thead>
  <tr>
    <th>Port</th>
    <th>Protocol</th>
    <th>Destination</th>
    <th>Destination port</th>
    <th>Description</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>22</td>
    <td>TCP</td>
    <td rowspan="2">Leader instance</td>
    <td>22</td>
    <td>SSH to leader. Can also be used to connect to worker instances (using the leader as a bastion).</td>
  </tr>
  <tr>
    <td>6443</td>
    <td>TCP</td>
    <td>6443</td>
    <td>Kubectl to K8s control plane (deployed on a leader instance). Kube config is pulled after spinning up the control plane</td>
  </tr>
  <tr>
    <td>80</td>
    <td>TCP</td>
    <td rowspan="2">Workers</td>
    <td>30080</td>
    <td rowspan="2">Forwarding HTTP and HTTPS traffic to NGINX ingress-controller, which is exposed with NodePorts on worker instances. HTTPS offloading is performed by ingress-controller via LetsEncrypt's issued certificate.</td>
  </tr>
  <tr>
    <td>443</td>
    <td>TCP</td>
    <td>30443</td>
  </tr>
</tbody>
</table>


## Troubleshooting

### Out of host capacity

![image](https://user-images.githubusercontent.com/6253488/149601001-cda85054-d43d-4c50-a373-14e1e5343197.png)

This error means that Oracle has run out of free ARM compute resources in selected region.

Possible workaround could be to switch to another availability domain for provisioning compute resources (see [main.tf](main.tf)), or to retry cluster provisioning in some days (as Oracle promises to deploy new capacity over time).

### Invalid NLB state transition: from Updating to Updating

![image](https://user-images.githubusercontent.com/6253488/151791718-263b692e-f89d-420d-8783-a82adb73adcb.png)

That's a tricky error to debug, but my guess is that we create lots of resources under the Network Load Balancer (listeners, backend sets, backends). Oracle Cloud creates it sequentially one-by-one. And it appears that sometimes there could be a race condition happening on the Oracle's side (multiple NLB resources compete to be created), which results in the error.

Workaround for this error is to manually retry `terraform apply` command once again. Terraform will continue resources provisioning from the point where it stopped.
