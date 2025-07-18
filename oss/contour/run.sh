#!/bin/bash
PS3='Would you like to add ingress-class-name, when you installed ako plugin? input number: '
select option in Yes No
do
    case $option in
      Yes)
	      yringress="Yes"
            break;;
      No)
	      yringress="No"
            break;;
    esac
done

echo "What is your contour namespace?"
read contourns

cat > 00-common.yaml << EOF
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    pod-security.kubernetes.io/enforce: privileged
  name: ${contourns}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: contour
  namespace: ${contourns}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: envoy
  namespace: ${contourns}
EOF

cat > 01-contour-config.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: contour
  namespace: ${contourns}
data:
  contour.yaml: |
    # Specify the Gateway API configuration.
    # gateway:
    #   namespace: projectcontour
    #   name: contour
    #
    # should contour expect to be running inside a k8s cluster
    # incluster: true
    #
    # path to kubeconfig (if not running inside a k8s cluster)
    # kubeconfig: /path/to/.kube/config
    #
    # Disable RFC-compliant behavior to strip "Content-Length" header if
    # "Tranfer-Encoding: chunked" is also set.
    # disableAllowChunkedLength: false
    #
    # Disable Envoy's non-standard merge_slashes path transformation option
    # that strips duplicate slashes from request URLs.
    # disableMergeSlashes: false
    #
    # Disable HTTPProxy permitInsecure field
    disablePermitInsecure: false
    tls:
    # minimum TLS version that Contour will negotiate
    # minimum-protocol-version: "1.2"
    # TLS ciphers to be supported by Envoy TLS listeners when negotiating
    # TLS 1.2.
    # cipher-suites:
    # - '[ECDHE-ECDSA-AES128-GCM-SHA256|ECDHE-ECDSA-CHACHA20-POLY1305]'
    # - '[ECDHE-RSA-AES128-GCM-SHA256|ECDHE-RSA-CHACHA20-POLY1305]'
    # - 'ECDHE-ECDSA-AES256-GCM-SHA384'
    # - 'ECDHE-RSA-AES256-GCM-SHA384'
    # Defines the Kubernetes name/namespace matching a secret to use
    # as the fallback certificate when requests which don't match the
    # SNI defined for a vhost.
      fallback-certificate:
    #   name: fallback-secret-name
    #   namespace: projectcontour
      envoy-client-certificate:
    #   name: envoy-client-cert-secret-name
    #   namespace: projectcontour
    ####
    # ExternalName Services are disabled by default due to CVE-2021-XXXXX
    # You can re-enable them by setting this setting to `true`.
    # This is not recommended without understanding the security implications.
    # Please see the advisory at https://github.com/projectcontour/contour/security/advisories/GHSA-5ph6-qq5x-7jwc for the details.
    # enableExternalNameService: false
    ##
    # Address to be placed in status.loadbalancer field of Ingress objects.
    # May be either a literal IP address or a host name.
    # The value will be placed directly into the relevant field inside the status.loadBalancer struct.
    # ingress-status-address: local.projectcontour.io
    ### Logging options
    # Default setting
    accesslog-format: envoy
    # The default access log format is defined by Envoy but it can be customized by setting following variable.
    # accesslog-format-string: "...\n"
    # To enable JSON logging in Envoy
    # accesslog-format: json
    # accesslog-level: info
    # The default fields that will be logged are specified below.
    # To customise this list, just add or remove entries.
    # The canonical list is available at
    # https://godoc.org/github.com/projectcontour/contour/internal/envoy#JSONFields
    # json-fields:
    #   - "@timestamp"
    #   - "authority"
    #   - "bytes_received"
    #   - "bytes_sent"
    #   - "downstream_local_address"
    #   - "downstream_remote_address"
    #   - "duration"
    #   - "method"
    #   - "path"
    #   - "protocol"
    #   - "request_id"
    #   - "requested_server_name"
    #   - "response_code"
    #   - "response_flags"
    #   - "uber_trace_id"
    #   - "upstream_cluster"
    #   - "upstream_host"
    #   - "upstream_local_address"
    #   - "upstream_service_time"
    #   - "user_agent"
    #   - "x_forwarded_for"
    #   - "grpc_status"
    #   - "grpc_status_number"
    #
    # default-http-versions:
    # - "HTTP/2"
    # - "HTTP/1.1"
    #
    # The following shows the default proxy timeout settings.
    # timeouts:
    #   request-timeout: infinity
    #   connection-idle-timeout: 60s
    #   stream-idle-timeout: 5m
    #   max-connection-duration: infinity
    #   delayed-close-timeout: 1s
    #   connection-shutdown-grace-period: 5s
    #   connect-timeout: 2s
    #
    # Envoy cluster settings.
    # cluster:
    #   configure the cluster dns lookup family
    #   valid options are: auto (default), v4, v6
    #   dns-lookup-family: auto
    #
    # Envoy network settings.
    # network:
    #   Configure the number of additional ingress proxy hops from the
    #   right side of the x-forwarded-for HTTP header to trust.
    #   num-trusted-hops: 0
    #   Configure the port used to access the Envoy Admin interface.
    #   admin-port: 9001
    #
    # Configure an optional global rate limit service.
    # rateLimitService:
    #   Identifies the extension service defining the rate limit service,
    #   formatted as <namespace>/<name>.
    #   extensionService: projectcontour/ratelimit
    #   Defines the rate limit domain to pass to the rate limit service.
    #   Acts as a container for a set of rate limit definitions within
    #   the RLS.
    #   domain: contour
    #   Defines whether to allow requests to proceed when the rate limit
    #   service fails to respond with a valid rate limit decision within
    #   the timeout defined on the extension service.
    #   failOpen: false
    #   Defines whether to include the X-RateLimit headers X-RateLimit-Limit,
    #   X-RateLimit-Remaining, and X-RateLimit-Reset (as defined by the IETF
    #   Internet-Draft linked below), on responses to clients when the Rate
    #   Limit Service is consulted for a request.
    #   ref. https://tools.ietf.org/id/draft-polli-ratelimit-headers-03.html
    #   enableXRateLimitHeaders: false
    #   Defines whether to translate status code 429 to grpc code RESOURCE_EXHAUSTED
    #   instead of the default UNAVAILABLE
    #   enableResourceExhaustedCode: false
    #
    # Global Policy settings.
    # policy:
    #   # Default headers to set on all requests (unless set/removed on the HTTPProxy object itself)
    #   request-headers:
    #     set:
    #       # example: the hostname of the Envoy instance that proxied the request
    #       X-Envoy-Hostname: %HOSTNAME%
    #       # example: add a l5d-dst-override header to instruct Linkerd what service the request is destined for
    #       l5d-dst-override: %CONTOUR_SERVICE_NAME%.%CONTOUR_NAMESPACE%.svc.cluster.local:%CONTOUR_SERVICE_PORT%
    #   # default headers to set on all responses (unless set/removed on the HTTPProxy object itself)
    #   response-headers:
    #     set:
    #       # example: Envoy flags that provide additional details about the response or connection
    #       X-Envoy-Response-Flags: %RESPONSE_FLAGS%
    #
    # metrics:
    #  contour:
    #    address: 0.0.0.0
    #    port: 8000
    #    server-certificate-path: /path/to/server-cert.pem
    #    server-key-path: /path/to/server-private-key.pem
    #    ca-certificate-path: /path/to/root-ca-for-client-validation.pem
    #  envoy:
    #    address: 0.0.0.0
    #    port: 8002
    #    server-certificate-path: /path/to/server-cert.pem
    #    server-key-path: /path/to/server-private-key.pem
    #    ca-certificate-path: /path/to/root-ca-for-client-validation.pem
    #
    # listener:
    #  connection-balancer: exact
    #  socket-options:
    #    tos: 64
    #    traffic-class: 64
    #
    # omEnforcedHealthListener:
    #   address: 0.0.0.0
    #   port: 8003
