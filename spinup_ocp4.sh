#! /bin/bash
./openshift-install create manifests
sed -i 's/true/false/g' manifests/cluster-scheduler-02-config.yml
rm -f bootstrap.ign
./openshift-install create ignition-configs
base64 -w0 worker.ign > worker.64
base64 -w0 master.ign > master.64
git add bootstrap.ign
git commit bootstrap.ign -m "Updating bootstrap.ign file"
git push
ansible-playbook -i inventory playbook.yml
echo "Sleep for 15m to wait"
sleep 15m

export KUBECONFIG=$(pwd)/auth/kubeconfig
until oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
do 
  sleep 10;
done;
oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
oc apply -f htpasswd_csr.yaml
sleep 30
oc adm policy add-cluster-role-to-user cluster-admin osadmin
sleep 30
echo "Yay its done"

