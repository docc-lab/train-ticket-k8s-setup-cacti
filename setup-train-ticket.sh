
#!/bin/bash

set -x

. "`dirname $0`/setup-lib.sh"

if [ -f $OURDIR/train-ticket-done ]; then
    exit 0
fi

logtstart "train-ticket"

# Variables
REPO_URL="https://github.com/docc-lab/train-ticket.git"
EBS_URL="https://openebs.github.io/charts"
GEN_URL="https://github.com/docc-lab/train-ticket-auto-query.git"

echo "setup trainticket in k8s"

# setup dependencies, including local PVC with helm
sudo helm repo add openebs $EBS_URL
sudo helm repo update
sudo helm install openebs --namespace openebs openebs/openebs --create-namespace

# Clone the repository
cd /local
git clone $REPO_URL

# Setup kubernetes cluster
kubectl label nodes node-1 skywalking=true # Setup dedicated node for skywalking
kubectl taint nodes node-1 dedicated=skywalking:NoSchedule

cd /local/train-ticket/
sudo make deploy DeployArgs="--with-tracing"

# Setup concurrent load generator
cd /local
git clone $GEN_URL
sudo apt install -y golang-go
cd /local/train-ticket-auto-query/tt-concurrent-load-generator
go mod tidy
go build

echo "train-ticket-k8s setup complete"

logtend "train-ticket"

touch $OURDIR/train-ticket-done
exit 0
