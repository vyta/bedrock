#!/bin/sh
while getopts :f:g:h:k: option
do
 case "${option}" in
 f) ARGOCD_REPO_URL=${OPTARG};;
 h) ARGOCONFIG_REPO_URL=${OPTARG};;
 g) GITOPS_SSH_URL=${OPTARG};; 
 k) GITOPS_SSH_KEY=${OPTARG};;
 esac
done

KUBE_SECRET_NAME="argo-ssh" 
ARGOCD_NAMESPACE="argocd"
REPO_DIR="argocd"
CONFIG_DIR="argoConfig"

rm -rf $REPO_DIR
echo "Cloning ARGOCD $ARGOCD_REPO_URL"
if ! git clone $ARGOCD_REPO_URL $REPO_DIR; then
    echo "ERROR: failed to clone $ARGOCD_REPO_URL"
    exit 1
fi

rm -rf $CONFIG_DIR
echo "Cloning ARGOCD $ARGOCCONFIG_REPO_URL"
if ! git clone $ARGOCONFIG_REPO_URL $CONFIG_DIR; then
    echo "ERROR: failed to clone $ARGOCONFIG_REPO_URL"
    exit 1
fi

cd $REPO_DIR/argo-cd/master/manifests/ha/

re="^(https|git)(:\/\/|@)([^\/:]+)[\/:]([^\/:]+)\/(.+).git$"
if [[ $GITOPS_SSH_URL =~ $re ]]; then
    user=${BASH_REMATCH[4]}
    repo=${BASH_REMATCH[5]}

    # ARGOCD does not include a helm chart, replace the config repo with 
    # gitops url
    if ! sed -i -e "s|<your config repo>|$user/$repo|g" ./ARGOCD-rc.yaml; then
        echo "ERROR: failed to update with gitops url $GITOPS_SSH_URL"
        exit 1
    fi

    if ! sed -i -e "s|<location in your repo of yaml files>||g" ./ARGOCD-rc.yaml; then
        echo "ERROR: failed to update location in your repo of yaml files"
        exit 1
    fi

    if ! sed -i -e "s|- /data/repo/|- /data/repo/ --namespace default|g" ./ARGOCD-rc.yaml; then
        echo "ERROR: failed to add namespace arg for ARGOCD"
        exit 1
    fi
fi

echo "Updated with gitops url $GITOPS_SSH_URL"
sed '23q;d' ./ARGOCD-rc.yaml

cd ../../ 

echo "creating kubernetes namespace $ARGOCD_NAMESPACE if needed"
if ! kubectl describe namespace $ARGOCD_NAMESPACE > /dev/null 2>&1; then  
    if ! kubectl create namespace $ARGOCD_NAMESPACE; then  
        echo "ERROR: failed to create kubernetes namespace $ARGOCD_NAMESPACE"  
        exit 1  
    fi   
fi

echo "creating kubernetes secret $KUBE_SECRET_NAME from key file path $GITOPS_SSH_KEY"

if kubectl get secret $KUBE_SECRET_NAME -n $ARGOCD_NAMESPACE > /dev/null 2>&1; then
    # kubectl doesn't provide a native way to patch a secret using --from-file.
    # The update path requires loading the secret, base64 encoding it, and then
    # making a call to the 'kubectl patch secret' command.
    if [ ! -f $GITOPS_SSH_KEY ]; then
        echo "ERROR: unable to load GITOPS_SSH_KEY: $GITOPS_SSH_KEY"
        exit 1
    fi

    secret=$(cat $GITOPS_SSH_KEY | base64)
    if ! kubectl patch secret $KUBE_SECRET_NAME -n $ARGOCD_NAMESPACE -p="{\"data\":{\"identity\": \"$secret\"}}"; then
        echo "ERROR: failed to patch existing flux secret: $KUBE_SECRET_NAME "
        exit 1
    fi
else
    if ! kubectl create secret generic $KUBE_SECRET_NAME --from-file=identity=$GITOPS_SSH_KEY -n $ARGOCD_NAMESPACE; then
        echo "ERROR: failed to create secret: $KUBE_SECRET_NAME"
        exit 1
    fi
fi

echo "Applying ARGOCD deployment"
if ! kubectl create -f  $REPO_DIR/argo-cd/master/manifests/ha/install.yaml -n $ARGOCD_NAMESPACE; then
    echo "ERROR: failed to apply ARGOCD deployment"
    exit 1
fi

cd 

echo "ARGOCD deployment complete"
