module Database
    def connect
        return SQLite3::Database.new("database.db")
    end

    def fetch(data, table, restriction, limit)
        db = connect
        if restriction == nil
            return db.execute("SELECT #{data} FROM '#{table}'")
        else
            return db.execute("SELECT #{data} FROM '#{table}' WHERE '#{restriction}' = ?", [limit])
        end
    end

    def fetch_userinfo(username, data)
        db = connect
        if data == nil
            return db.execute("SELECT * FROM users WHERE name = ?", [username])
        end
        p "this runs?"
        return db.execute("SELECT #{data} FROM users WHERE name = ?", [username])
    end

end