{{/*
Expand the name of the chart.
*/}}
{{- define "terraria.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "terraria.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "terraria.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "terraria.labels" -}}
helm.sh/chart: {{ include "terraria.chart" . }}
{{ include "terraria.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "terraria.selectorLabels" -}}
app.kubernetes.io/name: {{ include "terraria.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "terraria.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "terraria.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "terraria.worldsize" -}}
{{- with .Values.world.size }}
{{- if eq . "small" }}1
{{- else if eq . "medium" }}2
{{- else if eq . "large" }}3
{{- else }}{{ fail (printf "world.size '%s' is invalid, must be one of: small, medium, large" .) }}
{{- end }}
{{- end }}
{{- end }}

{{- define "terraria.difficulty" -}}
{{- with .Values.world.difficulty }}
{{- if eq . "classic" }}0
{{- else if eq . "expert" }}1
{{- else if eq . "master" }}2
{{- else if eq . "journey" }}3
{{- else }}{{ fail (printf "world.difficulty '%s' is invalid, must be one of: classic, expert, master, journey" .) }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Tools image and pull policy.
*/}}
{{- define "terraria.toolsImage" -}}
image: {{ tpl .Values.image.tools.repository . }}:{{ tpl .Values.image.tools.tag . }}
imagePullPolicy: {{ default .Values.image.pullPolicy .Values.image.terraria.pullPolicy }}
{{- end }}

{{- define "terraria.livenessPacket" -}}
echo 'DAABCExpdmVuZXNz' | base64 -d
{{- end }}

{{- define "terraria.socatLivenessCommand" -}}
{{ include "terraria.livenessPacket" . }} | socat - tcp-connect:{{ include "terraria.fullname" . }}:7777 | grep 'Multiplayer.4'
{{- end }}

{{/*
Checks if the terraria server is accepting connections.
Sends a "connection request" packet with "Liveness" as version (base64 encoded string), the server
should respond with "Multiplayer.4" which is a version mismatch disconnect message.
*/}}
{{- define "terraria.livenessCheck" -}}
exec:
  command:
    - bash
    - -c
    - "{{ include "terraria.livenessPacket" . }} | (exec 3<>/dev/tcp/localhost/7777; cat >&3; cat <&3; exec 3<&-) | grep 'Multiplayer.4'"
{{- end }}

{{/*
Returns if the deployed image is tshock.
*/}}
{{- define "terraria.tshock" -}}
  {{- if .Values.image.terraria.type }}
    {{- if eq .Values.image.terraria.type "tshock" }}
      true
    {{- end }}
  {{- else if contains "tshock" (tpl .Values.image.terraria.tag .) }}
    true
  {{- end }}
{{- end }}

{{/*
Define the namespace template if set with forceNamespace or .Release.Namespace is set.
*/}}
{{- define "terraria.namespace" -}}
{{- if .Values.forceNamespace -}}
namespace: {{ .Values.forceNamespace }}
{{- else -}}
namespace: {{ .Release.Namespace }}
{{- end -}}
{{- end -}}

{{/*
Define probe values.
*/}}
{{- define "terraria.probeValues" -}}
initialDelaySeconds: {{ .initialDelaySeconds }}
periodSeconds: {{ .periodSeconds }}
timeoutSeconds: {{ .timeoutSeconds }}
successThreshold: {{ .successThreshold }}
failureThreshold: {{ .failureThreshold }}
{{- end }}