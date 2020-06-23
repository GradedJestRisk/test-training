#!/bin/zsh

# Set up vnm
. ~/.nvm/nvm.sh

# Check parameters
CONFIGURATION_FILE=$1
if [ -z ${CONFIGURATION_FILE} ]; then
  echo "CONFIGURATION_FILE parameter is missing";
  echo "Try: ./analyze-self-supporting.sh my_repo.sh";
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

# Display headers
printf "\n commit_date (sha1) : ${directories[*]} - test execution time (s)" 2>&1 | tee -a $LOG_FILE_PATH
printf  "\n -----------------------------------------" 2>&1 | tee -a $LOG_FILE_PATH

for commit_date in ${commit_dates[@]}; do

   commit_sha1=$(git log --after="$commit_date 00:00" --before="$commit_date 23:59" --pretty="%H" | tail -n 1 --quiet)
   printf "\n $commit_date ($commit_sha1): " | tee -a $LOG_FILE_PATH
   git -c advice.detachedHead=false checkout --force $commit_sha1 --quiet

  ########### Count file word count ############

  for directory in ${directories[@]}; do
     count=$((find ./$directory -name '*.*' -print0 2> /dev/null | xargs -0 cat ) | wc -w )
     #echo "$directory : $count"
     printf " $count w." 2>&1 | tee -a $LOG_FILE_PATH
  done

  ########### Setup environment ############

  # install node
  node_actual_version=`node --version`
  npm_actual_version=`npm --version`

  echo "actual node version: $node_actual_version"
  echo "actual npm version: $npm_actual_version"

  node_expected_version=`node --eval "process.stdout.write(require('./package.json').engines.node)"`
  echo "node version from package.json: $node_expected_version "

#  if [ "$node_expected_version" = "12.14.1" ]; then
#    # nasty bug: $ nvm install 12.4.1 => #Version '12.4.1' not found - try `nvm ls-remote` to browse available versions.
#    node_expected_version="12.16.1"
#  fi

  echo "node version to install by nvm: $node_expected_version "

  nvm install $node_expected_version #>/dev/null 2>&1

  node_actual_version=`node --version`
  npm_actual_version=`npm --version`

  echo "actual node version (after install): $node_actual_version"
  echo "actual npm version (after install): $npm_actual_version"

  #nvm use $node_version #>/dev/null 2>&1

  # install dependencies
  npm install #>/dev/null 2>&1

  npm rebuild node-sass

  ########### Run tests ############

  test_start_time=`date +%s`

  npm test

  test_end_time=`date +%s`
  test_duration=$((test_end_time - test_start_time))
  printf " $test_duration s." 2>&1 | tee -a $LOG_FILE_PATH

  ########### Go to log next line  ############
  printf "\n" 2>&1 | tee -a $LOG_FILE_PATH

done

echo "\n #################################################" 2>&1 | tee -a $LOG_FILE_PATH

# Restore branch to last commit
git checkout --force $BRANCH_NAME --quiet

exit 0