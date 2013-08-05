# Ultimate tic tac toe
Inspired by [this post](http://mathwithbaddrawings.com/2013/06/16/ultimate-tic-tac-toe/)

This is a super little project, which may support multiplayer later.

# Installation
You need ruby with the sass gem to compile .sass file into css. If you don't have any
ruby installation, I recommend [rvm](http://rvm.io).
```
npm install
grunt install
```
For development, you can run the local server with `node server.js` and head to [localhost](http://localhost:4445). Also, run `grunt watch` to recompile css and handlebars templates when
they change.

## todo
refactor the whole thing using ember. Right now, the app is a big mess with data
and dom elements put together, it's ugly. And it'll be easier to make the app
bigger with ember (multiplayer, sessions and stuff like that).
