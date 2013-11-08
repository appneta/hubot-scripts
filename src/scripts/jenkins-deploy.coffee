# Description:
#   Deploy with your Jenkins CI server
#
# Dependencies:
#   "querystring": ""
#
# Configuration:
#   None
#
# Commands:
#   hubot deploy <environment> <branch> - deploys the specified Tracelons branch to the specified environment
#
# Author:
#   danriti

querystring = require 'querystring'

jenkinsDeploy = (msg, robot) ->
    ENV_TO_JOBS =
        labs: 'deploy-labs'

    if not robot.jenkins and not robot.jenkins.build
        msg.send "Error: jenkins plugin not installed."
        return

    environment = querystring.escape msg.match[1]
    branch = querystring.escape msg.match[2]

    if not environment in ENV_TO_JOBS
        msg.send "Invalid environment: #{environment}"
        msg.send "Valid choices are: #{(key for key of env2job)}"
        return

    job = ENV_TO_JOBS[environment]
    params = "BRANCH=#{branch}"

    # monkeypatch the msg.match object
    msg.match[1] = job
    msg.match[3] = params

    robot.jenkins.build(msg)

module.exports = (robot) ->
    robot.respond /deploy ([\w\.\-_]+) (.+)?/i, (msg) ->
        jenkinsDeploy(msg, robot)
