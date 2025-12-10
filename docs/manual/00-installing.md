# Installing impulse on a server
This guide will show you how to install impulse, on a server. Before we start, it should be understood impulse is made to be developed in a locally hosted peer-to-peer server, and it is made to be ran in production on a game server. To learn how to setup impulse, for development on your local machine, take a look at [the dev setup guide](https://vingard.github.io/impulsedocs/topics/10-devsetup.md.html).

## Warning
impulse is a **framework**, a framework is similar to a game engine, if there is an issue with your schema, it is not the frameworks fault. Please consult the developer of the schema for help regarding those issues. impulse was designed to be proprietary software, and as a result has some compatability issues with other admin mods or prop protection systems. This issue is planned to be addressed in future versions of the framework by using CAMI and CPPI.

## Database Information
impulse: reforged now uses Garry's Mod's built-in SQLite database by default, making it easier to get started. **However, for production servers, using MySQL/MariaDB is highly recommended** for better performance, reliability, and scalability. SQLite is suitable for small servers or testing, but larger communities should use a dedicated database server.

## Installation
**Step 1** Make sure you remove ULX if you have it already, it is not compatible with impulse.<br/>
**Step 2** Install [FPP](https://github.com/FPtje/Falcos-Prop-protection) onto your server.<br/>
**Step 3** Download the [impulse framework](https://github.com/vingard/impulse) and put it in your gamemodes folder.<br/>
**Step 4** Download your schema of choice and also put it in your gamemodes folder. If you don't have a schema, you can use the [skeleton schema](https://github.com/vingard/impulseskeleton).<br/>
**Step 5** (*not required, but recommended*) Install and setup [GExtension](https://www.gmodstore.com/market/view/2899).<br/>
**Step 6** Make sure the map you are running has a map config inside the schema, go into the schema gamemode folder, then check schema/config/maps/**MAP NAME HERE**.lua.<br/>
**Step 7** Set the gamemode of your server to the folder name of the schema.<br/>
**Step 8** That's it! Join the server to confirm everything is working. If it's not working, check the console for errors and read the message on the in-game error screen.<br/>
**Step 9** *You probably will want to edit some of the schema config. In your schema folder, navigate to config/sh_config.lua to configure your server.*<br/>

## Using MySQL/MariaDB (Recommended for Production)
While SQLite works out of the box, using MySQL/MariaDB is recommended for production servers with higher player counts or those requiring better performance and reliability.

**Step 1** Install [mysqloo](https://github.com/FredyH/MySQLOO/releases) onto your server.<br/>
**Step 2** Set up your MySQL/MariaDB database and turn off MySQL strict mode.<br/>
**Step 3** Goto garrysmod/data on your server and create a folder called 'impulse'.<br/>
**Step 4** Inside the impulse folder create a file called config.yml and paste in the config below:<br/>

```
db:
  ip: "mysql server ip here"
  username: "db username"
  password: "db pass"
  database: "db name"
  port: 3306
```

**Step 5** Replace the values in the config.yml file with those of your database.<br/>
**Step 6** Restart your server. impulse will now use MySQL instead of SQLite.<br/>

## Extra setup
Here's some extra setup you can do to get access to extra features.

### API features
If you want anti-family sharing features and slack logging, you'll need to provide your Steam API key and a Slack webhook URL. Just add this to the config.yml file:
```
apis:
  discord_ops_webhook: "https://discord.com/api/webhooks/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  discord_relaykey: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  slack_webhook: "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX"
  steam_key: "XXXXXXXXXXXXXXXXXXXXXXX"
```
