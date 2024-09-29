# TrainTicket K8S profile usage

## A. Use the profile to create an experiment.

The cloudlab profile is called [train-ticket-k8s](https://www.cloudlab.us/p/Tracing-Pythia/train-ticket-k8s). 
We only debugged for `with-tracing` make flag for cloudlab k8s setup. If you want to use other component that tt provides, feel free to fork and edit. It would be great if you can PR it back.

After getting email saying setup complete, train-ticket might take extra 15 mins to get ready for all pods. Check `kubectl get pods` till all pods is ready.

## B. (Optional) Build and use your own docker images from src

TODO

## C. Check TrainTicket Web UI

1. Setup port forwarding for TrainTicket dashboard UI

    Note that all IPs in k8s cluster are not accessible from outside as CloudLab only provides a few public IPs per experiment.
    You can either use graphic ssh OR, as we recommend, setup port forwarding from k8s controler node to your local as the following (don't forget to replace placeholder): 

    ```bash
    ssh  -L 12345:localhost:12345 -i <PATH_TO_YOUR_KEY> <YOUR_CLOUDLAB_USERID>@<HOST_FOR_NODE_0> 'kubectl port-forward service/ts-ui-dashboard 12345:8080'
    ```
    If you want to use different port in your local or in k8s controller node, check manual of `kubectl port-forward` and `ssh -L` for details.

    Then you'll be able to see TrainTicket frontend UI by visiting `http://localhost:12345/` with browser in your local.

2. Explore features based on [trainticket team's user guide](https://github.com/FudanSELab/train-ticket/wiki/User-Guide)


## D. Check SkyWalking Trace

1. Via SkyWalking web UI with port forwarding

    ```bash
    ssh  -L 54321:localhost:54321 -i <PATH_TO_YOUR_KEY> <YOUR_CLOUDLAB_USERID>@<HOST_FOR_NODE_0> 'kubectl port-forward service/skywalking-ui 54321:8080'
    ```

    Then you'll be able to see SkyWalking web UI by visiting `http://localhost:54321/` with browser in your local. Traces are under the `trace` tab on the top.
    Note that, (1) skywalking collects all db connections --> you would see a lot of db.close() trace; and (2) skywalking UI displays all spans in traces separately as standlone items in the query list on the left, so it could be annoying to find a different traces since the list is flooded by spans of same trace.

2. Via GraphQL api
    There is an excluisve api in Java spring tracing infra called GraphQL. Basically, you can send query statements in HTTP request to fetch specific info. In our case, we query for trace.
    You follow the format as the following, and we also provide a concrete example:
    ```bash
    # GraphQL format
    curl -X POST -H "Content-Type: application/json" -d '{
        "query": "YOUR_QUERY_HERE",
        "variables": {
            "traceId": "your-trace-id",
            "condition": {
            // Your condition parameters here
            }
        }
    }' http://YOUR_SW_IP:12800/graphql

    # concrete example
    curl -X POST -H "Content-Type: application/json" -d '{
        "query": "query queryTrace($traceId: ID!) { queryTrace(traceId: $traceId) { spans { traceId segmentId spanId parentSpanId serviceCode startTime endTime endpointName type peer component isError layer } } }",
        "variables": {
            "traceId": "b5be1efa2f4442c8b69f7ea21fff092c.121.17273687553310021"
        }
    }' http://192.168.241.22:12800/graphql

    ```

3. Via REST api
    Theoretically, Skywalking should be compatible with REST api that is defined in both OTel spec and [in Skywalking's own api documentation](https://skywalking.apache.org/docs/main/next/en/debugging/query-tracing/), like:
    ```bash
    http://{core restHost}:{core restPort}/debugging/query/queryBasicTraces?{parameters}
    ```
    But it seems not works in our deployment, though. So, use the GraphQL method in D.2 instead.

## E. Run workload generator

We implemented a concurrent version of [train-ticket's auto-query load generater](https://github.com/FudanSELab/train-ticket-auto-query) in golang, see [github](https://github.com/docc-lab/train-ticket-auto-query.git) for more details. It's integrated into this cloudlab profile already, so you can just execute the binary with different arguments described below.

 1. Find IP address of trainticket ui services

     ```bash
     kubectl get services | grep ts-ui-dashboard
     ```

 2. Use concurrent load generator. 
    It takes three parameters---IP address of tt-ui-dashboard, # threads you want, # scenarios per thread. So, the # total scenarios = # threads * # scenarios per thread, and each of scenario consists of several consequntial requests (starting from a login request --> query request --> different followup requests)

     ```bash
     cd /local/train-ticket-auto-query/tt-concurrent-load-generator
     ./tt-concurrent-load-generator <TRAIN_TICKET_UI_IPADDR> <NUM_THREAD> <NUM_SCENARIOS_PER_THREAD>
     ```

 3. Check load generator logs & results
TODO