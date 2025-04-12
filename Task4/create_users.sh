#!/bin/bash

user="${1:-test}"

if [[ -d "$user" ]]; then
    echo "Dir for user '$user' already exists" && exit
fi

###

kubectl config use-context minikube
mkdir $user

###

echo "Creating certificates for user '$user'"
key_file=$user/propdev-kube.key
openssl genrsa -out $key_file 2048
echo "Created certificate for user '$user' as '$key_file'"

###

csr_name=$user-csr
group1="${2:-group1}"
group2="${3:-group2}"

echo "Signing certificate for user '$user'"

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $csr_name
spec:
  request: $(openssl req -new -key $key_file -subj "/CN=$user/O=$group1/O=$group2" | base64 | tr -d "\n")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
  - client auth
EOF

echo "Signed certificate for user '$user'"

###

crt_file=$user/propdev-kube.crt
ctx_name=$user-context

kubectl certificate approve $csr_name
kubectl wait --for=jsonpath='{.status.certificate}' csr/$csr_name
kubectl get csr $csr_name -o jsonpath='{.status.certificate}'| base64 -d > $crt_file

echo "Creating context for user '$user'"
kubectl config set-credentials $user --client-key=$key_file --client-certificate=$crt_file --embed-certs=true
kubectl config set-context $ctx_name --cluster=minikube --user=$user
echo "Created context for user '$user'"

echo $user | tee -a .created_users
