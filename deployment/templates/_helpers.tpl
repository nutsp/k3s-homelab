{{/*
Expand the name of the chart.
*/}}
{{- define "deployment.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "deployment.fullname" -}}
{{- if .Values.nameOverride }}
{{- .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
{{- define "deployment.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "deployment.labels" -}}
helm.sh/chart: {{ include "deployment.chart" . }}
{{ include "deployment.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "deployment.selectorLabels" -}}
app.kubernetes.io/name: {{ include "deployment.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Auth service labels
*/}}
{{- define "deployment.auth.labels" -}}
helm.sh/chart: {{ include "deployment.chart" . }}
app.kubernetes.io/name: {{ .Values.auth.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: auth
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Auth service selector labels
*/}}
{{- define "deployment.auth.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.auth.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Profile service labels
*/}}
{{- define "deployment.profile.labels" -}}
helm.sh/chart: {{ include "deployment.chart" . }}
app.kubernetes.io/name: {{ .Values.profile.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: profile
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Profile service selector labels
*/}}
{{- define "deployment.profile.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.profile.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Auth image
*/}}
{{- define "deployment.auth.image" -}}
{{- if .Values.auth.image }}
{{- printf "%s:%s" .Values.auth.image.repository (.Values.auth.image.tag | default "latest") }}
{{- else }}
{{- printf "%s:%s" "ghcr.io/k3s-homelab/auth" "latest" }}
{{- end }}
{{- end }}

{{/*
Profile image
*/}}
{{- define "deployment.profile.image" -}}
{{- if .Values.profile.image }}
{{- printf "%s:%s" .Values.profile.image.repository (.Values.profile.image.tag | default "latest") }}
{{- else }}
{{- printf "%s:%s" "ghcr.io/k3s-homelab/profile" "latest" }}
{{- end }}
{{- end }}

{{/*
Auth service configmap checksum
*/}}
{{- define "deployment.auth.configmap.checksum" -}}
{{- .Values.auth.configmaps | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Auth service secret checksum
*/}}
{{- define "deployment.auth.secret.checksum" -}}
{{- .Values.auth.secrets | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Auth service image checksum
*/}}
{{- define "deployment.auth.image.checksum" -}}
{{- printf "%s:%s" .Values.auth.image.repository (.Values.auth.image.tag | default "latest") | b64enc | trunc 16 }}
{{- end }}

{{/*
Profile service configmap checksum
*/}}
{{- define "deployment.profile.configmap.checksum" -}}
{{- .Values.profile.configmaps | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Profile service secret checksum
*/}}
{{- define "deployment.profile.secret.checksum" -}}
{{- .Values.profile.secrets | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Profile service image checksum
*/}}
{{- define "deployment.profile.image.checksum" -}}
{{- printf "%s:%s" .Values.profile.image.repository (.Values.profile.image.tag | default "latest") | b64enc | trunc 16 }}
{{- end }}

{{/*
Keycloak service labels
*/}}
{{- define "deployment.keycloak.labels" -}}
helm.sh/chart: {{ include "deployment.chart" . }}
app.kubernetes.io/name: {{ .Values.keycloak.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: keycloak
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Keycloak service selector labels
*/}}
{{- define "deployment.keycloak.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.keycloak.service.name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Keycloak image
*/}}
{{- define "deployment.keycloak.image" -}}
{{- if .Values.keycloak.image }}
{{- printf "%s:%s" .Values.keycloak.image.repository (.Values.keycloak.image.tag | default "latest") }}
{{- else }}
{{- printf "%s:%s" "quay.io/keycloak/keycloak" "latest" }}
{{- end }}
{{- end }}

{{/*
Keycloak service configmap checksum
*/}}
{{- define "deployment.keycloak.configmap.checksum" -}}
{{- .Values.keycloak.configmaps | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Keycloak service secret checksum
*/}}
{{- define "deployment.keycloak.secret.checksum" -}}
{{- .Values.keycloak.secrets | toJson | b64enc | trunc 16 }}
{{- end }}

{{/*
Keycloak service image checksum
*/}}
{{- define "deployment.keycloak.image.checksum" -}}
{{- printf "%s:%s" .Values.keycloak.image.repository (.Values.keycloak.image.tag | default "latest") | b64enc | trunc 16 }}
{{- end }}

