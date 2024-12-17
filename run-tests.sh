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

# -> Vulnerability found in py version 1.11.0
#    Vulnerability ID: 51457
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 51457 in safety’s
# -> Vulnerability found in pip version 22.3.1
#    Vulnerability ID: 62044
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 62044 in safety’s
# -> Vulnerability found in sqlalchemy-utils version 0.41.2
#    Vulnerability ID: 42194
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 42194 in safety’s
# -> Vulnerability found in flask-cors version 5.0.0
#    Vulnerability ID: 70624
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 70624 in safety’s
# -> Vulnerability found in flask-cors version 5.0.0
#    Vulnerability ID: 72731
#    ADVISORY: A vulnerability in corydolphin/flask-cors allows the
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 72731 in safety’s
# -> Vulnerability found in flask-caching version 2.3.0
#    Vulnerability ID: 40459
#    For more information about this vulnerability, visit
#    To ignore this vulnerability, use PyUp vulnerability id 40459 in safety’s
safety_exceptions="-i 51457 -i 62044 -i 42194 -i 70624 -i 72731 -i 40459"
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
