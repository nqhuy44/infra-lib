{{- define "cronjob.template" }}
{{- if .cronjob }}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ .cronjob.name }}
spec:
  {{- if .cronjob.suspend }}
  suspend: {{   .cronjob.suspend }}
  {{- end }}
  schedule: {{ .cronjob.schedule | quote }}
  {{- if .cronjob.timezone }}
  timeZone: {{ .cronjob.timezone | quote }}
  {{- end }}
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: {{ .cronjob.successfulJobsHistoryLimit | default 1 }}
  failedJobsHistoryLimit: {{ .cronjob.failedJobsHistoryLimit | default 1 }}
  startingDeadlineSeconds: {{ default 180 .cronjob.startingDeadlineSeconds }}
  jobTemplate:
    metadata:
      labels:
        cronjob: {{ .cronjob.name }} # <-- match created jobs with the cronjob
    spec:
      template:
        metadata:
          labels:
            cronjob: {{ .cronjob.name }} # <-- and add at here
            {{- if .Values.podLabels }}
            {{- toYaml .Values.podLabels | nindent 12 }}
            {{- end }}
        spec:
          restartPolicy: {{ default "OnFailure" .image.restartPolicy }}
          {{- if .hostAliases }}
          hostAliases:
          {{- range .hostAliases }}
            - ip: {{ .ip }}
              hostnames:
              {{- range .hostnames }}
                - {{ . }}
              {{- end}}
          {{- end }}
          {{- end }}
          {{- if .cronjob.terminationGracePeriodSeconds }}
          terminationGracePeriodSeconds: {{ .cronjob.terminationGracePeriodSeconds }}
          {{- end }}
          {{- if .image.imagePullSecrets }}
          imagePullSecrets: {{ toYaml .image.imagePullSecrets | nindent 12 }}
          {{- end }}
          {{- if .Values.serviceAccount.enabled }}
          serviceAccountName: {{ template "saName" $ }}
          {{- end }}
          containers:
            #                #
            # CONTAINER MAIN #
            #                #
            - name: {{ .cronjob.name }}
              {{- if and (kindIs "map" .cronjob.image) .cronjob.image.registry .cronjob.image.repository .cronjob.image.tag }}
              image: {{ printf "%s/%s:%s" .cronjob.image.registry .cronjob.image.repository .cronjob.image.tag }}
              {{- else }}
              image: {{ .cronjob.image }}
              {{- end }}
              imagePullPolicy: {{ .image.pullPolicy | quote }}
              {{- if .Values.lifecycle }}
              lifecycle: {{- toYaml .Values.lifecycle | nindent 16 }}
              {{- end }}
              command: {{ toYaml .cronjob.command | nindent 16 }}
              {{- if .cronjob.resources }}
              resources: {{ toYaml .cronjob.resources | nindent 16 }}
              {{- end }}
              {{- if .cronjob.envs }}
              env:
              {{- range $k, $v := .cronjob.envs }}
                - name: {{ $k }}
                  value: {{ $v | quote}}
              {{- end }}
              {{- end }}

              #              #
              # VOLUME MOUNT #
              #              #
              volumeMounts:
                # Basic mount RWO #
                {{- if .Values.mounts }}
                {{- range .Values.mounts }}
                - mountPath: {{ .mountPath }}
                  name: "{{ template "chart.fullname" $ }}-volume"
                  subPath: {{ .filename }}
                  readOnly: true
                {{- end }}
                {{- end }}

                # External ENV by file #
                {{- if and (.Values.externalEnvFromCM.enabled) (eq .Values.externalEnvFromCM.type "file")  }}
                - mountPath: "{{ .Values.externalEnvFromCM.mountPath }}"
                  name: {{ template "configmapName" $ }}
                  subPath: {{ template "envFile" $ }}
                  readOnly: {{ template "externalEnvReadOnly" $ }}
                {{- end }}

                # Extra configmap with type is file#
                {{- range .Values.externalData }}
                {{- if eq .type "file" }}
                - mountPath: {{ .mountPath }}
                  name: {{ .name }}
                  subPath: {{ .fileName }}
                  readOnly: {{ .readOnly }}
                {{- end }}
                {{- end }}

                {{- if .Values.externalEnvFromAWS.enabled }}
                - name: {{ template "secretName" $ }}
                  mountPath: {{ "/mnt/secret" }}
                {{- end }}

                # Persistent volume RWM #
                {{- if .Values.persistentVolumes }}
                {{- range .Values.persistentVolumes }}
                - mountPath: "{{ .mountPath }}"
                  {{- if .subPath }}
                  subPath: "{{ .subPath }}"
                  {{- end }}
                  name: "{{ .name }}"
                {{- end }}
                {{- end }}

              # Env with external type variable #
              # If disableExternalEnv is true then skip this section #
              {{- if not .cronjob.disableExternalEnv }}
              {{- if or (.Values.externalEnvFromAWS.enabled) (.Values.externalEnvFromVault.enabled) (and (.Values.externalEnvFromCM.enabled) (eq .Values.externalEnvFromCM.type "variable")) }}
              envFrom:
                # Default map to configmap #
              - configMapRef:
                  name: {{ template "configmapName" $ }}
                # ENV with external by secret #
              {{- if or (.Values.externalEnvFromAWS.enabled) (.Values.externalEnvFromVault.enabled) }}
              - secretRef:
                  name: {{ template "secretName" $ }}
              {{- end }}
              {{- end }}
              {{- end }}

          #        #
          # VOLUME #
          #        #
          volumes:
          # Basic mount RWO #
          {{- if .Values.mounts }}
          - name: "{{ template "chart.fullname" $ }}-volume"
            configMap:
              name: "{{ template "chart.fullname" $ }}"
              items:
                {{- range .Values.mounts }}
                - key: {{ .name }}
                  path: {{ .filename }}
                {{- end }}
          {{- end }}

          # configmap #
          {{- if and (eq .Values.externalEnvFromCM.type "file") (.Values.externalEnvFromCM.enabled) }}
          - name: {{ template "configmapName" $ }}
            configMap:
              name: {{ template "configmapName" $ }}
          {{- end }}

          # Extra configmaps #
          {{- range .Values.externalData }}
          {{- if eq .type "file" }}
          - name: {{ .name }}
            configMap:
              name: {{ .name }}
          {{- end }}
          {{- end }}

          # secret #
          {{- if .Values.externalEnvFromAWS.enabled }}
          - name: {{ template "secretName" $ }}
            csi:
              driver: secrets-store.csi.k8s.io
              readOnly: true
              volumeAttributes:
                secretProviderClass: {{ template "secretName" $ }}
          {{- end }}
            
          # Persistenct volume RWM #
          {{- if .Values.persistentVolumes }}
          {{- range .Values.persistentVolumes }}
          - name: "{{ .name }}"
            persistentVolumeClaim:
              {{- if .existingClaim }}
              claimName: "{{ .existingClaim }}"
              {{- else }}
              claimName: "{{ printf "%s-%s" (include "chart.fullname" $) .name }}"
              {{- end }}
          {{- end }}
          {{- end }}

          {{- if .Values.affinity }}
          affinity: {{- toYaml .Values.affinity | nindent 12 }}
          {{- end }}
          {{- if .Values.nodeSelector }}
          nodeSelector: {{- toYaml .Values.nodeSelector | nindent 12 }}
          {{- end }}
          {{- if .Values.tolerations }}
          tolerations: {{- toYaml .Values.tolerations | nindent 10 }}
          {{- end }} 
{{- end }}
{{- end }}

