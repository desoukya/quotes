const express = require('express');
const app     = express();
const path    = require('path');
const Random  = require('random-js');
const quotes  = require('./quotes.json');

// LOGGING
const winston = require('winston');
winston.loggers.add('info', {
  console: {
    level: 'info',
    colorize: true
  },
  file: {
    filename: '/var/log/info.log'
  }
});
const logger = winston.loggers.get('info');


// SETUP TEMPLATE ENGINE
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'hjs');

// REST ENDPOINTS
app.get('/', function(req, res) {
  const size = quotes.length - 1;
  const random = new Random().integer(0, size);

  const response = {
    quote: quotes[random].text,
    author: quotes[random].author
  };

  logger.info({
    status: 200,
    response
  });  

  return res.render('index', response);
});

// HTTP WEB SERVER
app.listen(3000, function() {
  console.log('[OK] HTTP Web Server Listening on http://localhost:3000');
});