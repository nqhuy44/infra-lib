{{- define "worker.template" }}
{{- if .worker }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .worker.name }}
  labels:
    app: {{ .worker.name }}
    tier: {{ default "worker" .worker.tier }}
spec:
  replicas: {{ default "1" .worker.replicas }}
  selector:
    matchLabels:
      app: {{ .worker.name }}
      tier: {{ default "worker" .worker.tier }}
  template:
    metadata:
      labels:
        app: {{ .worker.name }}
        tier: {{ default "worker" .worker.tier }}
        {{- if .Values.podLabels }}
        {{- toYaml .Values.podLabels | nindent 8 }}
        {{- end }}        
    spec:
      restartPolicy: {{ default "Always" .image.restartPolicy }}
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
      terminationGracePeriodSeconds: {{ default 300 .worker.terminationGracePeriodSeconds}}
      {{- if .image.imagePullSecrets }}
      imagePullSecrets: {{ toYaml .image.imagePullSecrets | nindent 8 }}
      {{- end }}
      {{- if .Values.serviceAccount.enabled }}
      serviceAccountName: {{ template "saName" $ }}
      {{- end }}
      containers:
        #                #
        # CONTAINER MAIN #
        #                #
        - name: {{ .worker.name }}
          image: {{ .image.registry }}/{{ .image.repository }}:{{ .image.tag }}
          {{- if .worker.envs }}
          env:
          {{- range $k, $v := .worker.envs }}
            - name: {{ $k }}
              value: {{ $v | quote}}
          {{- end }}
          {{- end }}
          imagePullPolicy: {{ .image.pullPolicy | quote }}
          {{- if .Values.lifecycle }}
          lifecycle: {{- toYaml .Values.lifecycle | nindent 12 }}
          {{- end }}
          {{- if .worker.command }}
          command: 
          - /bin/sh
          - -c 
          - while ! [ -f /tmp/kill_me ]; do {{ .worker.command }}; done;
          {{- end }}
          {{- if .worker.resources }}
          resources: {{ toYaml .worker.resources | nindent 12 }}
          {{- end }}
          {{- if .worker.livenessProbe }}
          livenessProbe: {{- toYaml .worker.livenessProbe | nindent 12 }}
          {{- end }}
          {{- if .worker.readinessProbe }}
          readinessProbe: {{- toYaml .worker.readinessProbe | nindent 12 }}
          {{- end }}
          {{- if .Values.startupProbe }}
          startupProbe: {{- toYaml .Values.startupProbe | nindent 12 }}
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

            {{- if .Values.externalEnvFromAWS.enabled }}
            - name: {{ template "secretName" $ }}
              mountPath: {{ "/mnt/secret" }}
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
      affinity: {{- toYaml .Values.affinity | nindent 8 }}
      {{- end }}
      {{- if .Values.nodeSelector }}
      nodeSelector: {{- toYaml .Values.nodeSelector | nindent 8 }}
      {{- end }}
      {{- if .Values.tolerations }}
      tolerations: {{- toYaml .Values.tolerations | nindent 6 }}
      {{- end }}

{{- end }}
{{- end }}
