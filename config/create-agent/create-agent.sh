set -x
#GATEURL=https://oes-gate.payu-new.opsmx.net
#AGENTNAME=payuagent
#NAMESPACE=payu-saas-agent

#Get spinnaker name replaced in json-load
SPINNAME=`curl $GATEURL/oes/accountsConfig/v3/spinnaker/apple/automation | jq '.[0] | .name'`

if [[ $SPINNAME == "null" ]]; then
   echo "Error: Could not get spinnaker name"
   exit 1
fi

# Take standard payload and edit account name and spinnaker name.
# account name is same as agent name
cat  /tmp/initscript/create-agent-request.json| sed s/AGENTNAME/$AGENTNAME/g | jq ".spinnaker=$SPINNAME" > /tmp/tmp-agent-json

# Create the agent
curl -X POST  -H "Content-Type: application/json" -d @/tmp/tmp-agent-json $GATEURL/oes/accountsConfig/v1/agents/apple/automation  -i > /tmp/tmp-create.out
STATUS=`cat /tmp/tmp-create.out | grep HTTP | grep 200 | wc -l`
STATUS=${STATUS// /}
if [[ $STATUS != "1" ]]; then
   echo "Error: Could not create agent"
   cat tmp-create.out
   exit 1
fi

curl  $GATEURL/oes/accountsConfig/v1/agents/$AGENTNAME/manifest/apple/automation > /tmp/$AGENTNAME-manifest.yml
if [[ -s /tmp/$AGENTNAME-manifest.yml ]]; then
   echo "Agent-file creates: $AGENTNAME-manifest.yml"
else
   echo "Error downloading agent manifest"
   exit 1
fi

#Create Service-template
#cat service-manifest-template.yml | sed s/AGENTNAME/$AGENTNAME/g > /tmp/service-manifest-$AGENTNAME.yml
#kubectl apply -n $NAMESPACE -f service-manifest-$AGENTNAME.yml
kubectl apply -n $NAMESPACE -f /tmp/initscript/service-manifest-template.yml

#Create agent
#cat $AGENTNAME-manifest.yml | sed "s/namespace: default/namespace: $NAMESPACE/g" > test-mani.yml
cat /tmp/$AGENTNAME-manifest.yml | sed "s/namespace: default/namespace: $NAMESPACE/g" | kubectl apply -n $NAMESPACE -f  -

