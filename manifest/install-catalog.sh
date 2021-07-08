#!/bin/bash

install_dir=$(dirname "$0")
. ${install_dir}/catalog.config
yaml_dir="${install_dir}/yaml"
crd_dir="${yaml_dir}/crds/key-mapping"
ca_dir="${install_dir}/ca"

function set_env(){
    if [[ -z ${imageRegistry} ]]; then
        imageRegistry=quay.io
    else
        imageRegistry=${imageRegistry}
    fi

    if [[ -z ${catalogVersion} ]]; then
        catalogVersion=0.3.0
    else
        catalogVersion=${catalogVersion}
    fi

    sed -i "s|{imageRegistry}|${imageRegistry}|g" ${yaml_dir}/controller-manager-deployment.yaml
    sed -i "s|{catalogVersion}|${catalogVersion}|g" ${yaml_dir}/controller-manager-deployment.yaml
    sed -i "s|{imageRegistry}|${imageRegistry}|g" ${yaml_dir}/webhook-deployment.yaml
    sed -i "s|{catalogVersion}|${catalogVersion}|g" ${yaml_dir}/webhook-deployment.yaml

    openssl genrsa -out rootca.key 2048
    openssl req -x509 -new -nodes -key rootca.key -sha256 -days 3650 -subj /C=KO/ST=None/L=None/O=None/CN=catalog-catalog-webhook -out rootca.crt
    openssl req -new -newkey rsa:2048 -sha256 -nodes -keyout server.key -subj /C=KO/ST=None/L=None/O=None/CN=catalog-catalog-webhook -out server.csr
    openssl x509 -req -in server.csr -CA rootca.crt -CAkey rootca.key -CAcreateserial -out server.crt -days 3650 -sha256 -extfile ./${ca_dir}/v3.ext
    openssl base64 -in rootca.crt > key0
    openssl base64 -in server.crt > cert
    openssl base64 -in server.key > key
    key0=$(awk 'NF {sub(/\r/, ""); printf "%s",$0;}' key0)
    cert=$(awk 'NF {sub(/\r/, ""); printf "%s",$0;}' cert)
    key=$(awk 'NF {sub(/\r/, ""); printf "%s",$0;}' key)
    sed -i "s|{{ b64enc \$ca.Cert }}|${key0}|g" ${yaml_dir}/webhook-register.yaml
    sed -i "s|{{ b64enc \$cert.Cert }}|${cert}|g" ${yaml_dir}/webhook-register.yaml
    sed -i "s|{{ b64enc \$cert.Key }}|${key}|g" ${yaml_dir}/webhook-register.yaml
}

function install_catalog(){
    echo  "========================================================================="
    echo  "=======================  start install catalog  ======================"
    echo  "========================================================================="
    #1. install crd
    kubectl apply -f ${crd_dir}/
    #2. create namespace & serviceaccount
    kubectl create namespace catalog
    kubectl apply -f ${yaml_dir}/serviceaccounts.yaml
    kubectl apply -f ${yaml_dir}/rbac.yaml
    #3. create catalog manager
    kubectl apply -f ${yaml_dir}/controller-manager-deployment.yaml
    kubectl apply -f ${yaml_dir}/controller-manager-service.yaml
    #4. create catalog-webhook
    kubectl apply -f ${yaml_dir}/webhook-register.yaml
    kubectl apply -f ${yaml_dir}/webhook-deployment.yaml
    kubectl apply -f ${yaml_dir}/webhook-service.yaml
    echo  "========================================================================="
    echo  "=======================  complete install catalog  ======================"
    echo  "========================================================================="
}

function uninstall_catalog(){
    echo  "========================================================================="
    echo  "=======================  start uninstall catalog  ======================"
    echo  "========================================================================="
    timeout 1m kubectl delete servicebinding --all --all-namespaces
    timeout 1m kubectl delete serviceinstance --all --all-namespaces
    timeout 1m kubectl delete servicebinding --all --all-namespaces
    timeout 1m kubectl delete clusterservicebroker --all --all-namespaces
    timeout 1m kubectl delete servicebroker --all --all-namespaces
    timeout 1m kubectl delete -f ${yaml_dir}/webhook-service.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/webhook-deployment.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/webhook-register.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/controller-manager-service.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/controller-manager-deployment.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/rbac.yaml
    timeout 1m kubectl delete -f ${yaml_dir}/serviceaccounts.yaml
    timeout 1m kubectl delete namespace catalog
    timeout 1m kubectl delete -f ${crd_dir}/
    echo  "========================================================================="
    echo  "=======================  complete uninstall catalog  ======================"
    echo  "========================================================================="
}

function main(){
    case "${1:-}" in
    install)
        set_env
        install_catalog
        ;;
    uninstall)
        set_env
        uninstall_catalog
        ;;
    *)
        set +x
        echo " service list:" >&2
        echo "  $0 install" >&2
        echo "  $0 uninstall" >&2
        ;;
    esac
}

main $1