EOF

cat > 02-job-certgen.yaml << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: contour-certgen
  namespace: ${contourns}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: contour
  namespace: ${contourns}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: contour-certgen
subjects:
- kind: ServiceAccount
  name: contour-certgen
  namespace: ${contourns}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: contour-certgen
  namespace: ${contourns}
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - create
  - update
---
apiVersion: batch/v1
kind: Job
metadata:
  name: contour-certgen-main
  namespace: ${contourns}
spec:
  ttlSecondsAfterFinished: 0
  template:
    metadata:
      labels:
        app: "contour-certgen"
    spec:
      containers:
      - name: contour
        image: ghcr.io/projectcontour/contour:main
        imagePullPolicy: Always
        command:
        - contour
        - certgen
        - --kube
        - --incluster
        - --overwrite
        - --secrets-format=compact
        - --namespace=\$(CONTOUR_NAMESPACE)
        env:
        - name: CONTOUR_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      restartPolicy: Never
      serviceAccountName: contour-certgen
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        runAsGroup: 65534
  parallelism: 1
  completions: 1
  backoffLimit: 1
EOF

cat > 02-rbac.yaml << EOF
---
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: contour
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: contour
subjects:
- kind: ServiceAccount
  name: contour
  namespace: ${contourns}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: contour-rolebinding
  namespace: ${contourns}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: contour
