#!/usr/bin/env bash

set -eu

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
src_dir="${script_dir}/../../.."

"${src_dir}/bosh-src/ci/docker/main-bosh-docker/start-bosh.sh"

source /tmp/local-bosh/director/env

bosh int /tmp/local-bosh/director/creds.yml --path /jumpbox_ssh/private_key > /tmp/jumpbox_ssh_key.pem
chmod 400 /tmp/jumpbox_ssh_key.pem

export BOSH_DIRECTOR_IP="10.245.0.3"

BOSH_BINARY_PATH=$(which bosh)
export BOSH_BINARY_PATH
export BOSH_RELEASE="${PWD}/bosh-src/src/spec/assets/dummy-release.tgz"
export BOSH_DIRECTOR_RELEASE_PATH="${PWD}/bosh-release"
DNS_RELEASE_PATH="$(realpath "$(find "${PWD}"/bosh-dns-release -maxdepth 1 -path '*.tgz')")"
export DNS_RELEASE_PATH
CANDIDATE_STEMCELL_TARBALL_PATH="$(realpath "${src_dir}"/stemcell/*.tgz)"
export CANDIDATE_STEMCELL_TARBALL_PATH
export BOSH_DEPLOYMENT_PATH="/usr/local/bosh-deployment"
export BOSH_DNS_ADDON_OPS_FILE_PATH="${BOSH_DEPLOYMENT_PATH}/experimental/dns-addon-with-api-certificates.yml"

export OUTER_BOSH_ENV_PATH="/tmp/local-bosh/director/env"

DOCKER_CERTS="$(bosh int /tmp/local-bosh/director/bosh-director.yml --path /instance_groups/0/properties/docker_cpi/docker/tls)"
export DOCKER_CERTS
DOCKER_HOST="$(bosh int /tmp/local-bosh/director/bosh-director.yml --path /instance_groups/name=bosh/properties/docker_cpi/docker/host)"
export DOCKER_HOST

apt-get update
apt-get install -y jq

RDS_MYSQL_EXTERNAL_DB_HOST="$(jq -r .aws_mysql_endpoint database-metadata/metadata | cut -d':' -f1)"
RDS_POSTGRES_EXTERNAL_DB_HOST="$(jq -r .aws_postgres_endpoint database-metadata/metadata | cut -d':' -f1)"
GCP_MYSQL_EXTERNAL_DB_HOST="$(jq -r .gcp_mysql_endpoint database-metadata/metadata)"
GCP_POSTGRES_EXTERNAL_DB_HOST="$(jq -r .gcp_postgres_endpoint database-metadata/metadata)"
GCP_MYSQL_EXTERNAL_DB_CA="$(jq -r .mysql_ca_cert gcp-ssl-config/gcp_mysql.yml)"
GCP_MYSQL_EXTERNAL_DB_CLIENT_CERTIFICATE="$(jq -r .mysql_client_cert gcp-ssl-config/gcp_mysql.yml)"
GCP_MYSQL_EXTERNAL_DB_CLIENT_PRIVATE_KEY="$(jq -r .mysql_client_key gcp-ssl-config/gcp_mysql.yml)"
GCP_POSTGRES_EXTERNAL_DB_CA="$(jq -r .postgres_ca_cert gcp-ssl-config/gcp_postgres.yml)"
GCP_POSTGRES_EXTERNAL_DB_CLIENT_CERTIFICATE="$(jq -r .postgres_client_cert gcp-ssl-config/gcp_postgres.yml)"
GCP_POSTGRES_EXTERNAL_DB_CLIENT_PRIVATE_KEY="$(jq -r .postgres_client_key gcp-ssl-config/gcp_postgres.yml)"

export RDS_MYSQL_EXTERNAL_DB_HOST
export RDS_POSTGRES_EXTERNAL_DB_HOST
export GCP_MYSQL_EXTERNAL_DB_HOST
export GCP_POSTGRES_EXTERNAL_DB_HOST
export GCP_MYSQL_EXTERNAL_DB_CA
export GCP_MYSQL_EXTERNAL_DB_CLIENT_CERTIFICATE
export GCP_MYSQL_EXTERNAL_DB_CLIENT_PRIVATE_KEY
export GCP_POSTGRES_EXTERNAL_DB_CA
export GCP_POSTGRES_EXTERNAL_DB_CLIENT_CERTIFICATE
export GCP_POSTGRES_EXTERNAL_DB_CLIENT_PRIVATE_KEY

function create_mysql() {
  echo 'Create MYSQL ============'
  hostname=$1
  username=$2
  export MYSQL_PWD=$3
  database_name=$4

  mysql -h ${hostname} -P 3306 --user=${username} -e "drop database ${database_name};"
  mysql -h ${hostname} -P 3306 --user=${username} -e "show databases;"
  mysql -h ${hostname} -P 3306 --user=${username} -e "create database ${database_name};"
  mysql -h ${hostname} -P 3306 --user=${username} -e "show databases;"
}

function create_postgres() {
  echo 'Create POSTGRES ============'
  hostname=$1
  username=$2
  export PGPASSWORD=$3
  database_name=$4

  # Assumption: we are deleting inner-bosh in AfterEach so all connection will be terminated,
  #             so we dont need to revoke connection
  dropdb -U ${username} -p 5432 -h ${hostname} ${database_name} || true
  psql -h ${hostname} -p 5432 -U ${username} -c '\l' | grep ${database_name}
  createdb -U ${username} -p 5432 -h ${hostname} ${database_name}
  psql -h ${hostname} -p 5432 -U ${username} -c '\l' | grep ${database_name}
}

echo 'Create RDS ============================'
create_mysql $RDS_MYSQL_EXTERNAL_DB_HOST $RDS_MYSQL_EXTERNAL_DB_USER $RDS_MYSQL_EXTERNAL_DB_PASSWORD $RDS_MYSQL_EXTERNAL_DB_NAME
create_postgres $RDS_POSTGRES_EXTERNAL_DB_HOST $RDS_POSTGRES_EXTERNAL_DB_USER $RDS_POSTGRES_EXTERNAL_DB_PASSWORD $RDS_POSTGRES_EXTERNAL_DB_NAME

echo 'Create GCP ============================'
create_mysql $GCP_MYSQL_EXTERNAL_DB_HOST $GCP_MYSQL_EXTERNAL_DB_USER $GCP_MYSQL_EXTERNAL_DB_PASSWORD $GCP_MYSQL_EXTERNAL_DB_NAME
create_postgres $GCP_POSTGRES_EXTERNAL_DB_HOST $GCP_POSTGRES_EXTERNAL_DB_USER $GCP_POSTGRES_EXTERNAL_DB_PASSWORD $GCP_POSTGRES_EXTERNAL_DB_NAME

cd bosh-src
scripts/test-brats
