#! /bin/env bash

# Help
[[ ${1} == "--help" ]] && echo "Usage: $0 [--restart]" && exit 0

# Run restart process
if [[ ${1} != "" ]]; then
  if [[ ${1} == "--restart" ]]; then
    RUN_RESTART="true" 
  else
    echo "This parameter is strange, check it: ${}"
    exit 1
  fi
fi

###
### VARIABLES
###
SLEEP=10
KUBECTL="kubectl"

###
### CONFIRM CONTEXT
###
echo -e "\nConfirm your context: $(${KUBECTL} config current-context): [enter / ctrl+c]"
echo -e "~~~~~~~~~~~~~~~~~~~~~~~\n"

read

###
### RESTART ALL K8s SERVICES
###
echo -e "\n\n>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<"
echo ">>> RESTART ALL K8s SERVICES <<<"
echo ">>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<"
CONTROL_PLANE=$(${KUBECTL} get node -l node-role=master -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}')
for master in ${CONTROL_PLANE}; do
  echo "Master: ${master}"
  echo "~~~~~~~~~~~~~~~~~~~~~"
  CP_PODS=$(${KUBECTL} -n kube-system get pods --field-selector spec.nodeName=${master} -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}' | grep -E -- 'etcd|^kube-')

  for pod in ${CP_PODS}; do
    CP_RESTART="${KUBECTL} -n kube-system delete pod ${pod}"
    if [[ ${RUN_RESTART} == "true" ]]; then
      echo "  * [$(date '+%F %T')] Run command: ${CP_RESTART}"
      ${CP_RESTART} && echo
      sleep ${SLEEP}
    else
      echo "  * ${CP_RESTART}"
    fi
  done
  echo -e "~~~~~~~~~~~~~~~~~~~~~~~\n\n"
done

###
### RESTART ALL Deployments, ReplicaSets and DaemonSets
###
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ">>> RESTART ALL Deployments, StatefullSets and DaemonSets <<<"
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
for ns in $(${KUBECTL} get ns -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}'); do 
  # Check if in the namespace are PODs
  # PODS=$(${KUBECTL} -n ${ns} get pod -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}')
  # echo ">>> ${ns}: $PODS"
  # if [[ "${PODS}" != "" ]]; then
    # ns="ms"
    echo "Namespace: $ns"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    echo "  >> Deployments:"
    for deployment in $(${KUBECTL} -n $ns get deployments.apps -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}'); do
      DEPL_RESTART="${KUBECTL} -n ${ns} rollout restart deployments.apps ${deployment}"
      if [[ ${RUN_RESTART} == "true" ]]; then
        echo "     * [$(date '+%F %T')] Run command: ${DEPL_RESTART}"
        ${DEPL_RESTART} && echo
        sleep ${SLEEP}
      else
        echo "     * ${DEPL_RESTART}"
      fi
    done

    echo "  >> StatefulSets:"
    for rs in $(${KUBECTL} -n $ns get statefulset -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}'); do
      RS_RESTART="${KUBECTL} -n ${ns} rollout restart statefulset ${rs}"
      if [[ ${RUN_RESTART} == "true" ]]; then 
        echo "     * [$(date '+%F %T')] Run command: ${RS_RESTART}"
        ${RS_RESTART} && echo
        sleep ${SLEEP}
      else
        echo "     * ${RS_RESTART}"
      fi
    done
    
    echo "  >> DaemonSets:"
    for ds in $(${KUBECTL} -n $ns get daemonsets.apps -o jsonpath='{range .items[*]}{@.metadata.name}{"\n"}'); do
      DS_RESTART="${KUBECTL} -n ${ns} rollout restart daemonsets.apps ${ds}"
      if [[ ${RUN_RESTART} == "true" ]]; then
        echo "     * [$(date '+%F %T')] Run command: ${DS_RESTART}"
        ${DS_RESTART} && echo
        sleep ${SLEEP}
      else
        echo "     * ${DS_RESTART}"
      fi
    done
    echo -e "~~~~~~~~~~~~~~~~~~~~~~~\n\n"
done