# Packer VMWare Stemcell Builder

This repo contains an automated process for creating a windows stemcell using the vmware-iso builder and the [vsphere builder](https://github.com/jetbrains-infra/packer-builder-vsphere) from jetbrains.

# Workflow

Packer currently requires a guest IP Hack in order to connect to ESXi directly. This is not a viable option in an enterprise environment so this repo attempts to simplify the process of building a windows vm by breaking it into two phases. 

## Phase 1 - ISO to VMX

In the first phase, the "iso to vmx" template takes the iso from the windows evaluation center and turns it into a vmware virtual machine using a local vmware workstation. 

Due to the time it takes to run windows updates, it is recommended doing this process only once to get the initial windows vm. Once the windows VM is created, uploading it to vcenter is the next step. This is taken care of with a Provisioner in the template. 

The following templates build the VMX and upload it to VCenter:

| name                       | os version                       |
|----------------------------|----------------------------------|
|[eval-win2016-standard-iso-to-vmx.json](eval-win2016-standard-iso-to-vmx.json)|windows server 2016 standard eval |

## Phase 2 - VMX to stemcell

Once the VMX has been created and is uploaded to vcenter, it is ready for the second phase to run. In this phase we will be snapshotting the existing windows VM to make a stemcell VM. 

# Submodules

This git repo is dependent on the [boxcutter/windows](https://github.com/boxcutter/windows) repository for many of the automation scripts. In specific circumstances, files have been copied from the submodule and modified in this repo. Ideally all dependencies will update based on feedback from issues and pull requests, though this is not always the case.