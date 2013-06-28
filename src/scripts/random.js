// Description:
//   random choice selector
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   hubot random choice Bob, Alice, Sally
//
// Author:
//   Dan Tillberg

module.exports = function(robot) {
    robot.respond(/random choice (.*)$/i, function(msg){
        var choicesStr = msg.match[1];
        var choices = [];
        // Extract comma-separated items
        choicesStr.replace(/([^,]+)/g, function (m) {
            // And trim whitespace from the beginning/end of each
            choices.push(m[0].replace(/(^\s+|\s+$)/g, '');
        });

        var randomIndex = Math.floor(Math.random() * choices.length);
        msg.reply(choices[randomIndex]);
    });
}
