module Database
    def connect
        return SQLite3::Database.new("database.db")
    end

    # def fetch(data, table, restriction, limit)
    #     db = connect
    #     if restriction == nil
    #         return db.execute("SELECT #{data} FROM #{table}")
    #     elsif restriction == ""
    #         return db.execute("SELECT #{data} FROM #{table}")
    #     else
    #         return db.execute("SELECT #{data} FROM #{table} WHERE #{restriction} = ?", [limit])
    #     end
    # end

    def fetch_groups(id)
        db = connect()
        return db.execute("SELECT groupid FROM user_group WHERE userid=?", [id])
    end

    def fetch_invites(id)
        db = connect()
        return db.execute("SELECT * FROM invites WHERE  invitedid=?", [id])
    end

    def fetch_groupid()
        db = connect()
        allgroups = db.execute("SELECT groupid FROM user_group")
        group_id_name = {}
        allgroups.each do |group_id|
            group_id_name[group_id.join] = db.execute("SELECT name FROM groups WHERE id=?", [group_id.join]).join
        end
        return group_id_name
    end

    def checkfor(group_id,reciever_id)
        db = connect
        return db.execute("SELECT * FROM invites WHERE groupid = ? AND invitedid = ?", [group_id,reciever_id]).join
    end

    def insert_invite(group_id,sender_id,reciever_id)
        db = connect()
        db.execute("INSERT INTO invites (groupid, inviterid, invitedid) VALUES (?,?,?)",[group_id,sender_id,reciever_id])
    end

    def insert_user_group(user_id, invite)
        db = connect()
        db.execute("INSERT INTO user_group (userid, groupid) VALUES (?,?)",[user_id, invite])
    end

    def register(username,password_digest)
        db = connect()
        db.execute("INSERT INTO users (name, password) VALUES (?,?)",[username,password_digest])
    end

    def fetch_userinfo(username, data)
        db = connect
        if data == ""
            return db.execute("SELECT * FROM users WHERE name = ?", [username])
        end
        return db.execute("SELECT #{data} FROM users WHERE name = ?", [username])
    end

    def fetch_userids_from_group(group_id)
        db = connect
        return db.execute("SELECT userid FROM user_group WHERE groupid = ?", [group_id])
    end

    def fetch_userinfo_from_group(group_id)
        db = connect
        return db.execute("SELECT id,name FROM users WHERE id IN (SELECT userid FROM user_group WHERE groupid = ?)", [group_id])
    end

    def fetch_invited_userinfo(group_id)
        db = connect
        return db.execute("SELECT id,name FROM users WHERE id IN (SELECT invitedid FROM invites WHERE groupid = ?)", [group_id])
    end

    def fetch_all_users()
        db = connect
        return db.execute("SELECT id,name FROM users")
    end
    
    def fetch_groupinfo(username, data)
        db = connect
        if data == nil
            return db.execute("SELECT * FROM groups WHERE name = ?", [username])
        end
        return db.execute("SELECT #{data} FROM groups WHERE name = ?", [username])
    end

    def fetch_group_leader(group_id)
        db = connect
        return db.execute("SELECT groupleaderid FROM groups WHERE id = ?", [group_id])
    end

    def fetch_invite_info(invite_id)
        db = connect
        return db.execute("SELECT * FROM invites WHERE id = ?", [invite_id])
    end

    def fetch_messages(id)
        db = connect()
        return db.execute("SELECT * FROM messages WHERE groupid=?", [id])
    end
    
    def remove_invite(invite_id)
        db = connect
        db.execute("DELETE FROM invites WHERE id = ?", [invite_id])
    end

    def create_group(user_id,group_name)
        db = connect()
        db.execute("INSERT INTO groups (name,groupleaderid) VALUES (?,?)",[group_name,user_id])
        ids = db.execute("SELECT id FROM groups WHERE name = ? AND groupleaderid = ?",[group_name,user_id])
        largest = 0
        ids.each do |id|
            if id[0] > largest
                largest = id[0]
            end
        end
        db.execute("INSERT INTO user_group (userid,groupid) VALUES (?,?)",[user_id,largest])
    end

    def message(logged_in_user,group_id,message)
        db = connect()
        db.execute("INSERT INTO messages (userid, groupid, message) VALUES (?,?,?)",[logged_in_user,group_id,message])
    end
end