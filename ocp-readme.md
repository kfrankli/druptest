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

4.  This part will take two paths depending on if you have RWX storage available or not. 

    - If you have **ReadWriteMany** storage available, create a single PVC:

      ```console
      oc apply -f - <<EOF
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: pvc-htdocs
        labels:
          app: htdocs
      spec:
        accessModes:
          - ReadWriteMany
        storageClassName: efs-sc  #Update as needed
        resources:
          requests:
            storage: 1Gi
      EOF
      ```
    
    - If  **ReadWriteMany** storage is **not** available, create a two PVCs:

      ```console
      oc apply -f - <<EOF
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: pvc-htdocs-nginx
        labels:
          app: htdocs-nginx
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
      EOF

      oc apply -f - <<EOF
      apiVersion: v1
      kind: PersistentVolumeClaim
      metadata:
        name: pvc-htdocs-php
        labels:
          app: htdocs-php
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
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
              name: 'druptest-php:latest'
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
              name: 'druptest-nginx:latest'
    EOF
    ```

8.  Follow the image build logs:
    
    ```console
    oc logs -f bc/nginx-container-build
    ```

9.  Create a Deployment for the php component

    - If you had **RWX** storage available and created one PVC, run the following.

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
                claimName: pvc-htdocs
            containers:
            - image: druptest-php:latest
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
    - If you didn't have **RWX** storage and had to make two PVCs, run the following

      ```
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
                claimName: pvc-htdocs-php
            containers:
            - image: druptest-php:latest
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

12. Create a Deployment for the nginx component

    - If you had **RWX** storage available and created one PVC, run the following.

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
                claimName: pvc-htdocs
            containers:
            - image: druptest-nginx:latest
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
    - If you didn't have **RWX** storage and had to make two PVCs, run the following


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
                claimName: pvc-htdocs-nginx
            containers:
            - image: druptest-nginx:latest
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
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
      port:
        targetPort: 8080-tcp
      alternateBackends: []
    EOF
    ```

16. We're going to manually copy files. First you need to get a the pod names:

    - If you had **RWX** storage available and created one PVC, run the following. Pick either the nginx or php pod name

      ```console
      c get pods -l deployment=php
      ```

      Now using the podnames to `oc rysnc` the contents to the instance replacing the pod name as appropriate:

      ```console
      oc rsync ./htdocs/ php-f74f65d57-smtct:/opt/app/htdocs
      ```

      Optionally if you wanted to get clever and use [Go templating](http://golang.org/pkg/text/template/#pkg-overview) to one line it:

      ```console
      oc rsync ./htdocs/ $(oc get pods -l deployment=php  --template='{{range .items}}{{.metadata.name}}{{end}}'):/opt/app/htdocs
      ```

    - If you didn't have **RWX** storage and had to make two PVCs, run the following

      ```console
      oc get pods -l deployment=php
      oc get pods -l deployment=nginx
      ```

      Now using the podnames to `oc rysnc` the contents to the instance replacing the pod name as appropriate:

      ```console
      oc rsync ./htdocs/ php-f74f65d57-smtct:/opt/app/htdocs
      oc rsync ./htdocs/ nginx-786bf7bf7b-9tlnn:/var/www/html/htdocs/ 
      ```

      Optionally if you wanted to get clever and use [Go templating](http://golang.org/pkg/text/template/#pkg-overview) to one line it:

      ```console
      oc rsync ./htdocs/ $(oc get pods -l deployment=php  --template='{{range .items}}{{.metadata.name}}{{end}}'):/opt/app/htdocs
      oc rsync ./htdocs/ $(oc get pods -l deployment=nginx  --template='{{range .items}}{{.metadata.name}}{{end}}'):/var/www/html/htdocs/ 
      ```

17. Find the route name for nginx

    ```console
    oc get route nginx
    ```

    Now if you want to get *really* clever you can use [Go templating](http://golang.org/pkg/text/template/#pkg-overview) and get just the URL:

    ```console
    oc get route nginx --template={{.spec.host}}
    ```

18. Use curl to confirm it's deployed

    ```console
    curl nginx-druptest.apps.cluster-swzqb.swzqb.sandbox1915.opentlc.com
    ```

    Or we can use the cleverness of GO templating we just learned in the prior step and linux bash command nesting to single line the two steps:

    ```console
    curl $(oc get route nginx --template={{.spec.host}})
    ```

19. Lastly to delete and undo what we've done delete the project

    ```console
    oc delete project druptest
    ```

## Build via Pipelines

1.  Install the OpenShift Pipelines operator as outlined in the [official docs](https://docs.openshift.com/pipelines/1.15/install_config/installing-pipelines.html#installing-pipelines)  Accept the default settings.

2.  Login to OpenShift via command line

    ```console
    oc login ...
    ```

3.  Create a project to contain this

    ```console
    oc new-project druptest
    ```

4.  Switch to the project (the create command will do this by default)

    ```console
    oc project druptest
    ```

5.  Create two new tasks from updating your kubernetes objects and then updating the application deployment to redeploy after a new image build:

    ```console
    oc create -f ./tekton/apply_manifest_task.yaml -n druptest

    oc create -f ./tekton/update_deployment_task.yaml -n druptest
    ```

6.  Create the pipeline

    ```console
    oc create -f ./tekton/pipeline.yaml -n druptest
    ```

7.  Once you're done experimenting, feel free to delete the project.

    ```console
    oc delete project druptest
    ```

## References

* [OpenShift Container Platform Documentation: Images: Creating Images](https://github.com/openshift/source-to-image)
* [OpenShift Origin GitHub: Source-To-Image](https://docs.openshift.com/container-platform/4.14/openshift_images/create-images.html#images-create-guidelines_create-images)
* [OpenShift Docker/Container Build Examples](https://github.com/openshift-examples/container-build)
* [OpenShift Pipelines Tutorial](https://github.com/openshift/pipelines-tutorial)