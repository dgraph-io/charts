#!/usr/bin/env bash

# PASS
helm template ./charts/dgraph/

# PASS
helm template ./charts/dgraph/ \
  --set "alpha.serviceHeadless.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
	| bat -l yaml
# 
helm template ./charts/dgraph/ \
  --set "zero.serviceHeadless.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
	| bat -l yaml
# 
helm template ./charts/dgraph/ \
  --set "alpha.service.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
	| bat -l yaml
# 
helm template ./charts/dgraph/ \
  --set "alpha.service.labels.consul\.hashicorp\.com/service-ignore=\"true\"" \
	| bat -l yaml
