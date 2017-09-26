
module.exports = (robot) ->
  botname = process.env.HUBOT_SLACK_BOTNAME
  plusplus_re = /@([a-z0-9_\-\.]+)\+{2,}/ig
  minusminus_re = /@([a-z0-9_\-\.]+)\-{2,}/ig
  plusplus_minusminus_re = /@([a-z0-9_\-\.]+)[\+\-]{2,}/ig
  
  robot.hear plusplus_minusminus_re, (msg) ->
     sending_user = msg.message.user.name
     res = ''
     while (match = plusplus_re.exec(msg.message))
         user = match[1].replace(/\-+$/g, '')
         if user != sending_user
            count = (robot.brain.get(user) or 0) + 1
            robot.brain.set user, count
            res += "@#{user}++ [woot! now at #{count}]\n"
         else if process.env.KARMABOT_NO_GIF
            res += process.env.KARMABOT_NO_GIF
     while (match = minusminus_re.exec(msg.message))
         user = match[1].replace(/\-+$/g, '')
         count = (robot.brain.get(user) or 0) - 1
         robot.brain.set user, count
         res += "@#{user}-- [ouch! now at #{count}]\n"
     msg.send res.replace(/\s+$/g, '')

  robot.hear /// #{botname} \s+ @([a-z0-9_\-\.]+) ///i, (msg) ->
     user = msg.match[1].replace(/\-+$/g, '')
     count = robot.brain.get(user)
     if count != null
         point_label = if count == 1 then "point" else "points"
         msg.send "@#{user}: #{count} " + point_label
     else
         msg.send "@#{user} has no karma"

  robot.hear /// #{botname} \s+ leaderboard ///i, (msg) ->
     users = robot.brain.data._private
     tuples = []
     for username, score of users
        tuples.push([username, score])

     if tuples.length == 0
        msg.send "The lack of karma is too damn high!"
        return

     tuples.sort (a, b) ->
        if a[1] > b[1]
           return -1
        else if a[1] < b[1]
           return 1
        else
           return 0

     str = ''
     limit = 5
     for i in [0...Math.min(limit, tuples.length)]
        username = tuples[i][0]
        points = tuples[i][1]
        point_label = if points == 1 then "point" else "points"
        leader = if i == 0 then "All hail supreme leader!" else ""
        newline = if i < Math.min(limit, tuples.length) - 1 then '\n' else ''
        str += "##{i+1} @#{username} [#{points} " + point_label + "] " + leader + newline
     msg.send(str)
