// this simply Node.js server sets a secure session cookie, via https://WEB_DOMAIN/session

// use Express server
var crypto  = require('crypto');
var express = require('express');
var app = express();

// redirect with new session key
app.get('/session', function(req, res){
  res
    .cookie(
      'sessionKey',
      crypto.randomBytes(20).toString('hex'), // we provide the key
      {
        path: '/',
        sameSite: 'Lax',        
        secure: true,
        httpOnly: true // the key itself is httpOnly
      }
    )
    .cookie(
      'isSession',
      1,
      {
        path: '/',
        sameSite: 'Lax',        
        secure: true // but set a flag readable by javascript that sessionKey exists
      }
    )
    .redirect('https://' + process.env.WEB_DOMAIN); // and only send it to the intended url
});

app.listen(8080);
