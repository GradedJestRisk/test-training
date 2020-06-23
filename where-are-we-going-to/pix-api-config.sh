#!/bin/zsh

REPOSITORY_PATH=/home/topi/Documents/OCTO/Missions/Pix/code/repo/pix/api
BRANCH_NAME=dev

LOG_FILE_PATH=/home/topi/Documents/IT/test/where-are-we-going-to/log-api.txt

declare -a directories=("lib" "tests/unit" "tests/integration" "tests/acceptance")

## Test
#declare -a commit_dates=(\
#"2020-02-03" "2020-01-02" \
#)

## PG 10 only => use without docker-compose
declare -a commit_dates=(\
"2020-02-03" "2020-01-02" \
"2019-12-02" "2019-11-01" "2019-10-01" "2019-09-02" "2019-08-02" "2019-07-02" "2019-06-03" "2019-05-02" "2019-04-01" "2019-03-01" "2019-02-01" "2019-02-01" \
"2018-12-03" "2018-11-02" "2018-10-01" "2018-09-03" "2018-08-02" "2018-07-10" "2018-06-01" "2018-05-02" "2018-04-03" "2018-03-01" "2018-02-01" "2018-01-31" \
"2017-12-01" "2017-11-02" "2017-10-02" "2017-09-02" "2017-08-02" "2017-07-03" "2017-06-01" "2017-05-02" "2017-04-03" "2017-03-01" "2017-02-02" "2017-01-03"\
)

# PG 10/11/12
# https://github.com/docker-library/postgres/issues/681
# https://stackoverflow.com/questions/49293967/how-to-pass-environment-variable-to-docker-compose-up
# won't work if POSTGRES_HOST_AUTH_METHOD is not declared in docker-compose.yml
#  environment:
#    POSTGRES_DB: "DB"
#    POSTGRES_HOST_AUTH_METHOD: ${POSTGRES_HOST_AUTH_METHOD}
#(POSTGRES_HOST_AUTH_METHOD=trust docker-compose up -d)
#declare -a commit_dates=(\
#"2020-06-02" "2020-05-04" "2020-04-01" "2020-03-02" "2020-02-03" "2020-01-02" \
#"2019-12-02" "2019-11-01" "2019-10-01" "2019-09-02" "2019-08-02" "2019-07-02" "2019-06-03" "2019-05-02" "2019-04-01" "2019-03-01" "2019-02-01" "2019-02-01" \
#"2018-12-03" "2018-11-02" "2018-10-01" "2018-09-03" "2018-08-02" "2018-07-10" "2018-06-01" "2018-05-02" "2018-04-03" "2018-03-01" "2018-02-01" "2018-01-31" \
#"2017-12-01" "2017-11-02" "2017-10-02" "2017-09-02" "2017-08-02" "2017-07-03" "2017-06-01" "2017-05-02" "2017-04-03" "2017-03-01" "2017-02-02" "2017-01-03"\
#)

#declare -a commit_dates=(\
#"2020-06-02" "2020-05-04"
#)
EXECUTE_TEST(){
   NODE_ENV=test npm run db:prepare && npx mocha --recursive --exit --reporter dot tests --timeout 10000
}

IS_SELF_SUPPORTING_ENVIRONMENT=false

# https://unix.stackexchange.com/questions/444946/how-can-we-run-a-command-stored-in-a-variable
RESTART_EXTERNAL_SERVICE() {
   cd /home/topi/Documents/OCTO/Missions/Pix/code/env;
   ./restart.sh;
}
# checking port status give non-deterministic result  (while ! nc -z localhost 5432; do sleep 1; done;)
  # => going back to actual DB client connection
IS_EXTERNAL_SERVICE_UP="psql postgresql://postgres@localhost:5432/pix -c 'select current_database()'"
EXTERNAL_SERVICE_STARTUP_INTERVAL=1
EXTERNAL_SERVICE_STARTUP_TIMEOUT=10