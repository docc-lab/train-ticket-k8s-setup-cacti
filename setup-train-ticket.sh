
#!/bin/bash

set -x

. "`dirname $0`/setup-lib.sh"

if [ -f $OURDIR/train-ticket-done ]; then
    exit 0
fi

logtstart "train-ticket"

# Variables
REPO_URL="https://github.com/RoyZhang7/train-ticket.git"
EBS_URL="https://openebs.github.io/charts"

echo "setup deathstarbench in k8s"

# setup dependencies, including local PVC with helm
sudo helm repo add openebs $EBS_URL
sudo helm repo update
sudo helm install openebs --namespace openebs openebs/openebs --create-namespace

# Clone the repository
cd /local
git clone --depth=1 $REPO_URL

# Setup kubernetes cluster
sudo su
cd /local/train-ticket/
make deploy

echo "train-ticket-k8s setup complete"

logtend "train-ticket"

touch $OURDIR/train-ticket-done
exit 0
