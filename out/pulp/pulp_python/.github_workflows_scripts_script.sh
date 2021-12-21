#!/usr/bin/env bash
# coding=utf-8

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_python' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")"/../../..
REPO_ROOT="$PWD"

set -mveuo pipefail

source .github/workflows/scripts/utils.sh

export POST_SCRIPT=$PWD/.github/workflows/scripts/post_script.sh
export POST_DOCS_TEST=$PWD/.github/workflows/scripts/post_docs_test.sh
export FUNC_TEST_SCRIPT=$PWD/.github/workflows/scripts/func_test_script.sh

# Needed for both starting the service and building the docs.
# Gets set in .github/settings.yml, but doesn't seem to inherited by
# this script.
export DJANGO_SETTINGS_MODULE=pulpcore.app.settings
export PULP_SETTINGS=$PWD/.ci/ansible/settings/settings.py

export PULP_URL="https://pulp"

if [[ "$TEST" = "docs" ]]; then
  cd docs
  make PULP_URL="$PULP_URL" diagrams html
  tar -cvf docs.tar ./_build
  cd ..

  echo "Validating OpenAPI schema..."
  cat $PWD/.ci/scripts/schema.py | cmd_stdin_prefix bash -c "cat > /tmp/schema.py"
  cmd_prefix bash -c "python3 /tmp/schema.py"
  cmd_prefix bash -c "pulpcore-manager spectacular --file pulp_schema.yml --validate"

  if [ -f $POST_DOCS_TEST ]; then
    source $POST_DOCS_TEST
  fi
  exit
fi

if [[ "${RELEASE_WORKFLOW:-false}" == "true" ]]; then
  REPORTED_VERSION=$(http $PULP_URL/pulp/api/v3/status/ | jq --arg plugin python --arg legacy_plugin pulp_python -r '.versions[] | select(.component == $plugin or .component == $legacy_plugin) | .version')
  response=$(curl --write-out %{http_code} --silent --output /dev/null https://pypi.org/project/pulp-python/$REPORTED_VERSION/)
  if [ "$response" == "200" ];
  then
    echo "pulp_python $REPORTED_VERSION has already been released. Skipping running tests."
    exit
  fi
fi

if [[ "$TEST" == "plugin-from-pypi" ]]; then
  COMPONENT_VERSION=$(http https://pypi.org/pypi/pulp-python/json | jq -r '.info.version')
  git checkout ${COMPONENT_VERSION} -- pulp_python/tests/
fi

cd ../pulp-openapi-generator
./generate.sh pulpcore python
pip install ./pulpcore-client
rm -rf ./pulpcore-client
if [[ "$TEST" = 'bindings' ]]; then
  ./generate.sh pulpcore ruby 0
  cd pulpcore-client
  gem build pulpcore_client.gemspec
  gem install --both ./pulpcore_client-0.gem
fi
cd $REPO_ROOT

if [[ "$TEST" = 'bindings' ]]; then
  if [ -f $REPO_ROOT/.ci/assets/bindings/test_bindings.py ]; then
    python $REPO_ROOT/.ci/assets/bindings/test_bindings.py
  fi
  if [ -f $REPO_ROOT/.ci/assets/bindings/test_bindings.rb ]; then
    ruby $REPO_ROOT/.ci/assets/bindings/test_bindings.rb
  fi
  exit
fi

cat unittest_requirements.txt | cmd_stdin_prefix bash -c "cat > /tmp/unittest_requirements.txt"
cmd_prefix pip3 install -r /tmp/unittest_requirements.txt

# check for any uncommitted migrations
echo "Checking for uncommitted migrations..."
cmd_prefix bash -c "django-admin makemigrations --check --dry-run"

if [[ "$TEST" != "upgrade" ]]; then
  # Run unit tests.
  cmd_prefix bash -c "PULP_DATABASES__default__USER=postgres django-admin test --noinput /usr/local/lib/python3.8/site-packages/pulp_python/tests/unit/"
fi

# Run functional tests
export PYTHONPATH=$REPO_ROOT/../pulpcore${PYTHONPATH:+:${PYTHONPATH}}
export PYTHONPATH=$REPO_ROOT${PYTHONPATH:+:${PYTHONPATH}}


if [[ "$TEST" == "upgrade" ]]; then
  # Handle app label change:
  sed -i "/require_pulp_plugins(/d" pulp_python/tests/functional/utils.py

  # Running pre upgrade tests:
  pytest -v -r sx --color=yes --pyargs --capture=no pulp_python.tests.upgrade.pre

  # Checking out ci_upgrade_test branch and upgrading plugins
  cmd_prefix bash -c "cd pulpcore; git checkout -f ci_upgrade_test; pip install --upgrade --force-reinstall ."
  cmd_prefix bash -c "cd pulp_python; git checkout -f ci_upgrade_test; pip install ."

  # Migrating
  cmd_prefix bash -c "django-admin migrate --no-input"

  # Restarting single container services
  cmd_prefix bash -c "s6-svc -r /var/run/s6/services/pulpcore-api"
  cmd_prefix bash -c "s6-svc -r /var/run/s6/services/pulpcore-content"
  cmd_prefix bash -c "s6-svc -d /var/run/s6/services/pulpcore-resource-manager"
  cmd_prefix bash -c "s6-svc -d /var/run/s6/services/pulpcore-worker@1"
  cmd_prefix bash -c "s6-svc -d /var/run/s6/services/pulpcore-worker@2"
  cmd_prefix bash -c "s6-svc -u /var/run/s6/services/new-pulpcore-resource-manager"
  cmd_prefix bash -c "s6-svc -u /var/run/s6/services/new-pulpcore-worker@1"
  cmd_prefix bash -c "s6-svc -u /var/run/s6/services/new-pulpcore-worker@2"

  echo "Restarting in 60 seconds"
  sleep 60

  # CLI commands to display plugin versions and content data
  pulp status
  pulp content list
  CONTENT_LENGTH=$(pulp content list | jq length)
  if [[ "$CONTENT_LENGTH" == "0" ]]; then
    echo "Empty content list"
    exit 1
  fi

  # Rebuilding bindings
  cd ../pulp-openapi-generator
  ./generate.sh pulpcore python
  pip install ./pulpcore-client
  ./generate.sh pulp_python python
  pip install ./pulp_python-client
  cd $REPO_ROOT

  # Running post upgrade tests
  git checkout ci_upgrade_test -- pulp_python/tests/
  pytest -v -r sx --color=yes --pyargs --capture=no pulp_python.tests.upgrade.post
  exit
fi


if [[ "$TEST" == "performance" ]]; then
  if [[ -z ${PERFORMANCE_TEST+x} ]]; then
    pytest -vv -r sx --color=yes --pyargs --capture=no --durations=0 pulp_python.tests.performance
  else
    pytest -vv -r sx --color=yes --pyargs --capture=no --durations=0 pulp_python.tests.performance.test_$PERFORMANCE_TEST
  fi
  exit
fi

if [ -f $FUNC_TEST_SCRIPT ]; then
  source $FUNC_TEST_SCRIPT
else
    pytest -v -r sx --color=yes --pyargs pulp_python.tests.functional
fi

if [ -f $POST_SCRIPT ]; then
  source $POST_SCRIPT
fi