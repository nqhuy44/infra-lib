{{- define "image" -}}
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

{{- define "imagePreInstall" -}}
{{ .Values.image.registry }}/{{ .Values.preInstalls.image.repository }}:{{ .Values.preInstalls.image.tag }}
{{- end }}

{{- define "chart.fullname" -}}
{{- printf "%s" .Values.name -}}
{{- end -}}

{{- define "serviceport" -}}
{{- .Values.service.port -}}
{{- end -}}

{{- define "envFile" -}}
{{ .Values.externalEnv.fileName | default ".env" }}
{{- end -}}

{{- define "configmapName" -}}
"{{ template "chart.fullname" $ }}-configmap"
{{- end -}}

{{- define "configmapDataName" -}}
"{{ template "chart.fullname" $ }}-data-configmap"
{{- end -}}

{{- define "secretName" -}}
"{{ template "chart.fullname" $ }}-secret"
{{- end -}}

{{- define "secretNameFiles" -}}
"{{ template "chart.fullname" $ }}-secret-files"
{{- end -}}

{{- define "saName" -}}
"{{ template "chart.fullname" $ }}-sa"
{{- end -}}


# {{- define "externalEnvReadOnly" -}}
# {{ if eq (.Values.externalEnv.readOnly | toString) "true" }}true{{ else }}false{{ end }}
# {{- end -}}
