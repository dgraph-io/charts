#!/usr/bin/env bash

# TEST 1
helm template ./charts/dgraph/
# TEST 2
helm template ./charts/dgraph/ \
  --set "alpha.serviceHeadless.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
  | bat -l yaml
# TEST 3
helm template ./charts/dgraph/ \
  --set "zero.serviceHeadless.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
 | bat -l yaml
# TEST 4
helm template ./charts/dgraph/ \
  --set "zero.service.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
  | bat -l yaml
# TEST 5
helm template ./charts/dgraph/ \
  --set "alpha.service.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
  | bat -l yaml
# TEST 6
helm template ./charts/dgraph/ \
  --set "ratel.service.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
  --set "ratel.enabled=true" \
  | bat -l yaml
