#!/bin/bash

# WARNING: DO NOT EDIT!
#
# This file was generated by plugin_template, and is managed by it. Please use
# './plugin-template --github pulp_rpm' to update this file.
#
# For more info visit https://github.com/pulp/plugin_template

# make sure this script runs at the repo root
cd "$(dirname "$(realpath -e "$0")")"/../../..

set -euv

export response=$(curl --write-out %{http_code} --silent --output /dev/null https://pypi.org/project/pulp-rpm/$1/)
if [ "$response" == "200" ];
then
  echo "pulp_rpm $1 has already been released. Skipping."
  exit
fi

pip install twine

twine check dist/pulp_rpm-$1-py3-none-any.whl || exit 1
twine check dist/pulp-rpm-$1.tar.gz || exit 1
twine upload dist/pulp_rpm-$1-py3-none-any.whl -u pulp -p $PYPI_PASSWORD
twine upload dist/pulp-rpm-$1.tar.gz -u pulp -p $PYPI_PASSWORD

exit $?
