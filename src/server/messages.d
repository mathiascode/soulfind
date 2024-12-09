// SPDX-FileCopyrightText: 2024 Soulfind Contributors
// SPDX-FileCopyrightText: 2005-2017 SeeSchloss <seeschloss@seeschloss.org>
// SPDX-License-Identifier: GPL-3.0-or-later


module soulfind.server.messages;
@safe:

import soulfind.defines;
import std.bitmanip : Endian, read;
import std.conv : to;
import std.outbuffer : OutBuffer;
import std.stdio : writefln;
import std.string : lastIndexOf;

// Constants

const enum Status
{
    offline  = 0,
    away     = 1,
    online   = 2
}


// Message Codes

const Login                  = 1;
const SetWaitPort            = 2;
const GetPeerAddress         = 3;
const WatchUser              = 5;
const UnwatchUser            = 6;
const GetUserStatus          = 7;
const SayChatroom            = 13;
const JoinRoom               = 14;
const LeaveRoom              = 15;
const UserJoinedRoom         = 16;
const UserLeftRoom           = 17;
const ConnectToPeer          = 18;
const MessageUser            = 22;
const MessageAcked           = 23;
const FileSearch             = 26;
const SetStatus              = 28;
const ServerPing             = 32;
const SharedFoldersFiles     = 35;
const GetUserStats           = 36;
const Relogged               = 41;
const UserSearch             = 42;
const AddThingILike          = 51;
const RemoveThingILike       = 52;
const GetRecommendations     = 54;
const GlobalRecommendations  = 56;
const UserInterests          = 57;
const RoomList               = 64;
const AdminMessage           = 66;
const CheckPrivileges        = 92;
const WishlistSearch         = 103;
const WishlistInterval       = 104;
const SimilarUsers           = 110;
const ItemRecommendations    = 111;
const ItemSimilarUsers       = 112;
const RoomTicker             = 113;
const RoomTickerAdd          = 114;
const RoomTickerRemove       = 115;
const SetRoomTicker          = 116;
const AddThingIHate          = 117;
const RemoveThingIHate       = 118;
const RoomSearch             = 120;
const SendUploadSpeed        = 121;
const UserPrivileged         = 122;
const GivePrivileges         = 123;
const ChangePassword         = 142;
const MessageUsers           = 149;
const JoinGlobalRoom         = 150;
const LeaveGlobalRoom        = 151;
const GlobalRoomMessage      = 152;
const CantConnectToPeer      = 1001;


// Incoming Messages

class UMessage
{
    uint       code;
    ubyte[]    in_buf;

    this(uint code, ubyte[] in_buf, string in_user = "?")
    {
        this.in_buf = in_buf;

        debug (msg) writefln(
            "Receive <- %s (code %d) of %d bytes <- from user %s",
            blue ~ this.name ~ norm, code, in_buf.length,
            blue ~ in_user ~ norm
        );
    }

    string name()
    {
        const cls_name = typeid(this).name;
        return cls_name[cls_name.lastIndexOf(".") + 1 .. $];
    }

    private uint readi()
    {
        uint i;
        if (in_buf.length < uint.sizeof) {
            writefln(
                "message code %d, length %d not enough data "
                ~ "trying to read an int", code, in_buf.length
            );
            return i;
        }

        i = in_buf.read!(uint, Endian.littleEndian);
        return i;
    }

    private bool readb()
    {
        bool i;
        if (in_buf.length < bool.sizeof) {
            writefln(
                "message code %d, length %d not enough data "
                ~ "trying to read a boolean", code, in_buf.length
            );
            return i;
        }

        i = in_buf.read!bool;
        return i;
    }

    private string reads()
    {
        uint slen = readi();
        if (slen > in_buf.length) slen = cast(uint) in_buf.length;
        const str = cast(string) in_buf[0 .. slen].idup;

        in_buf = in_buf[slen .. $];
        return str;
    }
}

class ULogin : UMessage
{
    string  user;
    string  password;
    uint    major_version;
    string  hash;            // MD5 hash of username + password
    uint    minor_version;

