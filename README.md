# K8s cluster on Oracle Cloud Always Free Infrastructure (with Terraform)

## Getting started

1. Sign up to Oracle Cloud [here](https://www.oracle.com/cloud/free/).

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

2. If you've set up a public dns name, go to http://{cluster_public_address}/dashboard. It should redirect to https and open a k8s dashboard login page. Https connection should be established successfully, browser should show a secure lock icon in address bar, certificate should be correctly issued by LetsEncrypt.

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

```
> ssh ubuntu@{cluster-public-ip}
Welcome to Ubuntu 20.04.3 LTS (GNU/Linux 5.11.0-1022-oracle aarch64)
This is a leader instance, which was provisioned by Terraform
ubuntu@leader:~$
```

## Used resources

TODO

## Troubleshooting

TODO

## Contributing

TODO

## License

TODO
