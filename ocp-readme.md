# Smithsonian Institution Baseline Drupal Insallation OpenShift POC

## Steps to create OCP Objects Manually

1.  Login to OpenShift via command line

    ```console
    oc login ...
    ```

2.  Create a project to contain this

    ```console
    oc new-project druptest
    ```

3.  Switch to the project (the create command will do this by default)

    ```console
    oc project druptest
    ```

4.  Create a PVC (PersistantVolumeClaim)

    ```console
    oc apply -f - <<EOF
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: htdocs-pvc
      labels:
        app: htdocs
    spec:
      accessModes:
        - ReadWriteMany
      storageClassName: efs-sc
      resources:
        requests:
          storage: 10Gi
    EOF
    ```

5.  Create a simple imagestream and buildconfig for the PHP component

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

6.  Follow the image build logs:
    
    ```console
    oc logs -f bc/php-container-build
    ```

7.  Create a simple imagestream and buildconfig for the NGinx component

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

8.  Follow the image build logs:
    
    ```console
    oc logs -f bc/nginx-container-build
    ```

9.  Create a DeploymentConfig for the php component

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
          volumes:
          - name: htdocs
            persistentVolumeClaim:
              claimName: htdocs-pvc
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
            volumeMounts:
            - name: htdocs
              mountPath: "/opt/app/htdocs/"
          dnsPolicy: ClusterFirst
          restartPolicy: Always
          schedulerName: default-scheduler
          securityContext: {}
          terminationGracePeriodSeconds: 30
    EOF
    ```

10. Check that the pod comes up:

    ```console
    oc get pods
    ```

11. Create a service

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
      - name: 9000-tcp
        port: 9000
        protocol: TCP
        targetPort: 9000
      selector:
        deployment: php
      sessionAffinity: None
      type: ClusterIP
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
          volumes:
          - name: htdocs
            persistentVolumeClaim:
              claimName: htdocs-pvc
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
            volumeMounts:
            - name: htdocs
              mountPath: "/var/www/html/"
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

20. How to manually copy files

    ```
    oc rsync ./htdocs/ nginx-786bf7bf7b-9tlnn:/var/www/html/htdocs/ 
    oc rsync ./htdocs/ php-f74f65d57-smtct:/opt/app/htdocs
    ```

## Deploy via GitOps

1.  Login to OpenShift via command line as a admin.

    ```console
    $ oc login ...
    ```

2.  Create GitOps namespace. For this command to work you *MUST* be a [cluster `admin` user in OCP RBAC](https://docs.openshift.com/container-platform/4.16/authentication/using-rbac.html).

    ```console
    $ oc create namespace openshift-gitops-operator
    $ oc project openshift-gitops-operator
    ```

    The reason you're using the `oc create namespace` is running `oc new-project` will fail. For example:?

    ```console
    $ oc new-project openshift-gitops-operator
    Error from server (Forbidden): project.project.openshift.io "openshift-gitops-operator" is forbidden: cannot request a project starting with "openshift-"
    ```

3.  Apply the `OperatorGroup` object.

    ```console
    oc apply -f - <<EOF
    apiVersion: operators.coreos.com/v1
    kind: OperatorGroup
    metadata:
      name: openshift-gitops-operator
      namespace: openshift-gitops-operator
    spec:
      upgradeStrategy: Default
    EOF
    ```

4.  Apply the Subscription object to subscribe the operator in the `openshift-gitops-operator` namespace.

    ```console
    oc apply -f - <<EOF
    apiVersion: operators.coreos.com/v1alpha1
    kind: Subscription
    metadata:
      name: openshift-gitops-operator
      namespace: openshift-gitops-operator
    spec:
      channel: latest 
      installPlanApproval: Automatic
      name: openshift-gitops-operator 
      source: redhat-operators 
      sourceNamespace: openshift-marketplace
    EOF
    ```

5.  After the installation is complete, verify that all the pods in the `openshift-gitops` namespace are running. This can take a few minutes depending on your network to even return anything.

    ```console
    $ oc get pods -n openshift-gitops
    NAME                                                      	      READY   STATUS    RESTARTS   AGE
    cluster-b5798d6f9-zr576                                   	      1/1 	  Running   0          65m
    kam-69866d7c48-8nsjv                                      	      1/1 	  Running   0          65m
    openshift-gitops-application-controller-0                 	      1/1 	  Running   0          53m
    openshift-gitops-applicationset-controller-6447b8dfdd-5ckgh       1/1 	  Running   0          65m
    openshift-gitops-dex-server-569b498bd9-vf6mr                      1/1     Running   0          65m
    openshift-gitops-redis-74bd8d7d96-49bjf                   	      1/1 	  Running   0          65m
    openshift-gitops-repo-server-c999f75d5-l4rsg              	      1/1 	  Running   0          65m
    openshift-gitops-server-5785f7668b-wj57t                  	      1/1 	  Running   0          53m
    ```

5.  Verify that the pod/s in the `openshift-gitops-operator` namespace are running.

    ```console
    $ oc get pods -n openshift-gitops-operator
    NAME                                                            READY   STATUS    RESTARTS   AGE
    openshift-gitops-operator-controller-manager-664966d547-vr4vb   2/2     Running   0          65m
    ```
## References

* [OpenShift Container Platform Documentation: Images: Creating Images](https://github.com/openshift/source-to-image)
* [OpenShift Origin GitHub: Source-To-Image](https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html#images-create-guidelines_create-images)
* [OpenShift Docker/Container Build Examples](https://github.com/openshift-examples/container-build)