    this(ubyte[] in_buf)
    {
        super(Login, in_buf);

        user          = reads();
        password      = reads();
        major_version = readi();

        if (major_version >= 155) {
            // Older clients would not send these
            hash          = reads();
            minor_version = readi();
        }
    }
}

class USetWaitPort : UMessage
{
    uint port;

    this(ubyte[] in_buf, string in_user)
    {
        super(SetWaitPort, in_buf, in_user);

        port = readi();
    }
}

class UGetPeerAddress : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(GetPeerAddress, in_buf, in_user);

        user = reads();
    }
}

class UWatchUser : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(WatchUser, in_buf, in_user);

        user = reads();
    }
}

class UUnwatchUser : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(UnwatchUser, in_buf, in_user);

        user = reads();
    }
}

class UGetUserStatus : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(GetUserStatus, in_buf, in_user);

        user = reads();
    }
}

class USayChatroom : UMessage
{
    string  room;
    string  message;

    this(ubyte[] in_buf, string in_user)
    {
        super(SayChatroom, in_buf, in_user);

        room    = reads();
        message = reads();
    }
}

class UJoinRoom : UMessage
{
    string room;

    this(ubyte[] in_buf, string in_user)
    {
        super(JoinRoom, in_buf, in_user);

        room = reads();
    }
}

class ULeaveRoom : UMessage
{
    string room;

    this(ubyte[] in_buf, string in_user)
    {
        super(LeaveRoom, in_buf, in_user);

        room = reads();
    }
}

class UConnectToPeer : UMessage
{
    uint    token;
    string  user;
    string  type;

    this(ubyte[] in_buf, string in_user)
    {
        super(ConnectToPeer, in_buf, in_user);

        token = readi();
        user  = reads();
        type  = reads();
    }
}

class UMessageUser : UMessage
{
    string  user;
    string  message;

    this(ubyte[] in_buf, string in_user)
    {
        super(MessageUser, in_buf, in_user);

        user    = reads();
        message = reads();
    }
}

class UMessageAcked : UMessage
{
    uint id;

    this(ubyte[] in_buf, string in_user)
    {
        super(MessageAcked, in_buf, in_user);

        id = readi();
    }
}

class UFileSearch : UMessage
{
    uint    token;
    string  query;

    this(ubyte[] in_buf, string in_user)
    {
        super(FileSearch, in_buf, in_user);

        token = readi();
        query = reads();
    }
}

class UWishlistSearch : UMessage
{
    uint    token;
    string  query;

    this(ubyte[] in_buf, string in_user)
    {
        super(WishlistSearch, in_buf, in_user);

        token = readi();
        query = reads();
    }
}

class USimilarUsers : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(SimilarUsers, in_buf, in_user);
    }
}

class USetStatus : UMessage
{
    uint status;

    this(ubyte[] in_buf, string in_user)
    {
        super(SetStatus, in_buf, in_user);

        status = readi();
    }
}

class UServerPing : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(ServerPing, in_buf, in_user);
    }
}

class USendUploadSpeed : UMessage
{
    uint speed;

    this(ubyte[] in_buf, string in_user)
    {
        super(SendUploadSpeed, in_buf, in_user);

        speed = readi();
    }
}

class USharedFoldersFiles : UMessage
{
    uint  nb_folders;
    uint  nb_files;

    this(ubyte[] in_buf, string in_user)
    {
        super(SharedFoldersFiles, in_buf, in_user);

        nb_folders = readi();
        nb_files   = readi();
    }
}

class UGetUserStats : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(GetUserStats, in_buf, in_user);

        user = reads();
    }
}

class UUserSearch : UMessage
{
    string  user;
    uint    token;
    string  query;

    this(ubyte[] in_buf, string in_user)
    {
        super(UserSearch, in_buf, in_user);

        user  = reads();
        token = readi();
        query = reads();
    }
}

class UAddThingILike : UMessage
{
    string thing;

    this(ubyte[] in_buf, string in_user)
    {
        super(AddThingILike, in_buf, in_user);

        thing = reads();
    }
}

class URemoveThingILike : UMessage
{
    string thing;

    this(ubyte[] in_buf, string in_user)
    {
        super(RemoveThingILike, in_buf, in_user);

        thing = reads();
    }
}

