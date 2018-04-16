#!/bin/bash

def_link="https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img"
def_img="/home/dmitry/projects/kvm-training/xenial.img"
def_rsa_file="/home/dmitry/.ssh/id_rsa.pub"
VM_NAME="${1}"
SSH_PUBLIC_KEY="${3:-$def_rsa_file}"
IMG_LINK="${2:-$def_link}"
DIR_NAME="/var/lib/libvirt/images/${VM_NAME}"
CHECK_SUM="99e73c2c09cad6a681b2d372c37f2e11"
TEMPLATE_FILE="templates/user-data.template"

function downloadImg {
   if [ ! -e "$DIR_NAME" ]
   then
      mkdir ${DIR_NAME} 
   fi
   if [ -f "${def_img}" ]; then
     cp "${def_img}" ${DIR_NAME}/${VM_NAME}.img
     qemu-img resize ${DIR_NAME}/${VM_NAME}.img +8G
   else
     if [ ! -f "${DIR_NAME}/${VM_NAME}".img ]; then
       wget -O ${DIR_NAME}/${VM_NAME}.img "${1}"
       qemu-img resize ${DIR_NAME}/${VM_NAME}.img +8G
     else 
       local existing_file_check_sum="$(md5sum -b ${DIR_NAME}/${VM_NAME}.img|awk '{print$1}')"
       if [[ "${CHECK_SUM}" != "${existing_file_check_sum}" ]]
       then
         wget -O ${DIR_NAME}/${VM_NAME}.img "${1}"
         qemu-img resize ${DIR_NAME}/${VM_NAME}.img +8G
       fi
     fi
   fi
}

function createUserdata {
   local key_file=${1}
   mkdir /tmp/${VM_NAME}
   cp "${TEMPLATE_FILE}" /tmp/${VM_NAME}/user-data
   PUBLIC_KEY_CONTENT=$(cat ${key_file})
   sed -i "s#sed_change_public_key#${PUBLIC_KEY_CONTENT}#" /tmp/${VM_NAME}/user-data
   sed -i "s#sed_change_hostname#${VM_NAME}#" /tmp/${VM_NAME}/user-data
   cloud-localds ${DIR_NAME}/user-data.img /tmp/${VM_NAME}/user-data
   rm -rf /tmp/${VM_NAME}/  
}

function creatVm {
   virt-install --virt-type=kvm --name ${VM_NAME} \
                --ram 1024 \
                --vcpus=1 \
                --noautoconsole \
                --cdrom=${DIR_NAME}/user-data.img \
                --disk path=${DIR_NAME}/${VM_NAME}.img,format=qcow2
}

downloadImg $IMG_LINK 
createUserdata $SSH_PUBLIC_KEY
creatVm 
