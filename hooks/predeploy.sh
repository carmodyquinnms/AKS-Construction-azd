#!/bin/bash
source .azure/${AZURE_ENV_NAME}/.env

if ! [ -z "${AZURE_TENANT}" ]; then
   read -p 'Please enter Tenant ID: ' AZURE_TENANT
   TenantList=$(az account tenant list -o tsv|awk '{print $2}')
   if ! x=$(echo "${TenantList}"|grep ${AZURE_TENANT}); then 
      echo -e "Tenant ${AZURE_TENANT} not found in available tenants:\n${TenantList}"; 
      exit 1;
   fi
fi
azd env set AZURE_TENANT ${AZURE_TENANT} 

az acr import --name ${AZURE_CONTAINER_REGISTRY} --source docker.io/bitnami/mongodb:5.0.14-debian-11-r9 \
  --image bitnami/mongodb:5.0.14-debian-11-r9 --force

export MONGODB_ROOT_PASSWORD=mongo
export NAMESPACE=ratingsapp
export MONGODB_URI="mongodb://root:${MONGODB_ROOT_PASSWORD}@ratings-mongodb.ratingsapp.svc.cluster.local"

if ! kubectl get namespaces|grep ${NAMESPACE}; then
   kubectl create namespace ${NAMESPACE}
fi

az keyvault secret set --name mongodburi --vault-name ${AZURE_KEY_VAULT_NAME} --value "${MONGODB_URI}"  --description "mongodb uri"

kubectl apply -n ${NAMESPACE} -f ./src/manifests/mongo/ratings-mongodb-configmap.yaml