class UGetRecommendations : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(GetRecommendations, in_buf, in_user);
    }
}

class UGlobalRecommendations : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(GlobalRecommendations, in_buf, in_user);
    }
}

class UUserInterests : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(UserInterests, in_buf, in_user);

        user = reads();
    }
}

class URoomList : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(RoomList, in_buf, in_user);
    }
}

class UCheckPrivileges : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(CheckPrivileges, in_buf, in_user);
    }
}

class UAddThingIHate : UMessage
{
    string thing;

    this(ubyte[] in_buf, string in_user)
    {
        super(AddThingIHate, in_buf, in_user);

        thing = reads();
    }
}

class URemoveThingIHate : UMessage
{
    string thing;

    this(ubyte[] in_buf, string in_user)
    {
        super(RemoveThingIHate, in_buf, in_user);

        thing = reads();
    }
}

class UItemRecommendations : UMessage
{
    string item;

    this(ubyte[] in_buf, string in_user)
    {
        super(ItemRecommendations, in_buf, in_user);

        item = reads();
    }
}

class UItemSimilarUsers : UMessage
{
    string item;

    this(ubyte[] in_buf, string in_user)
    {
        super(ItemSimilarUsers, in_buf, in_user);

        item = reads();
    }
}

class USetRoomTicker : UMessage
{
    string  room;
    string  tick;

    this(ubyte[] in_buf, string in_user)
    {
        super(SetRoomTicker, in_buf, in_user);

        room = reads();
        tick = reads();
    }
}

class URoomSearch : UMessage
{
    string  room;
    uint    token;
    string  query;

    this(ubyte[] in_buf, string in_user)
    {
        super(RoomSearch, in_buf, in_user);

        room  = reads();
        token = readi();
        query = reads();
    }
}

class UUserPrivileged : UMessage
{
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(UserPrivileged, in_buf, in_user);

        user = reads();
    }
}

class UGivePrivileges : UMessage
{
    string  user;
    uint    time;

    this(ubyte[] in_buf, string in_user)
    {
        super(GivePrivileges, in_buf, in_user);

        user = reads();
        time = readi();
    }
}

class UChangePassword : UMessage
{
    string password;

    this(ubyte[] in_buf, string in_user)
    {
        super(ChangePassword, in_buf, in_user);

        password = reads();
    }
}

class UMessageUsers : UMessage
{
    string[]  users;
    string    message;

    this(ubyte[] in_buf, string in_user)
    {
        super(MessageUsers, in_buf, in_user);

        foreach (i ; 0 .. readi()) users ~= reads();
        message = reads();
    }
}

class UJoinGlobalRoom : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(JoinGlobalRoom, in_buf, in_user);
    }
}

class ULeaveGlobalRoom : UMessage
{
    this(ubyte[] in_buf, string in_user)
    {
        super(LeaveGlobalRoom, in_buf, in_user);
    }
}

class UCantConnectToPeer : UMessage
{
    uint token;
    string user;

    this(ubyte[] in_buf, string in_user)
    {
        super(CantConnectToPeer, in_buf, in_user);

        token = readi();
        user  = reads();
    }
}


// Outgoing Messages

class SMessage : OutBuffer
{
    uint       code;

    this(uint code)
    {
        this.code = code;
        write(code);
    }

    string name()
    {
        const cls_name = typeid(this).name;
        return cls_name[cls_name.lastIndexOf(".") + 1 .. $];
    }

    private void writei(uint i)
    {
        write(i);
    }

    private void writesi(int i)
    {
        write(i);
    }

    private void writeb(bool b)
    {
        write(cast(ubyte) b);
    }

    private void writes(string s)
    {
        write(cast(uint) s.length);
        write(s);
    }
}

class SLogin : SMessage
{
    this(bool success, string mesg, uint addr = 0,
         string password = null, bool supporter = false)
    {
        super(Login);

        writeb(success);
        writes(mesg);

        if (success)
        {
            writei(addr);
            writes(password);
            writeb(supporter);
        }
    }
}

