# Goal #
Travel backward in a codebase to detect tendencies.

Figures are:
* ratio test code / production code (word count)
* test execution time / production code count

# Design #
In an attempt for a modular design, I tried to use some "inversion of control" in bash: 
specify which command to launched in an external configuration file (using `source`).

It didn't succeed, so configuration file are still a bit messy. 

# Use #

## Self-supporting ##
Steps:
    * create configuration file
    * run: `./analyze-self-supporting.sh <CONFIG_FILE>`, eg: `./analyze-self-supporting.sh mon-pix-config.sh`
    * check results, eg `log-mon-pix.txt`
    
## External service (eg. DB , or API ##
Steps:
    * create configuration file
    * run: `./analyze-with-external-service.sh <CONFIG_FILE>`, eg. `./analyze-with-external-service.sh pix-api-config.sh`
    * check results, eg `log-api.txt`