subjects:
- kind: ServiceAccount
  name: contour
  namespace: ${contourns}

EOF

cat > 02-role-contour.yaml << EOF
# The following ClusterRole and Role are generated from kubebuilder RBAC tags by
# generate-rbac.sh. Do not edit this file directly but instead edit the source
# files and re-render.
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: contour
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - namespaces
  - secrets
  - services
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - backendtlspolicies
  - gatewayclasses
  - gateways
  - grpcroutes
  - httproutes
  - referencegrants
  - tcproutes
  - tlsroutes
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - gateway.networking.k8s.io
  resources:
  - backendtlspolicies/status
  - gatewayclasses/status
  - gateways/status
  - grpcroutes/status
  - httproutes/status
  - tcproutes/status
  - tlsroutes/status
  verbs:
  - update
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - networking.k8s.io
  resources:
  - ingresses/status
  verbs:
  - create
  - get
  - update
- apiGroups:
  - projectcontour.io
  resources:
  - contourconfigurations
  - extensionservices
  - httpproxies
  - tlscertificatedelegations
  verbs:
  - get
  - list
  - watch
- apiGroups:
  - projectcontour.io
  resources:
  - contourconfigurations/status
  - extensionservices/status
  - httpproxies/status
  verbs:
  - create
  - get
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: contour
  namespace: ${contourns}
rules:
- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - create
  - get
  - update
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - create
  - get
  - update
EOF

cat > 02-service-contour.yaml << EOF
---
apiVersion: v1
kind: Service
metadata:
  name: contour
  namespace: ${contourns}
spec:
  ports:
  - port: 8001
    name: xds
    protocol: TCP
    targetPort: 8001
  selector:
    app: contour
  type: ClusterIP
EOF

cat > 02-service-envoy.yaml << EOF
---
apiVersion: v1
kind: Service
metadata:
  name: envoy
  namespace: ${contourns}
  annotations:
    # This annotation puts the AWS ELB into "TCP" mode so that it does not
    # do HTTP negotiation for HTTPS connections at the ELB edge.
    # The downside of this is the remote IP address of all connections will
    # appear to be the internal address of the ELB. See docs/proxy-proto.md
    # for information about enabling the PROXY protocol on the ELB to recover
    # the original remote IP address.
    # service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
spec:
  externalTrafficPolicy: Local
  ports:
  - port: 80
    name: http
    protocol: TCP
    targetPort: 8080
  - port: 443
    name: https
    protocol: TCP
    targetPort: 8443
  selector:
    app: envoy
  type: LoadBalancer
EOF

cat > 03-contour.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: contour
  name: contour
  namespace: ${contourns}
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      # This value of maxSurge means that during a rolling update
      # the new ReplicaSet will be created first.
      maxSurge: 50%
  selector:
    matchLabels:
      app: contour
  template:
    metadata:
      labels:
        app: contour
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: contour
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - args:
        - serve
        - --incluster
        - --xds-address=0.0.0.0
        - --xds-port=8001
        - --contour-cafile=/certs/ca.crt
        - --contour-cert-file=/certs/tls.crt
        - --contour-key-file=/certs/tls.key
        - --config-path=/config/contour.yaml
        command: ["contour"]
        image: ghcr.io/projectcontour/contour:v1.32.0
        imagePullPolicy: IfNotPresent
        name: contour
        ports:
        - containerPort: 8001
          name: xds
          protocol: TCP
        - containerPort: 8000
          name: metrics
          protocol: TCP
        - containerPort: 6060
          name: debug
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8000
        readinessProbe:
          tcpSocket:
            port: 8001
          periodSeconds: 10
        volumeMounts:
          - name: contourcert
            mountPath: /certs
            readOnly: true
          - name: contour-config
            mountPath: /config
            readOnly: true
        env:
        - name: CONTOUR_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
      dnsPolicy: ClusterFirst
      serviceAccountName: contour
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        runAsGroup: 65534
      volumes:
        - name: contourcert
          secret:
            secretName: contourcert
        - name: contour-config
          configMap:
            name: contour
            defaultMode: 0644
            items:
            - key: contour.yaml
              path: contour.yaml