class SGetPeerAddress : SMessage
{
    this(string username, uint address, uint port, uint unknown = 0,
            uint obfuscated_port = 0)
    {
        super(GetPeerAddress);

        writes(username);
        writei(address);
        writei(port);
        writei(unknown);
        writei(obfuscated_port);
    }
}

class SWatchUser : SMessage
{
    this(string user, bool exists, uint status, uint speed,
         uint upload_number, uint something, uint shared_files,
         uint shared_folders, string country_code)
    {
        super(WatchUser);

        writes(user);
        writeb(exists);
        if (!exists)
            return;

        writei(status);
        writei(speed);
        writei(upload_number);
        writei(something);
        writei(shared_files);
        writei(shared_folders);
        if (status > 0) writes(country_code);
    }
}

class SGetUserStatus : SMessage
{
    this(string username, uint status, bool privileged)
    {
        super(GetUserStatus);

        writes(username);
        writei(status);
        writeb(privileged);
    }
}

class SSayChatroom : SMessage
{
    this(string room, string user, string mesg)
    {
        super(SayChatroom);

        writes(room);
        writes(user);
        writes(mesg);
    }
}

class SRoomList : SMessage
{
    this(uint[string] rooms)
    {
        super(RoomList);

        writei(cast(uint) rooms.length);
        foreach (room, users ; rooms) writes(room);

        writei(cast(uint) rooms.length);
        foreach (room, users ; rooms) writei(users);

        writei(0);    // number of owned private rooms(unimplemented)
        writei(0);    // number of owned private rooms(unimplemented)
        writei(0);    // number of other private rooms(unimplemented)
        writei(0);    // number of other private rooms(unimplemented)
        writei(0);    // number of operated private rooms(unimplemented)
    }
}

class SJoinRoom : SMessage
{
    this(string room, string[] usernames, uint[string] statuses,
         uint[string] speeds, uint[string] upload_numbers,
         uint[string] somethings, uint[string] shared_files,
         uint[string] shared_folders, uint[string] slots_full,
         string[string] country_codes)
    {
        super(JoinRoom);

        writes(room);
        const n = cast(uint) usernames.length;

        writei(n);
        foreach (username ; usernames) writes(username);

        writei(n);
        foreach (username ; usernames) writei(statuses[username]);

        writei(n);
        foreach (username ; usernames)
        {
            writei(speeds          [username]);
            writei(upload_numbers  [username]);
            writei(somethings      [username]);
            writei(shared_files    [username]);
            writei(shared_folders  [username]);
        }

        writei(n);
        foreach (username ; usernames) writei(slots_full[username]);

        writei(n);
        foreach (username ; usernames) writes(country_codes[username]);
    }
}

class SLeaveRoom : SMessage
{
    this(string room)
    {
        super(LeaveRoom);

        writes(room);
    }
}

class SUserJoinedRoom : SMessage
{
    this(string room, string username, uint status,
         uint speed, uint upload_number, uint something,
         uint shared_files, uint shared_folders,
         uint slots_full, string country_code)
    {
        super(UserJoinedRoom);

        writes(room);
        writes(username);
        writei(status);
        writei(speed);
        writei(upload_number);
        writei(something);
        writei(shared_files);
        writei(shared_folders);
        writei(slots_full);
        writes(country_code);
    }
}

class SUserLeftRoom : SMessage
{
    this(string username, string room)
    {
        super(UserLeftRoom);

        writes(room);
        writes(username);
    }
}

class SConnectToPeer : SMessage
{
    this(string username, string type, uint address, uint port,
            uint token, bool privileged, uint unknown = 0,
            uint obfuscated_port = 0)
    {
        super(ConnectToPeer);

        writes(username);
        writes(type);
        writei(address);
        writei(port);
        writei(token);
        writeb(privileged);
        writei(unknown);
        writei(obfuscated_port);
    }
}

class SMessageUser : SMessage
{
    this(uint id, uint timestamp, string from, string content,
            bool new_message)
    {
        super(MessageUser);

        writei(id);
        writei(timestamp);
        writes(from);
        writes(content);
        writeb(new_message);
    }
}

class SFileSearch : SMessage
{
    this(string username, uint token, string text)
    {
        super(FileSearch);

        writes(username);
        writei(token);
        writes(text);
    }
}

