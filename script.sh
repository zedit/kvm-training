#!/bin/bash

VM_NAME="${1}"
VM_PASSWORD="${2}"
SSH_PUBLIC_KEY="${3}"
IMG_LINK="${4}"

function downloadImg {
   mkdir ${VM_NAME}
   wget -O /var/lib/libvirt/images/${VM_NAME}/${VM_NAME}.img "${1}"
}

function createUserdata {
   local key_file=${2}
   mkdir /tmp/${VM_NAME}
   cp templates/user-data.template /tmp/${VM_NAME}/user-data
   sed -i "s/sed_change_password/${1}/" /tmp/${VM_NAME}/user-data
   PUBLIC_KEY_CONTENT=$(cat ${key_file})
   sed -i "s#sed_change_public_key#${PUBLIC_KEY_CONTENT}#" /tmp/${VM_NAME}/user-data
   mkdir -p /var/lib/libvirt/images/${VM_NAME}
   cloud-localds /var/lib/libvirt/images/${VM_NAME}/user-data.img /tmp/${VM_NAME}/user-data
   rm -rf /tmp/${VM_NAME}/  
}

function creatVm {
   virt-install --virt-type=kvm --name ${VM_NAME} \
                --ram 512 \
                --vcpus=1 \
                --noautoconsole \
                --cdrom=/var/lib/libvirt/images/${VM_NAME}/user-data.img \
                --disk path=/var/lib/libvirt/images/${VM_NAME}/${VM_NAME}.img,format=qcow2
}

downloadImg $IMG_LINK 
createUserdata $VM_PASSWORD $SSH_PUBLIC_KEY
creatVm 
