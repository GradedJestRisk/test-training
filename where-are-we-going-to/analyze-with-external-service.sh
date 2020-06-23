#!/bin/zsh

# Set up vnm
. ~/.nvm/nvm.sh

# Check parameters
CONFIGURATION_FILE=$1
if [ -z ${CONFIGURATION_FILE} ]; then
  echo "CONFIGURATION_FILE parameter is missing";
  echo "Try: ./analyze-with-external-service.sh my_repo.sh";
  exit 1;
fi;
echo $CONFIGURATION_FILE

# Exit early when undefined variable or command return error
#set -eu

# Set up configuration
source $CONFIGURATION_FILE

echo "Loading configuration from analyze-config.sh"

# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ -z ${REPOSITORY_PATH+x} ]; then echo "REPOSITORY_PATH is unset"; exit 1; fi;
if [ -z ${BRANCH_NAME+x} ]; then echo "BRANCH_NAME is unset"; exit 1; fi;
if [ -z ${LOG_FILE_PATH+x} ]; then echo "LOG_FILE_PATH is unset"; exit 1; fi;
if [ -z ${directories+x} ]; then echo "directories is unset"; exit 1; fi;
if [ -z ${commit_dates+x} ]; then echo "commit_dates is unset"; exit 1; fi;

if [ -z ${IS_SELF_SUPPORTING_ENVIRONMENT+x} ]; then echo "IS_SELF_SUPPORTING_ENVIRONMENT is unset"; exit 1; fi;
#if [ -z ${RESTART_EXTERNAL_SERVICE+x} ]; then echo "RESTART_EXTERNAL_SERVICE is unset"; exit 1; fi;
#if [ -z ${IS_EXTERNAL_SERVICE_UP+x} ]; then echo "IS_EXTERNAL_SERVICE_UP is unset"; exit 1; fi;
#if [ -z ${EXTERNAL_SERVICE_STARTUP_INTERVAL+x} ]; then echo "EXTERNAL_SERVICE_STARTUP_INTERVAL is unset"; exit 1; fi;
#if [ -z ${EXTERNAL_SERVICE_STARTUP_TIMEOUT+x} ]; then echo "EXTERNAL_SERVICE_STARTUP_TIMEOUT is unset"; exit 1; fi;

# Display introduction
now=$(date +"%T")

printf "\n\n\n ##########################################################" 2>&1 | tee -a $LOG_FILE_PATH
printf "\n $now analyzing $REPOSITORY_PATH" | tee -a $LOG_FILE_PATH
printf "\n saving raw data to $LOG_FILE_PATH"
printf "\n\n" | tee -a $LOG_FILE_PATH

# Start analyze

# Go to stable starting point
cd "$REPOSITORY_PATH"
git checkout $BRANCH_NAME --quiet

# Start external service

#RESTART_EXTERNAL_SERVICE()
(cd /home/topi/Documents/OCTO/Missions/Pix/code/env; ./restart.sh;)

# https://stackoverflow.com/questions/21982187/bash-loop-until-command-exit-status-equals-0
wait_cycle=0
#until $(IS_EXTERNAL_SERVICE_UP)
until  [ $wait_cycle -gt $EXTERNAL_SERVICE_STARTUP_TIMEOUT ]
do
    if psql postgresql://postgres@localhost:6432/pix_test -c 'select current_database()'; then
      #printf "\n external service has been reached"
      break;
    fi
    #printf "\n wait_cycle: $wait_cycle"

    #printf "\n external service unreachable, waiting $EXTERNAL_SERVICE_STARTUP_INTERVAL second(s).."
    sleep $EXTERNAL_SERVICE_STARTUP_INTERVAL
    (( wait_cycle=wait_cycle+1 ))

done

if  [ $wait_cycle -gt $EXTERNAL_SERVICE_STARTUP_TIMEOUT ]; then
  printf "\n timeout exceeded while trying to reach external service, exiting.."
  exit 1
fi;


# Display headers
printf "\n commit_date; sha;${directories[*]}; test execution time (s)" 2>&1 | tee -a $LOG_FILE_PATH
printf  "\n -----------------------------------------" 2>&1 | tee -a $LOG_FILE_PATH

for commit_date in ${commit_dates[@]}; do

   printf "\n" | tee -a $LOG_FILE_PATH

   commit_sha1=$(git log --after="$commit_date 00:00" --before="$commit_date 23:59" --pretty="%H" | tail -n 1 --quiet)
   printf "$commit_date;$commit_sha1;" | tee -a $LOG_FILE_PATH
   git -c advice.detachedHead=false checkout $commit_sha1 --quiet

  ########### Count file word count ############

  for directory in ${directories[@]}; do
     count=$((find ./$directory -name '*.js' -print0 2> /dev/null | xargs -0 cat ) | wc -w )
     #echo "$directory : $count"
     printf "$count;" 2>&1 | tee -a $LOG_FILE_PATH
  done

  ########### Setup environment ############

  # install node
  #node_actual_version=`node --version`
  #npm_actual_version=`npm --version`

  #echo "actual node version: $node_actual_version"
  #echo "actual npm version: $npm_actual_version"

  node_expected_version=`node --eval="process.stdout.write(require('./package.json').engines.node)"`
  #echo "node version from package.json: $node_expected_version "

#  if [ "$node_expected_version" = "12.14.1" ]; then
#    # nasty bug: $ nvm install 12.4.1 => #Version '12.4.1' not found - try `nvm ls-remote` to browse available versions.
#    node_expected_version="12.16.1"
#  fi

  #echo "node version to install by nvm: $node_expected_version "

  nvm install $node_expected_version #>/dev/null 2>&1

  #node_actual_version=`node --version`
  #npm_actual_version=`npm --version`

  #echo "actual node version (after install): $node_actual_version"
  #echo "actual npm version (after install): $npm_actual_version"

  #nvm use $node_version #>/dev/null 2>&1

  # install dependencies
  npm ci #>/dev/null 2>&1

  ########### Run tests ############

  test_start_time=`date +%s`

  #EXECUTE_TEST()
  # Default mocha timeout (2 s.) is not enough and cannot be set througth environment variable
  NODE_ENV=test npm run db:prepare
  NODE_ENV=test npx mocha --recursive --exit --reporter dot tests --timeout 10000

  test_end_time=`date +%s`
  test_duration=$((test_end_time - test_start_time))
  printf "$test_duration;" 2>&1 | tee -a $LOG_FILE_PATH

done

echo "\n #################################################" 2>&1 | tee -a $LOG_FILE_PATH

# Restore branch to last commit
git checkout $BRANCH_NAME --quiet

exit 0