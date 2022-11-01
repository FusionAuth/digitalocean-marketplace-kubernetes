#!/bin/sh

#Todo - encrypt password
#https://www.linuxtechi.com/encrypted-password-bash-shell-script/
#https://www.howtogeek.com/734838/how-to-use-encrypted-passwords-in-bash-scripts/
# https://itnext.io/manage-auto-generated-secrets-in-your-helm-charts-5aee48ba6918
#https://phoenixnap.com/kb/kubernetes-secrets#:~:text=What%20Are%20Kubernetes%20Secrets%3F,it%20available%20to%20a%20pod.
set -e

################################################################################
# repo
################################################################################


################################################################################
# chart
################################################################################
STACK="fusionauth"
CHART="fusionauth/fusionauth"
CHART_VERSION="0.10.10"
NAMESPACE="fusionauth"
password="5s68p86syNe8Zux$"

get_values () {
  if [ -z "${MP_KUBERNETES}" ]; then
    # use local version of values.yml
    ROOT_DIR=$(git rev-parse --show-toplevel)
    values="$ROOT_DIR/stacks/fusionauth/values.yml"
  else
    # use github hosted master version of values.yml
    values="https://raw.githubusercontent.com/digitalocean/marketplace-kubernetes/master/stacks/fusionauth/values.yml"
  fi
}

update_repos (){
  helm repo add stable https://charts.helm.sh/stable
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo add fusionauth https://fusionauth.github.io/charts
  helm repo update > /dev/null
}

install_postgres_elastic_search(){
  # helm install release_name repository/chart_name
  helm install my-es-release bitnami/elasticsearch --create-namespace --namespace "$NAMESPACE" -f elastic-search-values.yaml
  helm install my-postgres-release bitnami/postgresql  --set auth.username=fusionauth --set auth.password="$password" --set auth.database=fusionauth --set image.debug=true --namespace "$NAMESPACE"
}

expose_app(){
    export SVC_NAME=$(kubectl get svc --namespace fusionauth -l "app.kubernetes.io/name=fusionauth,app.kubernetes.io/instance=fusionauth" -o jsonpath="{.items[0].metadata.name}")
    kubectl port-forward svc/$SVC_NAME 9011:9011 -n fusionauth
}

get_values
update_repos
install_postgres_elastic_search
expose_app

helm upgrade "$STACK" "$CHART" \
  --atomic \
  --install \
  --timeout 8m0s \
  --namespace "$NAMESPACE" \
  --values "$values" \
  --version "$CHART_VERSION" \
  --set database.host=my-postgres-release-postgresql.fusionauth.svc.cluster.local  \
  --set search.host=my-es-release-elasticsearch.fusionauth.svc.cluster.local  \
  --set database.user=fusionauth \
  --set database.password="$password"