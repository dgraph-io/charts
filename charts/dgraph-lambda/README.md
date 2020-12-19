# dgraph-lambda helm chart

Early pre-release version.  To test this use the following:

```
cd 
git clone https://github.com/dgraph-io/charts
cd charts
git checkout joaquin/lambda
helm install my-release charts/dgraph
helm install my-lambda --values charts/dgraph-lambda/examples/example.yaml charts/dgraph-lambda/ 
```