EOF

cat > 03-envoy.yaml << EOF
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app: envoy
  name: envoy
  namespace: ${contourns}
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 10%
  selector:
    matchLabels:
      app: envoy
  template:
    metadata:
      labels:
        app: envoy
    spec:
      containers:
      - command:
        - /bin/contour
        args:
          - envoy
          - shutdown-manager
        image: ghcr.io/projectcontour/contour:v1.32.0
        imagePullPolicy: Always
        lifecycle:
          preStop:
            exec:
              command:
                - /bin/contour
                - envoy
                - shutdown
        name: shutdown-manager
        volumeMounts:
          - name: envoy-admin
            mountPath: /admin
      - args:
        - -c
        - /config/envoy.json
        - --service-cluster \$(CONTOUR_NAMESPACE)
        - --service-node \$(ENVOY_POD_NAME)
        - --log-level info
        command:
        - envoy
        image: docker.io/envoyproxy/envoy:v1.34.1
        imagePullPolicy: IfNotPresent
        name: envoy
        env:
        - name: CONTOUR_NAMESPACE
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.namespace
        - name: ENVOY_POD_NAME
          valueFrom:
            fieldRef:
              apiVersion: v1
              fieldPath: metadata.name
        ports:
        - containerPort: 8080
          hostPort: 80
          name: http
          protocol: TCP
        - containerPort: 8443
          hostPort: 443
          name: https
          protocol: TCP
        - containerPort: 8002
          hostPort: 8002
          name: metrics
          protocol: TCP
        readinessProbe:
          httpGet:
            path: /ready
            port: 8002
          initialDelaySeconds: 3
          periodSeconds: 4
        volumeMounts:
          - name: envoy-config
            mountPath: /config
            readOnly: true
          - name: envoycert
            mountPath: /certs
            readOnly: true
          - name: envoy-admin
            mountPath: /admin
        lifecycle:
          preStop:
            httpGet:
              path: /shutdown
              port: 8090
              scheme: HTTP
      initContainers:
      - args:
        - bootstrap
        - /config/envoy.json
        - --xds-address=contour
        - --xds-port=8001
        - --xds-resource-version=v3
        - --resources-dir=/config/resources
        - --envoy-cafile=/certs/ca.crt
        - --envoy-cert-file=/certs/tls.crt
        - --envoy-key-file=/certs/tls.key
        command:
        - contour
        image: ghcr.io/projectcontour/contour:main
        imagePullPolicy: Always
        name: envoy-initconfig
        volumeMounts:
        - name: envoy-config
          mountPath: /config
        - name: envoycert
          mountPath: /certs
          readOnly: true
        env:
        - name: CONTOUR_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      automountServiceAccountToken: false
      serviceAccountName: envoy
      terminationGracePeriodSeconds: 300
      volumes:
        - name: envoy-admin
          emptyDir: {}
        - name: envoy-config
          emptyDir: {}
        - name: envoycert
          secret:
            secretName: envoycert
      restartPolicy: Always
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        runAsGroup: 65534
EOF

if [[ $yringress = "Yes" ]]
then
	echo "What is your ingress class name(ex> ingress-contour)?"
  read ingressname
  echo "What is your ako labels(ex> avi: primary)?"
  read akolabels
  sed -i'' -r -e "/labels:/a\    ${akolabels}" ./00-common.yaml
  sed -i'' -r -e "/type: LoadBalancer/a\  loadBalancerClass: ako.vmware.com/avi-lb" ./02-service-envoy.yaml
  sed -i'' -r -e "/config-path/a\        - --ingress-class-name=${ingressname}" ./03-contour.yaml
  sed -i "s/hostPort:/#hostPort:/" ./03-envoy.yaml
cat > 00-ingressclass.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: ${ingressname}
spec:
  controller: projectcontour.io/ingress-controller
  parameters:
    apiGroup:  projectcontour.io
    kind: IngressParameters
    name: ${ingressname}
EOF
else
  echo ""
  echo ""
  echo "You dont use ingress-class-name"
fi

cp 01-crds.txt 01-crds.yaml