class SGetUserStats : SMessage
{
    this(string username, uint speed, uint upload_number, uint something,
            uint shared_files, uint shared_folders)
    {
        super(GetUserStats);

        writes(username);
        writei(speed);
        writei(upload_number);
        writei(something);
        writei(shared_files);
        writei(shared_folders);
    }
}

class SGetRecommendations : SMessage
{
    this(uint[string] list)
    {
        super(GetRecommendations);

        writei(cast(uint) list.length);
        foreach (artist, level ; list)
        {
            writes(artist);
            writesi(level);
        }
    }
}

class SGetGlobalRecommendations : SMessage
{
    this(uint[string] list)
    {
        super(GlobalRecommendations);

        writei(cast(uint) list.length);
        foreach (artist, level ; list)
        {
            writes(artist);
            writesi(level);
        }
    }
}

class SUserInterests : SMessage
{
    this(string user, string[string] likes, string[string] hates)
    {
        super(UserInterests);

        writes(user);

        writei(cast(uint) likes.length);
        foreach (thing ; likes) writes(thing);

        writei(cast(uint) hates.length);
        foreach (thing ; hates) writes(thing);
    }
}

class SRelogged : SMessage
{
    this()
    {
        super(Relogged);
    }
}

class SUserSearch : SMessage
{
    this(string user, uint token, string query)
    {
        super(UserSearch);

        writes(user);
        writei(token);
        writes(query);
    }
}

class SAdminMessage : SMessage
{
    this(string message)
    {
        super(AdminMessage);

        writes(message);
    }
}

class SCheckPrivileges : SMessage
{
    this(uint time)
    {
        super(CheckPrivileges);

        writei(time);
    }
}

class SWishlistInterval : SMessage
{
    this(uint interval)
    {
        super(WishlistInterval);

        writei(interval);
    }
}

class SSimilarUsers : SMessage
{
    this(uint[string] list)
    {
        super(SimilarUsers);

        writei(cast(uint) list.length);
        foreach (user, weight ; list)
        {
            writes (user);
            writesi(weight);
        }
    }
}

class SItemRecommendations : SMessage
{
    this(string item, uint[string] list)
    {
        super(ItemRecommendations);

        writes(item);
        writei(cast(uint) list.length);

        foreach (recommendation, weight ; list)
        {
            writes (recommendation);
            writesi(weight);
        }
    }
}

class SItemSimilarUsers : SMessage
{
    this(string item, string[] list)
    {
        super(ItemSimilarUsers);

        writes(item);
        writei(cast(uint) list.length);
        foreach (user ; list) writes(user);
    }
}

class SRoomTicker : SMessage
{
    this(string room, string[string] tickers)
    {
        super(RoomTicker);

        writes(room);
        writei(cast(uint) tickers.length);
        foreach (string user, string ticker ; tickers)
        {
            writes(user);
            writes(ticker);
        }
    }
}

class SRoomTickerAdd : SMessage
{
    this(string room, string user, string ticker)
    {
        super(RoomTickerAdd);

        writes(room);
        writes(user);
        writes(ticker);
    }
}

class SRoomTickerRemove : SMessage
{
    this(string room, string user)
    {
        super(RoomTickerRemove);

        writes(room);
        writes(user);
    }
}

class SRoomSearch : SMessage
{
    this(string user, uint token, string query)
    {
        super(RoomSearch);

        writes(user);
        writei(token);
        writes(query);
    }
}

class SUserPrivileged : SMessage
{
    this(string username, bool privileged)
    {
        super(UserPrivileged);

        writes(username);
        writeb(privileged);
    }
}

class SChangePassword : SMessage
{
    this(string password)
    {
        super(ChangePassword);

        writes(password);
    }
}

class SGlobalRoomMessage : SMessage
{
    this(string room, string user, string mesg)
    {
        super(GlobalRoomMessage);

        writes(room);
        writes(user);
        writes(mesg);
    }
}

class SCantConnectToPeer : SMessage
{
    this(uint token)
    {
        super(CantConnectToPeer);

        writei(token);
    }
}
