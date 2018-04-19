module Database
    def connect
        return SQLite3::Database.new("database.db")
    end

    def fetch(data, table, restriction, limit)
        db = connect
        if restriction == nil
            return db.execute("SELECT #{data} FROM #{table}")
        else
            return db.execute("SELECT #{data} FROM #{table} WHERE #{restriction} = ?", [limit])
        end
    end

    def fetch_userinfo(username, data)
        db = connect
        if data == nil
            return db.execute("SELECT * FROM users WHERE name = ?", [username])
        end
        return db.execute("SELECT #{data} FROM users WHERE name = ?", [username])
    end

    def fetch_users_from_group(group_id)
        db = connect
        return db.execute("SELECT userid FROM user_group WHERE groupid = ?", [group_id])
    end
    
    def fetch_groupinfo(username, data)
        db = connect
        if data == nil
            return db.execute("SELECT * FROM groups WHERE name = ?", [username])
        end
        return db.execute("SELECT #{data} FROM groups WHERE name = ?", [username])
    end

end