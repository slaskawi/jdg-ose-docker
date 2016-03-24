#!/bin/bash

IS_OSE_RUNNING=`docker inspect -f {{.State.Running}} origin`

echo "==== Starting OSE ===="
if [ "$IS_OSE_RUNNING" = "true" ] ; then
  echo "OSE is running"
else
  docker rm "origin"
  docker run -d --name "origin" \
        --privileged --pid=host --net=host \
        -v /:/rootfs:ro -v /var/run:/var/run:rw -v /sys:/sys -v /var/lib/docker:/var/lib/docker:rw \
        -v /var/lib/origin/openshift.local.volumes:/var/lib/origin/openshift.local.volumes \
        -v /var/log:/var/log \
        openshift/origin start
fi
        
echo "==== Downloading OSE client ===="
if [ -f ./oc ]; then
  echo "oc client installed"
else
  wget -q -N https://github.com/openshift/origin/releases/download/v1.1.4/openshift-origin-client-tools-v1.1.4-3941102-linux-64bit.tar.gz
  tar -zxf openshift-origin-client-tools-v1.1.4-3941102-linux-64bit.tar.gz
  cp openshift-origin-client-tools-v1.1.4-3941102-linux-64bit/oc .
  rm -rf openshift-origin-client-tools-v1.1.4-3941102-linux-64bit
  rm -rf openshift-origin-client-tools-v1.1.4-3941102-linux-64bit.tar.gz
fi

echo "==== Preparing JDG development environment ===="
./oc login --username='jdg' --password='jdg' https://127.0.0.1:8443
./oc new-project jdg
oc create -n openshift -f jboss-datagrid-image-stream.json

echo "==== Installing JDG templates ===="
for f in ./*.json; do 
  ./oc create -n jdg -f $f
done

echo "==== Adding JDG service accout ===="
./oc policy add-role-to-user view system:serviceaccount:$(./oc project -q):default -n $(./oc project -q)

echo "==== Info ===="
echo "Web Console: https://127.0.0.1:8443/console/"
echo "Login: ./oc --username=jdg --password=jdg"
echo "Standard usage: ./oc <the_rest_of_the_command>"

        
