{{/*
Shared pod spec for the dgraph validator, used by the `helm test` Pod, the
post-install hook Job, and the suspended manual CronJob. Emits the body of a pod
`spec:` at column 0; each caller includes it with `nindent` for its nesting.

Transport mirrors the ACL bootstrap reconciler: under native TLS
(alpha.tls.enabled) the validator targets the alpha-0 headless FQDN (a cert SAN)
over HTTPS with the chart CA and optional client cert; otherwise it talks
plaintext to the ClusterIP Service.
*/}}
{{- define "dgraph.validation.podSpec" -}}
{{- $nativeTLS := .Values.alpha.tls.enabled -}}
{{- $credsSecret := .Values.alpha.acl.bootstrap.existingSecret | default .Values.alpha.acl.existingSecret | default (printf "%s-acl-secret" (include "dgraph.alpha.fullname" .)) -}}
restartPolicy: Never
{{- include "dgraph.imagePullSecrets" . | nindent 0 }}
{{- if .Values.validation.rbac.enabled }}
serviceAccountName: {{ include "dgraph.alpha.fullname" . }}-validate
{{- else }}
automountServiceAccountToken: false
{{- end }}
{{- $nodeSelector := .Values.validation.nodeSelector | default .Values.alpha.nodeSelector }}
{{- with $nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- $tolerations := .Values.validation.tolerations | default .Values.alpha.tolerations }}
{{- with $tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- if .Values.alpha.securityContext.enabled }}
securityContext:
{{- omit .Values.alpha.securityContext "enabled" | toYaml | nindent 2 }}
{{- end }}
containers:
- name: validate
{{- /* Use the override only when registry, repository, and tag are all set; a
       partial override would render an invalid image reference, so fall back to
       the shared dgraph image instead. */}}
{{- if and .Values.validation.image .Values.validation.image.registry .Values.validation.image.repository .Values.validation.image.tag }}
  image: {{ printf "%s/%s:%s" .Values.validation.image.registry .Values.validation.image.repository (.Values.validation.image.tag | toString) }}
{{- else }}
  image: {{ include "dgraph.image" . }}
{{- end }}
  imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
  command: ["/usr/bin/bash", "/scripts/validate.sh"]
  env:
  - name: ALPHA_HOST
{{- if $nativeTLS }}
    value: {{ printf "%s-0.%s-headless.%s.svc%s" (include "dgraph.alpha.fullname" .) (include "dgraph.alpha.fullname" .) (include "dgraph.namespace" .) (include "dgraph.domainSuffix" .) | quote }}
{{- else }}
    value: {{ include "dgraph.alpha.fullname" . | quote }}
{{- end }}
  - name: EXPECTED_JSON
    value: /config/expected.json
  - name: CREDS_DIR
    value: /creds
  - name: RETRIES
    value: {{ .Values.validation.retries | quote }}
  - name: RETRY_SLEEP
    value: {{ .Values.validation.retrySleep | quote }}
{{- if $nativeTLS }}
  - name: CACERT_PATH
    value: /dgraph/tls/ca.crt
{{- if .Values.alpha.tls.clientName }}
  - name: CLIENT_CERT_PATH
    value: /dgraph/tls/client.{{ .Values.alpha.tls.clientName }}.crt
  - name: CLIENT_KEY_PATH
    value: /dgraph/tls/client.{{ .Values.alpha.tls.clientName }}.key
{{- end }}
{{- end }}
  volumeMounts:
  - name: scripts
    mountPath: /scripts
  - name: config
    mountPath: /config
{{- if .Values.alpha.acl.enabled }}
  - name: creds
    mountPath: /creds
    readOnly: true
{{- end }}
{{- if $nativeTLS }}
  - name: tls-volume
    mountPath: /dgraph/tls
    readOnly: true
{{- end }}
volumes:
- name: scripts
  configMap:
    name: {{ include "dgraph.alpha.fullname" . }}-validate
    defaultMode: 0555
    items:
    - key: validate.sh
      path: validate.sh
- name: config
  secret:
    secretName: {{ include "dgraph.alpha.fullname" . }}-validate
    items:
    - key: expected.json
      path: expected.json
{{- if .Values.alpha.acl.enabled }}
- name: creds
  secret:
    secretName: {{ $credsSecret }}
{{- end }}
{{- if $nativeTLS }}
- name: tls-volume
  secret:
    secretName: {{ include "dgraph.alpha.fullname" . }}-tls-secret
{{- end }}
{{- end -}}
