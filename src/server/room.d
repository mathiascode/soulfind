// SPDX-FileCopyrightText: 2024 Soulfind Contributors
// SPDX-FileCopyrightText: 2005-2017 SeeSchloss <seeschloss@seeschloss.org>
// SPDX-License-Identifier: GPL-3.0-or-later


module soulfind.server.room;
@safe:

import soulfind.defines;
import soulfind.server.messages;
import soulfind.server.user;

class Room
{
    string                  name;

    private User[string]    user_list;
    private string[string]  tickers;


    this(string name)
    {
        this.name = name;
    }


    // Users

    void add_user(User user)
    {
        if (user.username in user_list)
            return;

        user_list[user.username] = user;

        send_to_all(
            new SUserJoinedRoom(
                name, user.username, user.status,
                user.speed, user.upload_number, user.something,
                user.shared_files, user.shared_folders,
                user.slots_full, user.country_code
            )
        );
        user.send_message(
            new SJoinRoom(
                name, user_names, statuses, speeds,
                upload_numbers, somethings, shared_files,
                shared_folders, slots_full, country_codes
            )
        );
        user.send_message(new SRoomTicker(name, tickers));
    }

    void remove_user(string username)
    {
        if (username !in user_list)
            return;

        user_list.remove(username);
        send_to_all(new SUserLeftRoom(username, name));
    }

    bool is_joined(string username)
    {
        return (username in user_list) ? true : false;
    }

    ulong nb_users()
    {
        return user_list.length;
    }

    private string[] user_names()
    {
        return user_list.keys;
    }

    private uint[string] statuses()
    {
        uint[string] statuses;
        foreach (user ; user_list)
            statuses[user.username] = user.status;

        return statuses;
    }

    private uint[string] speeds()
    {
        uint[string] speeds;
        foreach (user ; user_list)
            speeds[user.username] = user.speed;

        return speeds;
    }

    private uint[string] upload_numbers()
    {
        uint[string] upload_numbers;
        foreach (user ; user_list)
            upload_numbers[user.username] = user.upload_number;

        return upload_numbers;
    }

    private uint[string] somethings()
    {
        uint[string] somethings;
        foreach (user ; user_list)
            somethings[user.username] = user.something;

        return somethings;
    }

    private uint[string] shared_files()
    {
        uint[string] shared_files;
        foreach (user ; user_list)
            shared_files[user.username] = user.shared_files;

        return shared_files;
    }

    private uint[string] shared_folders()
    {
        uint[string] shared_folders;
        foreach (user ; user_list)
            shared_folders[user.username] = user.shared_folders;

        return shared_folders;
    }

    private uint[string] slots_full()
    {
        uint[string] slots_full;
        foreach (user ; user_list)
            slots_full[user.username] = user.slots_full;

        return slots_full;
    }

    private string[string] country_codes()
    {
        string[string] country_codes;
        foreach (user ; user_list)
            country_codes[user.username] = user.country_code;

        return country_codes;
    }

    void send_to_all(SMessage msg)
    {
        foreach (user ; user_list)
            user.send_message(msg);
    }


    // Chat

    void say(string username, string message)
    {
        if (username in user_list)
            send_to_all(new SSayChatroom(name, username, message));
    }


    // Tickers

    void add_ticker(string username, string content)
    {
        if (!content) {
            del_ticker(username);
            return;
        }
        tickers[username] = content;
        send_to_all(new SRoomTickerAdd(name, username, content));
    }

    private void del_ticker(string username)
    {
        if (username !in tickers)
            return;

        tickers.remove(username);
        send_to_all(new SRoomTickerRemove(name, username));
    }
}

class GlobalRoom
{
    private User[string] user_list;


    void add_user(User user)
    {
        if (user.username !in user_list)
            user_list[user.username] = user;
    }

    void remove_user(string username)
    {
        if (username in user_list)
             user_list.remove(username);
    }

    void say(string room_name, string username, string message)
    {
        foreach (user ; user_list) {
            user.send_message(
                new SGlobalRoomMessage(room_name, username, message)
            );
        }
    }
}
