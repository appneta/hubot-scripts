# Description:
#   Display latency information from TraceView applications.
#
# Dependencies:
#
# Configuration:
#   HUBOT_TV_ACCOUNTS
# 
# Commands:
#   hubot (traceview|tv) me <account> latency (for|in) <applications> - Return latency information for TraceView applications in an account
#
# Author:
#   Eronarn

module.exports = (robot) ->
  robot.respond /(traceview|tv) me (\w*) latency (for|in) (.*)/i, (msg) ->
    # Get app and account parameters.
    account = msg.match[2]
    apps = msg.match[4].split " "

    # Get TraceView credentials from Hubot's settings.
    accounts = JSON.parse process.env.HUBOT_TV_ACCOUNTS
    key = accounts[account]

    # Back out if the requested account doesn't exist.
    if not key
      msg.send "Sorry, but I don't have the key for '#{account}' yet!"
      return

    # Set up the querystring.
    query = {
      key: key
    }

    # Define time result formatter.
    format = (microseconds) ->
      (microseconds / 1000000).toFixed(3) + "s"

    latency = (app) ->
      # Fetch app latency from the TraceView API.
      robot.http("https://api.tv.appneta.com/api-v1/latency/"+app+"/server/summary")
        .query(query)
        .get() (err, res, body) -> 
          if err
            msg.send "#{app}: failed to load: #{err}"
            return

          # Get the data from the endpoint.
          result = JSON.parse body

          # Print application latency.
          msg.send "#{app}: #{format(result.data.average)} avg. latency over #{result.data.count} traces."

    for app in apps
      latency(app)
