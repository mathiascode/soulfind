// SPDX-FileCopyrightText: 2024-2025 Soulfind Contributors
// SPDX-FileCopyrightText: 2005-2017 SeeSchloss <seeschloss@seeschloss.org>
// SPDX-License-Identifier: GPL-3.0-or-later


module soulfind.db;
@safe:

import soulfind.defines : blue, default_max_users, default_port, norm;
import std.conv : to;
import std.exception : ifThrown;
import std.file : exists, isFile;
import std.stdio : writefln, writeln;
import std.string : format, fromStringz, join, replace, toStringz;

struct SdbUserStats
{
    string  username;
    bool    exists;
    uint    speed;
    uint    upload_number;
    uint    shared_files;
    uint    shared_folders;
}

class Sdb
{
    const users_table   = "users";
    const admins_table  = "admins";
    const config_table  = "config";


    this(string filename)
    {

    }

    ~this()
    {
        debug(db) writeln("DB: Shutting down...");
    }

    private void init_config()
    {
        const sql = format!(
            "CREATE TABLE IF NOT EXISTS %s("
          ~ " option TEXT PRIMARY KEY,"
          ~ " value"
          ~ ") WITHOUT ROWID;")(
            config_table
        );
        query(sql);

        init_config_option("port", default_port);
        init_config_option("max_users", default_max_users);
        init_config_option("motd", "Soulfind %sversion%");
    }

    private void init_config_option(string option, string value)
    {
        const sql = format!(
            "INSERT OR IGNORE INTO %s(option, value) VALUES(?, ?);")(
            config_table
        );
        query(sql, [option, value]);
    }

    private void init_config_option(string option, uint value)
    {
        const sql = format!(
            "INSERT OR IGNORE INTO %s(option, value) VALUES(?, ?);")(
            config_table
        );
        query(sql, [option, value.to!string]);
    }

    void set_config_value(string option, string value)
    {
        const sql = format!(
            "REPLACE INTO %s(option, value) VALUES(?, ?);")(
            config_table
        );
        query(sql, [option, value]);
    }

    void set_config_value(string option, uint value)
    {
        const sql = format!(
            "REPLACE INTO %s(option, value) VALUES(?, ?);")(
            config_table
        );
        query(sql, [option, value.to!string]);
    }

    string get_config_value(string option)
    {
        const sql = format!("SELECT value FROM %s WHERE option = ?;")(
            config_table
        );
        return query(sql, [option])[0][0];
    }

    void add_admin(string username, uint level = 0)
    {
        const sql = format!(
            "REPLACE INTO %s(username, level) VALUES(?, ?);")(
            admins_table
        );
        query(sql, [username, level.to!string]);
    }

    void del_admin(string username)
    {
        const sql = format!("DELETE FROM %s WHERE username = ?;")(
            admins_table
        );
        query(sql, [username]);
    }

    string[] admins()
    {
        const sql = format!("SELECT username FROM %s;")(
            admins_table
        );
        string[] admins;
        foreach (record ; query(sql)) admins ~= record[0];
        return admins;
    }

    bool is_admin(string username)
    {
        const sql = format!(
            "SELECT username FROM %s WHERE username = ?;")(
            admins_table
        );
        return query(sql, [username]).length > 0;
    }

    void add_user(string username, string password)
    {
        const sql = format!(
            "INSERT INTO %s(username, password) VALUES(?, ?);")(
            users_table
        );
        query(sql, [username, password]);
        query("PRAGMA optimize;");
    }

    bool user_exists(string username)
    {
        const sql = format!(
            "SELECT username FROM %s WHERE username = ?;")(
            users_table
        );
        return query(sql, [username]).length > 0;
    }

    void user_update_field(string username, string field, string value)
    {
        const sql = format!(
            "UPDATE %s SET %s = ? WHERE username = ?;")(
            users_table, field
        );
        query(sql, [value, username]);
    }

    void user_update_field(string username, string field, ulong value)
    {
        const sql = format!(
            "UPDATE %s SET %s = ? WHERE username = ?;")(
            users_table, field
        );
        query(sql, [value.to!string, username]);
    }

    string get_pass(string username)
    {
        const sql = format!(
            "SELECT password FROM %s WHERE username = ?;")(
            users_table
        );
        return query(sql, [username])[0][0];
    }

    long get_user_privileges(string username)
    {
        const sql = format!(
            "SELECT privileges FROM %s WHERE username = ?;")(
            users_table
        );
        return query(sql, [username])[0][0].to!long.ifThrown(0);
    }

    long get_ban_expiration(string username)
    {
        const sql = format!(
            "SELECT banned FROM %s WHERE username = ?;")(
            users_table
        );
        return query(sql, [username])[0][0].to!long.ifThrown(0);
    }

    SdbUserStats get_user_stats(string username)
    {
        debug(db) writefln!("DB: Requested %s's info...")(
            blue ~ username ~ norm
        );
        const sql = format!(
            "SELECT speed,ulnum,files,folders"
          ~ " FROM %s"
          ~ " WHERE username = ?;")(
            users_table
        );
        const res = query(sql, [username]);
        auto user_stats = SdbUserStats();

        if (res.length > 0) {
            const record               = res[0];
            user_stats.exists          = true;
            user_stats.speed           = record[0].to!uint.ifThrown(0);
            user_stats.upload_number   = record[1].to!uint.ifThrown(0);
            user_stats.shared_files    = record[2].to!uint.ifThrown(0);
            user_stats.shared_folders  = record[3].to!uint.ifThrown(0);
        }
        return user_stats;
    }

    string[] usernames(string field = null, ulong min = 1,
                       ulong max = ulong.max)
    {
        string[] ret;
        auto sql = format!("SELECT username FROM %s")(users_table);
        string[] parameters;

        if (field) {
            sql ~= format!(" WHERE %s BETWEEN ? AND ?")(field);
            parameters = [min.to!string, max.to!string];
        }
        sql ~= ";";
        foreach (record ; query(sql, parameters)) ret ~= record[0];
        return ret;
    }

    uint num_users(string field = null, ulong min = 1, ulong max = ulong.max)
    {
        auto sql = format!("SELECT COUNT(1) FROM %s")(users_table);
        string[] parameters;

        if (field) {
            sql ~= format!(" WHERE %s BETWEEN ? AND ?")(field);
            parameters = [min.to!string, max.to!string];
        }
        sql ~= ";";
        return query(sql, parameters)[0][0].to!uint.ifThrown(0);
    }

    private string[][] query(string query, const string[] parameters = [])
    {
        string[][] ret;

        return ret;
    }
}
