module Database
    def connect
        return SQLite3::Database.new("database.db")
    end

    def fetch(data, table, restriction, limit)
        db = connect
        if restriction == nil
            return db.execute("SELECT #{data} FROM #{table}")
        elsif restriction == ""
            return db.execute("SELECT #{data} FROM #{table}")
        else
            return db.execute("SELECT #{data} FROM #{table} WHERE #{restriction} = ?", [limit])
        end
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

    def fetch_userinfo_from_invite_by_groupid(group_id)
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
    
    def remove_invite(invite_id)
        db = connect
        db.execute("DELETE FROM invites WHERE id = ?", [invite_id])
    end
end