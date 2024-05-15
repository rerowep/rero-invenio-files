#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# RERO-Invenio-Files
# Copyright (C) 2024 RERO.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


# Usage:
#   env DB=postgresql12 SEARCH=elasticsearch7 CACHE=redis MQ=rabbitmq ./run-tests.sh

# Quit on errors
set -o errexit

# Quit on unbound symbols
set -o nounset

# Always bring down docker services
function cleanup() {
    eval "$(docker-services-cli down --env)"
}
trap cleanup EXIT

# python -m check_manifest
python -m sphinx.cmd.build -qnNW docs docs/_build/html

safety_exceptions="-i 51668 -i 42194 -i 62019 -i 67599 -i 51457"
msg=$(safety check -o text ${safety_exceptions}) || {
    echo "Safety vulnerabilites found for packages:" $(safety check -o bare ${safety_exceptions})
    echo "Run: \"safety check -o screen ${safety_exceptions} | grep -i vulnerability\" for more details"
    exit 1
  }

autoflake -r --remove-all-unused-imports --ignore-init-module-imports --quiet .

# TODO: Remove services below that are not neeed (fix also the usage note).
eval "$(docker-services-cli up --db ${DB:-postgresql} --search ${SEARCH:-elasticsearch} --cache ${CACHE:-redis} --mq ${MQ:-rabbitmq} --env)"
python -m pytest
tests_exit_code=$?
python -m sphinx.cmd.build -qnNW -b doctest docs docs/_build/doctest
exit "$tests_exit_code"
