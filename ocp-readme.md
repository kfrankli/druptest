# Smithsonian Institue Baseline Drupal Insallation OpenShift POC

## Steps

1.  Login to OpenShift via command line

    ```console
    $ oc login ...
    ```

2.  Create a project to contain this

    ```console
    $ oc new-project druptest
    ```

3.  Switch to the project (the create command will do this by default)

    ```console
    $ oc project druptest
    ```

4.  Create a simple imagestream and buildconfig for the PHP component

    ```console
    oc apply -f - <<EOF
    kind: ImageStream
    apiVersion: image.openshift.io/v1
    metadata:
      name: php-container-build
    spec:
      lookupPolicy:
        local: true
    EOF

    oc apply -f - <<EOF
    apiVersion: build.openshift.io/v1
    kind: BuildConfig
    metadata:
        name: php-container-build
        labels:
            name: php-container-build
    spec:
        triggers:
            - type: ConfigChange
        source:
            type: Git
            git:
                uri: 'https://github.com/kfrankli/druptest'
        strategy:
            type: Docker
            dockerStrategy:
                dockerfilePath: ".ContainerFiles/php/Containerfile"
        output:
            to:
              kind: ImageStreamTag
              name: 'php-container-build:latest'
    EOF
    ```

5.  Follow the image build logs:
    
    ```console
    oc logs -f bc/php-container-build
    ```

6.  Create a simple imagestream and buildconfig for the NGinx component

    ```console
    oc apply -f - <<EOF
    kind: ImageStream
    apiVersion: image.openshift.io/v1
    metadata:
      name: nginx-container-build
    spec:
      lookupPolicy:
        local: true
    EOF

    oc apply -f - <<EOF
    apiVersion: build.openshift.io/v1
    kind: BuildConfig
    metadata:
        name: nginx-container-build
        labels:
            name: nginx-container-build
    spec:
        triggers:
            - type: ConfigChange
        source:
            type: Git
            git:
                uri: 'https://github.com/kfrankli/druptest'
        strategy:
            type: Docker
            dockerStrategy:
                dockerfilePath: ".ContainerFiles/nginx/Containerfile"
        output:
            to:
              kind: ImageStreamTag
              name: 'nginx-container-build:latest'
    EOF
    ```

7.  Follow the image build logs:
    
    ```console
    oc logs -f bc/nginx-container-build
    ```

8.  Create a DeploymentConfig for the php component

    ```console
    oc apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: php
      name: php
    spec:
      progressDeadlineSeconds: 600
      replicas: 1
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          deployment: php
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          annotations:
            alpha.image.policy.openshift.io/resolve-names: '*'
          labels:
            deployment: php
        spec:
          containers:
          - image: php-container-build:latest
            imagePullPolicy: Always
            name: php
            ports:
            - containerPort: 8080
              protocol: TCP
            - containerPort: 8443
              protocol: TCP
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
          dnsPolicy: ClusterFirst
          restartPolicy: Always
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
    EOF
    ```

    9.  Check that the pod comes up:

    ```console
    oc get pods
    ```

    10. Create a service

    ```console
    oc apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: php
      name: php
    spec:
      ports:
      - name: 8080-tcp
        port: 8080
        protocol: TCP
        targetPort: 8080
      - name: 8443-tcp
        port: 8443
        protocol: TCP
        targetPort: 8443
      selector:
        deployment: php
      sessionAffinity: None
      type: ClusterIP
    EOF
    ```

    11. Create a php route
    
    ```console
    oc apply -f - <<EOF
    kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: php
      namespace: druptest
      labels:
        app: php
    spec:
      to:
        kind: Service
        name: php
      tls: null
      port:
        targetPort: 8080-tcp
      alternateBackends: []
    EOF
    ```

    12. Create a DeploymentConfig for the nginx component

    ```console
    oc apply -f - <<EOF
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        app: nginx
      name: nginx
    spec:
      progressDeadlineSeconds: 600
      replicas: 1
      revisionHistoryLimit: 10
      selector:
        matchLabels:
          deployment: nginx
      strategy:
        rollingUpdate:
          maxSurge: 25%
          maxUnavailable: 25%
        type: RollingUpdate
      template:
        metadata:
          annotations:
            alpha.image.policy.openshift.io/resolve-names: '*'
          labels:
            deployment: nginx
        spec:
          containers:
          - image: nginx-container-build:latest
            imagePullPolicy: Always
            name: nginx
            ports:
            - containerPort: 8080
              protocol: TCP
            resources: {}
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
          dnsPolicy: ClusterFirst
          restartPolicy: Always
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
    EOF
    ```

    13. Check that the pod comes up:

    ```console
    oc get pods
    ```

    14. Create a nginx service

    ```console
    oc apply -f - <<EOF
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app: nginx
      name: nginx
    spec:
      ports:
      - name: 8080-tcp
        port: 8080
        protocol: TCP
        targetPort: 8080
      - name: 8443-tcp
        port: 8443
        protocol: TCP
        targetPort: 8443
      selector:
        deployment: nginx
      sessionAffinity: None
      type: ClusterIP
    EOF
    ```

    15. Create a nginx route
    
    ```console
    oc apply -f - <<EOF
    kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: nginx
      namespace: druptest
      labels:
        app: nginx
    spec:
      to:
        kind: Service
        name: nginx
      tls: null
      port:
        targetPort: 8080-tcp
      alternateBackends: []
    EOF
    ```

    16. Find the route name for nginx

    ```console
    oc get route nginx
    ```

    17. Use curl to confirm it's deployed

    ```console
    curl nginx-druptest.apps.cluster-swzqb.swzqb.sandbox1915.opentlc.com
    ```



## References

* [OpenShift Docker/Container Build Examples](https://github.com/openshift-examples/container-build)