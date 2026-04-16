{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "dgraph.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 24 -}}
{{- end -}}
{{/*
Create a default fully qualified app name.
We truncate at 24 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "dgraph.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 24 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 24 -}}
{{- end -}}
{{- end -}}
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "dgraph.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph.zero.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.zero.name }}
{{- end -}}

{{/*
Create a default fully qualified data name.
*/}}
{{- define "dgraph.backups.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.backups.name }}
{{- end -}}

{{/*
Create a semVer/calVer version from image.tag so that it can be safely use in
version comparisions used to toggle features or behavior.
*/}}
{{- define "dgraph.version" -}}
{{- $safeVersion := .Values.image.tag -}}
{{- if (eq $safeVersion "shuri") -}}
  {{- $safeVersion = "v20.07.1" -}}
{{- else if  (regexMatch "^[^v].*" $safeVersion) -}}
  {{- $safeVersion = "v50.0.0" -}}
{{- else -}}
  {{- $safeVersion = regexReplaceAll "-preview.*$" $safeVersion "" -}}
{{- end -}}
{{- printf "%s" $safeVersion -}}
{{- end -}}


{{/*
Return the backups image name
*/}}
{{- define "dgraph.backups.image" -}}
{{- $registryName := .Values.backups.image.registry -}}
{{- $repositoryName := .Values.backups.image.repository -}}
{{- $tag := .Values.backups.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the ratel image name
*/}}
{{- define "dgraph.ratel.image" -}}
{{- $registryName := .Values.ratel.image.registry -}}
{{- $repositoryName := .Values.ratel.image.repository -}}
{{- $tag := .Values.ratel.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}


{{/*
Return empty string if minio keys are not defined
*/}}
{{- define "dgraph.backups.keys.minio.enabled" -}}
{{- $minioEnabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.minio -}}
      {{- if and .Values.backups.keys.minio.access .Values.backups.keys.minio.secret -}}
        {{- $minioEnabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $minioEnabled -}}
{{- end -}}

{{/*
Return empty string if s3 keys are not defined
*/}}
{{- define "dgraph.backups.keys.s3.enabled" -}}
{{- $s3Enabled := "" -}}
{{- $backupsEnabled := or .Values.backups.full.enabled .Values.backups.incremental.enabled }}
{{- if $backupsEnabled -}}
  {{- if .Values.backups.keys -}}
    {{- if .Values.backups.keys.s3 -}}
      {{- if and .Values.backups.keys.s3.access .Values.backups.keys.s3.secret -}}
        {{- $s3Enabled = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- printf "%s" $s3Enabled -}}
{{- end -}}

{{/*
Return the initContainers image name
*/}}
{{- define "dgraph.initContainers.init.image" -}}
{{- $registryName := .Values.alpha.initContainers.init.image.registry -}}
{{- $repositoryName := .Values.alpha.initContainers.init.image.repository -}}
{{- $tag := .Values.alpha.initContainers.init.image.tag | toString -}}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}

{{/*
Return the proper image name (for the metrics image)
*/}}
{{- define "dgraph.image" -}}
{{- $registryName := .Values.image.registry -}}
{{- $repositoryName := .Values.image.repository -}}
{{- $tag := .Values.image.tag | toString -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 doesn't support it, so we need to implement this if-else logic.
Also, we can't use a single if because lazy evaluation is not an option
*/}}
{{- if .Values.global }}
    {{- if .Values.global.imageRegistry }}
        {{- printf "%s/%s:%s" .Values.global.imageRegistry $repositoryName $tag -}}
    {{- else -}}
        {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
    {{- end -}}
{{- else -}}
    {{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- end -}}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "dgraph.imagePullSecrets" -}}
{{/*
Helm 2.11 supports the assignment of a value to a variable defined in a different scope,
but Helm 2.9 and 2.10 doesn't support it, so we need to implement this if-else logic.
Also, we can't use a single if because lazy evaluation is not an option
*/}}
{{- if .Values.global }}
{{- if .Values.global.imagePullSecrets }}
imagePullSecrets:
{{- range .Values.global.imagePullSecrets }}
  - name: {{ . }}
{{- end }}
{{- else if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}
{{- else if .Values.image.pullSecrets }}
imagePullSecrets:
{{- range .Values.image.pullSecrets }}
  - name: {{ . }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified alpha name.
*/}}
{{- define "dgraph.alpha.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.alpha.name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "dgraph.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "dgraph.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified ratel name.
*/}}
{{- define "dgraph.ratel.fullname" -}}
{{ template "dgraph.fullname" . }}-{{ .Values.ratel.name }}
{{- end -}}

{{/*
Build a complete label set as a dict and render via toYaml so that keys
are always sorted alphabetically by Go's YAML marshaler.

Parameters (passed as a dict):
  ctx        — the Helm root context (required)
  component  — value for component / app.kubernetes.io/component (optional)
  extra      — dict of additional chart-defined labels, e.g. monitor or cronjob (optional)
  podLabels  — dict of user-supplied per-component pod labels (optional)

On key conflicts, higher-priority sources override lower-priority ones:
  (lowest)  commonLabels  — from values.yaml, applied to every resource
            podLabels     — from values.yaml, only passed on pod templates
            extra         — chart-defined, only passed by specific templates
            component     — chart-defined, omitted on shared resources like the ServiceAccount
  (highest) standard labels (app, chart, release, heritage, app.kubernetes.io/*)

For example, commonLabels cannot override standard labels like "app" or
"release", and podLabels cannot override chart-defined extra labels.

Not every call passes every parameter. The "extra" parameter is only
used by templates that need additional chart-defined labels:
  - alpha/zero non-headless Services pass extra.monitor (from monitorLabel)
  - alpha/zero headless Services pass extra from serviceHeadless.labels
  - ratel Service passes extra from service.labels
  - backup CronJob pod templates pass extra.cronjob
The "component" parameter is omitted on the shared ServiceAccount and
the pre-upgrade hook resources (which aren't component-specific).

Note on monitorLabel: because "monitor" is only passed as an extra on
the two non-headless Services, setting commonLabels.monitor will add a
"monitor" label to most resources, but those two Services will still
show their chart-defined monitorLabel value instead.
*/}}
{{- define "dgraph.labels" -}}
{{- $ctx := .ctx -}}
{{- $labels := default (dict) $ctx.Values.commonLabels | deepCopy -}}
{{- $labels = merge (default (dict) .podLabels | deepCopy) $labels -}}
{{- range $key, $val := (default (dict) .extra) -}}
{{- $_ := set $labels $key $val -}}
{{- end -}}
{{- if .component -}}
{{- $_ := set $labels "app.kubernetes.io/component" .component -}}
{{- $_ := set $labels "component" .component -}}
{{- end -}}
{{- $_ := set $labels "app" (include "dgraph.name" $ctx) -}}
{{- $_ := set $labels "app.kubernetes.io/instance" $ctx.Release.Name -}}
{{- $_ := set $labels "app.kubernetes.io/managed-by" $ctx.Release.Service -}}
{{- $_ := set $labels "app.kubernetes.io/name" (include "dgraph.name" $ctx) -}}
{{- if $ctx.Chart.AppVersion -}}
{{- $_ := set $labels "app.kubernetes.io/version" $ctx.Chart.AppVersion -}}
{{- end -}}
{{- $_ := set $labels "chart" (include "dgraph.chart" $ctx) -}}
{{- $_ := set $labels "helm.sh/chart" (include "dgraph.chart" $ctx) -}}
{{- $_ := set $labels "heritage" $ctx.Release.Service -}}
{{- $_ := set $labels "release" $ctx.Release.Name -}}
{{- toYaml $labels -}}
{{- end -}}

{{/*
Allow overriding namespace
*/}}
{{- define "dgraph.namespace" -}}
{{- default .Release.Namespace .Values.namespaceOverride -}}
{{- end -}}
