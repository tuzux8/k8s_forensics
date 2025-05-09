#!/bin/bash
#
# k8s-ContainerTriageCollection v0.1
#
# @author:    Kerstin Schmid
# @copyright: Copyright (c) 2024. All rights reserved.
# @date:	  2024-05-10
#
#
# Dependencies:
#
# tar 
#
# Changelog:
# Version 1.1
# Release Date: 2024-06-28
# Added kubectl commands
#
#######################################################################

# DESCRIPTION
# k8s-ContainerTriageCollection is a bash script to gather triage data about k8s resources on a target system.

# Example: ./k8s-ContainerTriageCollection

#######################################################################

# Header
echo "Script to gather triage data about k8s resources like pods and services on the target system v1.0"
echo "(c) 2024"
echo ""
echo ""
echo ""
echo "[Info]  Start Acquisition..."
echo ""

# Declarations
# Current working dir
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Set Timestamp
TIMESTAMP=$(date '+%F_%H-%M-%S') # YYYY-MM-DD_hh-mm-ss
TIMESTAMPVISUAL=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
START_TIME=$SECONDS

# Path to Tools

# Variablen
OUTPUT_DIR="$SCRIPT_DIR"/Collection
LOGFILE=$OUTPUT_DIR/collection-log-$TIMESTAMP.txt

#######################################################################

# Create Log File

# Create Output dir
mkdir -p "$OUTPUT_DIR"

# Header
echo "k8s-ContainerTriageCollection - script to gather triage data about k8s pods on a target system" >> $LOGFILE
echo "(c) 2024" >> $LOGFILE
echo "" >> $LOGFILE

# Execution time
echo "Execution time: $TIMESTAMPVISUAL" >> $LOGFILE
echo "Evidence storage location: $OUTPUT_DIR" >> $LOGFILE
echo ""

#######################################################################

# Check kubectl is installed
if ! [ -x "$(command -v kubectl)" ]
then
    echo "[Error] kubectl does not appear to be installed." 1>&2
    echo "[Error] kubectl does not appear to be installed." >> $LOGFILE
    exit 1
else
    echo -e "[Info] Collection commenced at $(date -u).\n\n" >> $LOGFILE
fi

# Set current namespace to default
kubectl config set-context --current --namespace=default 1>&2

# Host data
echo "[Info] Collecting cluster info"
echo -e " " >> $LOGFILE
echo -e "[Info] Collecting cluster info" >> $LOGFILE
echo "**********************************************************" >> $OUTPUT_DIR/cluster_metadata.txt
echo -e "\C VERSION\n" >> $OUTPUT_DIR/cluster_metadata.txt
echo -e "**********************************************************" >> $OUTPUT_DIR/cluster_metadata.txt
kubectl version >> $OUTPUT_DIR/cluster_metadata.txt
echo "k8s version data collected and stored in $OUTPUT_DIR/cluster_metadata.txt" >> $LOGFILE
echo -e "\n\n**********************************************************" >> $OUTPUT_DIR/cluster_metadata.txt
echo -e "\nK8S CLUSTER INFO\n" >> $OUTPUT_DIR/cluster_metadata.txt
echo "**********************************************************" >> $OUTPUT_DIR/cluster_metadata.txt
kubectl cluster-info >> $OUTPUT_DIR/cluster_metadata.txt
echo "**********************************************************" >> $OUTPUT_DIR/cluster_metadata.txt
echo "K8s cluster information collected and stored in $OUTPUT_DIR/cluster_metadata.txt" >> $LOGFILE
echo -e "# File hash: $(md5 $OUTPUT_DIR/cluster_metadata.txt). \n" >> $LOGFILE

# Services
echo "[Info] Gathering list of available services (all namespaces)"
echo -e " " >> $LOGFILE
echo -e "[Info] Gathering list of available services (all namespaces)" >> $LOGFILE
kubectl get services --all-namespaces > $OUTPUT_DIR/k8s_services.txt
echo "Get services output stored to $OUTPUT_DIR/k8s_services.txt" >> $LOGFILE
echo "# File hash: $(md5 $OUTPUT_DIR/k8s_services.txt)" >> $LOGFILE

# Collect data per available namespace
echo "[Info] Gathering list of available namespaces"
echo -e " " >> $LOGFILE
echo -e "[Info] Gathering list of available namespaces" >> $LOGFILE
kubectl get namespaces > $OUTPUT_DIR/k8s_namespaces.txt
echo "Get namespaces output stored to $OUTPUT_DIR/k8s_namepsaces.txt" >> $LOGFILE
echo "# File hash: $(md5 $OUTPUT_DIR/k8s_namespaces.txt)" >> $LOGFILE

