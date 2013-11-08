# Description:
#   Interact with your Jenkins CI server
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_AUTH
#
# Commands:
#   hubot jenkins build <job> - builds the specified Jenkins job
#   hubot jenkins build <job>, <params> - builds the specified Jenkins job with parameters as key=value&key2=value2
#   hubot jenkins deploy <environment> <branch> - deploys the specified Tracelons branch to the specified environment
#   hubot jenkins describe <job> - Describes the specified Jenkins job
#   hubot jenkins list <filter> - lists Jenkins jobs

#
# Author:
#   dougcole

querystring = require 'querystring'

jenkinsBuild = (msg) ->
    job = querystring.escape msg.match[1]
    params = msg.match[3]
    _jenkinsBuild(msg, job, params)

_jenkinsBuild = (msg, job, params) ->
    url = process.env.HUBOT_JENKINS_URL
    path = if params then "#{url}/job/#{job}/buildWithParameters?#{params}" else "#{url}/job/#{job}/build"

    req = msg.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
        if err
          msg.send "Jenkins says: #{err}"
        else if res.statusCode == 302
          msg.send "Build started for #{job} #{res.headers.location}"
        else
          msg.send "Jenkins says: #{body}"

jenkinsDescribe = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    job = msg.match[1]

    path = "#{url}/job/#{job}/api/json"

    req = msg.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.get() (err, res, body) ->
        if err
          msg.send "Jenkins says: #{err}"
        else
          response = ""
          try
            content = JSON.parse(body)
            response += "JOB: #{content.displayName}\n"

            if content.description
              response += "DESCRIPTION: #{content.description}\n"

            response += "ENABLED: #{content.buildable}\n"
            response += "STATUS: #{content.color}\n"

            tmpReport = ""
            if content.healthReport.length > 0
              for report in content.healthReport
                tmpReport += "\n  #{report.description}"
            else
              tmpReport = " unknown"
            response += "HEALTH: #{tmpReport}\n"

            parameters = ""
            for item in content.actions
              if item.parameterDefinitions
                for param in item.parameterDefinitions
                  tmpDescription = if param.description then " - #{param.description} " else ""
                  tmpDefault = if param.defaultParameterValue then " (default=#{param.defaultParameterValue.value})" else ""
                  parameters += "\n  #{param.name}#{tmpDescription}#{tmpDefault}"

            if parameters != ""
              response += "PARAMETERS: #{parameters}\n"

            msg.send response

            if not content.lastBuild
              return

            path = "#{content.lastBuild.url}/api/json"
            req = msg.http(path)
            if process.env.HUBOT_JENKINS_AUTH
              auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
              req.headers Authorization: "Basic #{auth}"

            req.header('Content-Length', 0)
            req.get() (err, res, body) ->
                if err
                  msg.send "Jenkins says: #{err}"
                else
                  response = ""
                  try
                    content = JSON.parse(body)
                    console.log(JSON.stringify(content, null, 4))
                    jobstatus = content.result || 'PENDING'
                    jobdate = new Date(content.timestamp);
                    response += "LAST JOB: #{jobstatus}, #{jobdate}\n"

                    msg.send response
                  catch error
                    msg.send error

          catch error
            msg.send error

jenkinsList = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    filter = new RegExp(msg.match[2], 'i')
    req = msg.http("#{url}/api/json")

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.get() (err, res, body) ->
        response = ""
        if err
          msg.send "Jenkins says: #{err}"
        else
          try
            content = JSON.parse(body)
            for job in content.jobs
              state = if job.color == "red" then "FAIL" else "PASS"
              if filter.test job.name
                response += "#{state} #{job.name}\n"
            msg.send response
          catch error
            msg.send error

jenkinsDeploy = (msg) ->
    env2job =
        labs: 'deploy-labs'

    environment = querystring.escape msg.match[1]
    branch = querystring.escape msg.match[2]

    if environment not in env2job
        msg.send "Invalid environment: #{environment}"
        msg.send "Valid choices are: #{(key for key of env2job)}"
        return

    job = env2job[environment]
    params = "BRANCH=#{branch}"

    _jenkinsBuild(msg, job, params)

module.exports = (robot) ->
  robot.respond /jenkins deploy ([\w\.\-_]+) (.+)?/i, (msg) ->
    jenkinsDeploy(msg)

  robot.respond /jenkins build ([\w\.\-_]+)(,?\s+(.+))?/i, (msg) ->
    jenkinsBuild(msg)

  robot.respond /jenkins list( (.+))?/i, (msg) ->
    jenkinsList(msg)

  robot.respond /jenkins describe (.*)/i, (msg) ->
    jenkinsDescribe(msg)

  robot.jenkins = {
    list: jenkinsList,
    build: jenkinsBuild
  }
