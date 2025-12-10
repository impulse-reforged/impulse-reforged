# Installing impulse locally (for development)
Installing impulse locally lets you test out the framework and schema, or develop a new schema. Follow the steps below to install it. When your ready to set it up on a live server, take a look at the [server install guide](https://vingard.github.io/impulsedocs/topics/00-installing.md.html).

## Warning
impulse is a **framework**, a framework is similar to a game engine, if there is an issue with your schema, it is not the frameworks fault. Please consult the developer of the schema for help regarding those issues. impulse was designed to be proprietary software, and as a result has some compatability issues with other admin mods or prop protection systems. This issue is planned to be addressed in future versions of the framework by using CAMI and CPPI.

## Important Note for Existing Users
If you're upgrading from the original impulse framework: **XAMPP is no longer required!** impulse: reforged now uses Garry's Mod's built-in SQLite database by default, making setup significantly easier. You can still use MySQL/MariaDB for production servers (recommended), but it's completely optional for development.

## Installation
**Step 1** Make sure you remove ULX if you have it already, it is not compatible with impulse.<br/>
**Step 2** Install [FPP](https://github.com/FPtje/Falcos-Prop-protection) onto your game client.<br/>
**Step 3** Download the [impulse framework](https://github.com/vingard/impulse) and put it in your gamemodes folder.<br/>
**Step 4** Download your schema of choice and also put it in your gamemodes folder. If you don't have a schema, you can use the [skeleton schema](https://github.com/vingard/impulseskeleton).<br/>
**Step 5** Make sure the map you are running has a map config inside the schema, go into the schema gamemode folder, then check schema/config/maps/**MAP NAME HERE**.lua.<br/>
**Step 6** Set your gamemode to the folder name of the schema. You can do this by typing 'gamemode **SCHEMA NAME HERE**' on the menu.<br/>
**Step 7** Start a **peer-to-peer game** and confirm everything is working. If it's not working, check the console for errors and read the message on the in-game error screen.<br/>
**Step 8** Give yourself superadmin, to do this open your console and type 'impulse_setgroup YOUR_STEAMID_HERE superadmin', after you give yourself this, you will probably want to reload your game for the changes to update.<br/>
**Step 9** You're done! impulse will automatically create and use an SQLite database for local development. Whenever you want to start impulse again, just set your gamemode to the schema folder name and start a peer-to-peer game.<br/>

## Using MySQL/MariaDB (Optional)
By default, impulse uses SQLite which requires no setup. However, if you want to use MySQL/MariaDB for development (to match your production environment or for advanced features), you can configure it in the config.yml file.

**Step 1** *(Optional)* Install [mysqloo](https://github.com/FredyH/MySQLOO/releases) onto your game client.<br/>
**Step 2** Set up a MySQL/MariaDB server (using XAMPP, Docker, or any other method).<br/>
**Step 3** Goto garrysmod/data on your server and create a folder called 'impulse' if it doesn't exist.<br/>
**Step 4** Inside the impulse folder create a file called config.yml and configure your database details:<br/>

```
db:
  ip: "localhost"
  username: "root"
  password: "secretpass"
  database: "impulse_development"
  port: 3306
```

**Note:** Without a config.yml file or database configuration, impulse will automatically use SQLite.

## Advanced settings
You can configure your **config.yml** file to do a bunch of helpful things for development. Note that all of these settings are completely optional - impulse will work without any config.yml file.

### API features
If you want anti-family sharing features and slack logging, you'll need to provide your Steam API key and a Slack webhook URL. Just add this to the config.yml file:
```
apis:
  discord_ops_webhook: "https://discord.com/api/webhooks/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  discord_relaykey: "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  slack_webhook: "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX"
  steam_key: "XXXXXXXXXXXXXXXXXXXXXXX"
```

### Seperating databases
If you work on several schemas, you'll probably want to use a different database for each one. Changing the name of the database in config.yml each time you switch is a pain, so, you can just add this to your config.yml file to auto switch depending on the schema you are playing:
```
schemadb:
impulseskeleton: "impulse_development_skeleton"
impulseotherschema: "impulse_development_otherone"
```
