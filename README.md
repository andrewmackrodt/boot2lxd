# boot2lxd

**Disclaimer: experimentation side project, probably not useful in current state**

Goals:
* Create a VM to run Linux Containers (LXD) on Windows, Mac OS and Linux
* Create a boot2lxd Vagrant plugin to use the VM 

Thoughts:
* Create the VM using a small image with required packages
* Provide a Vagrantfile with configurable second disk for LXD
* Configure LXD to work on Virtualbox private subnet
* Configure LXD on initial `vagrant up` as a provisioner?
* Include a DNS server in the VM?

FS considerations:
  * Windows NFS4.1 possible? https://www.cohortfs.com/windows-nfsv41-client-64-bit-0
  * Unison? had trouble with docker-sync
  * CIFS/SSHFS too slow, performance needs to be better than WSL executing `git status`

Similar Projects:
* https://github.com/nodoubleg/vagrant-vboxlxd