## Pod data
echo "[Info] Gathering information of namespace objects."
echo -e " " >> $LOGFILE
echo -e "[Info]  Gathering information of namespace objects." >> $LOGFILE
echo "Checking namespace data." >> $LOGFILE
TMPZ=$( kubectl get ns  --no-headers -o custom-columns=":metadata.name")
for i in $TMPZ
do
    NS=$(echo $i | cut -d: -f1)

    # exclude kube-system namespace
    if [[ $NS == "kube-system" ]]
    then
        echo -e "[Info] Namespace: $NS will be skipped ..." >> $LOGFILE
        echo -e "[Info] Namespace: $NS will be skipped ..."
        continue
    fi
    # Create NS Output dir
    OUTPUT_DIR_NS=$OUTPUT_DIR/$NS
    mkdir -p "$OUTPUT_DIR_NS"


    echo "NS: $NS " >> $OUTPUT_DIR_NS/ns_$NS.txt
    # Services
    echo " " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "Services: " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    kubectl get services --namespace=$NS >> $OUTPUT_DIR_NS/ns_$NS.txt 2>&1
    # Pods
    echo " " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "Pods: " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    kubectl get pods -o wide --namespace=$NS >> $OUTPUT_DIR_NS/ns_$NS.txt 2>&1

    # All images running in namespace: default, grouped by Pod
    echo " " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "Images: " >> $OUTPUT_DIR_NS/ns_$NS.txt
    echo "------------------------- " >> $OUTPUT_DIR_NS/ns_$NS.txt
    kubectl get pods --namespace $NS --output=custom-columns="NAME:.metadata.name,IMAGE:.spec.containers[*].image" >> $OUTPUT_DIR_NS/ns_$NS.txt 2>&1

    echo -e " " >> $LOGFILE
    echo -e "[Info] Namespace: $NS" >> $LOGFILE
    echo "Get objects of namespace $NS stored to $OUTPUT_DIR_NS/ns_$NS.txt" >> $LOGFILE
    echo "# File hash: $(md5 $OUTPUT_DIR_NS/ns_$NS.txt)" >> $LOGFILE

    ## Interact with running Pods
    # Produce ENV for all pods, assuming you have a default container for the pods, default namespace and the `env` command is supported.
    # Helpful when running any supported command across all pods, not just `env`
    echo "[Info] Gathering information of running pods within the namespace: $NS."
    PODS=$( kubectl get pod -n=$NS --output=jsonpath={.items..metadata.name} )
    for pod in $PODS
    do 
        echo "Pod: $pod " > $OUTPUT_DIR_NS/pod_$pod.txt 2>&1

        # General information of a pod
        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "General information: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        kubectl get pod $pod -n=$NS >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1

        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "Describe pod: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        kubectl describe pod $pod -n=$NS >> $OUTPUT_DIR_NS/pod_$pod.txt  2>&1

        # Environment Variables
        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "-------------------------: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "Environment variable: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        kubectl exec -it $pod -n $NS -- env >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1

        # Containers
        CONTAINERS=$( kubectl get pods $pod -n=$NS -o jsonpath='{.spec.containers[*].name}' )
        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "-------------------------: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "Containers: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo $CONTAINERS >> $OUTPUT_DIR_NS/pod_$pod.txt

        # Logs
        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "-------------------------: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "Logs: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        kubectl logs $pod -n $NS >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1

        # Logs of containers
        for container in $CONTAINERS
        do
            echo "Pod: $pod " > $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "Container: $container " >> $OUTPUT_DIR_NS/container_$pod_$container.txt

            # Logs
            echo " " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "-------------------------: " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "Logs: " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "------------------------- " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            kubectl logs $pod -c $container -n=$NS >> $OUTPUT_DIR_NS/container_$pod_$container.txt

            echo " " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "-------------------------: " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "Environment variable: " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            echo "------------------------- " >> $OUTPUT_DIR_NS/container_$pod_$container.txt
            kubectl exec -it $pod -c $container -n $NS -- env >> $OUTPUT_DIR_NS/container_$pod_$container.txt 2>&1

            echo "Get information of container $container stored to $OUTPUT_DIR_NS/container_$pod_$container.txt" >> $LOGFILE
            echo "# File hash: $(md5 $OUTPUT_DIR_NS/container_$pod_$container.txt)" >> $LOGFILE
        done

        # Metrics of a pod
        echo " " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "-------------------------: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "Metrics: " >> $OUTPUT_DIR_NS/pod_$pod.txt
        echo "------------------------- " >> $OUTPUT_DIR_NS/pod_$pod.txt
        kubectl top pod $pod -n $NS --containers >> $OUTPUT_DIR_NS/pod_$pod.txt 2>&1

        echo "Get information of pod $pod stored to $OUTPUT_DIR_NS/pod_$pod.txt" >> $LOGFILE
        echo "# File hash: $(md5 $OUTPUT_DIR_NS/pod_$pod.txt)" >> $LOGFILE
    done
done

echo -e " " >> $LOGFILE
echo -e "[Info]  Triage collection completed at $(date -u)" >> $LOGFILE


# Create Archive file
echo "[Info] Create archive file of results ... "

if tar --help | grep -q "Options:" > /dev/null
then
	tar -cf "$TIMESTAMP"_kubernetes_collections.tar "$OUTPUT_DIR" > /dev/null 2> /dev/null
	sudo rm -R  $OUTPUT_DIR/* 2> /dev/null
    mv "$TIMESTAMP"_kubernetes_collections.tar $OUTPUT_DIR
	md5 "$OUTPUT_DIR/$TIMESTAMP"_kubernetes_collections.tar | awk '{print $1}' > "$TIMESTAMP"_kubernetes_collections.tar-md5.txt
    mv "$TIMESTAMP"_kubernetes_collections.tar-md5.txt $OUTPUT_DIR
	echo "[Info]  "$OUTPUT_DIR/$TIMESTAMP"_kubernetes_collections.tar successfully created ... "
	# Archive File Size
	BYTES=$(ls -l "$OUTPUT_DIR/$TIMESTAMP"_kubernetes_collections.tar | awk '{print $5}')
	FILESIZE=$(echo "$BYTES" | awk '{ split( "Bytes KB MB GB TB" , v ); s=1; while( $1>1000 ){ $1/=1000; s++ } printf "%.1f %s", $1, v[s] }')
	echo "[Info]  Total Archive Size: $FILESIZE"
else
	echo "[Info]  Tar not found. Creation of archive file will be skipped ..."
fi

#######################################################################

echo ""
echo "[Info] Collection completed."
echo "Log file: $LOGFILE"
echo "MD5 Hash of "$TIMESTAMP"_kubernetes_collections.tar: $(md5 "$OUTPUT_DIR/$TIMESTAMP"_kubernetes_collections.tar | awk '{print $1}')"

exit
