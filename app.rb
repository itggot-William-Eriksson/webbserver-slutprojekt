class App < Sinatra::Base

require_relative 'module.rb'

include Database

enable :sessions

	get '/' do
		x = "b" + rand(1..3).to_s + "box"
		slim(:hem, locals:{x:x})
	end

	get '/register' do
		slim(:register)
	end

	get '/start' do
		if session[:user] == nil
			redirect('/')
		end
		begin
			user_id = fetch_userinfo(session[:user], "id").join
			groups = fetch("groupid", "user_group", "userid", user_id)
			invites = fetch("*", "invites", "invitedid", user_id)
		end
		group_id_name = {}
		groups.each do |group_id|
			group_id_name[group_id.join] = fetch("name", "groups", "id", group_id.join).join
		end
		slim(:start, locals:{username:session[:user], groups:groups, invites:invites, group_id_name:group_id_name})
	end

	get '/start/groups/:id' do
		if session[:user] == nil
			redirect('/')
		end
		message_limit = 10
		group_id = params["id"]
		users = fetch_users_from_group(group_id)
		messages = fetch("*", "messages", "groupid", group_id)
		leader_id = fetch("groupleaderid", "groups", "id", group_id).join
		logged_in_user_id = fetch_userinfo(session[:user], "id").join
		usernames = []
		users.each do |user_id|
			usernames << fetch("name", "users", "id", user_id).join
		end
		user_id_name = {}
		users.each do |user_id|
			user_id_name[user_id.join] = fetch("name", "users", "id", user_id.join).join
		end
		while messages.length > message_limit
			messages.delete_at(0)
		end
		if leader_id == logged_in_user_id
			slim(:groupifleader, locals:{usernames:usernames, messages:messages, group_id:group_id, user_id_name:user_id_name})
		else
			slim(:group, locals:{usernames:usernames, messages:messages, group_id:group_id, user_id_name:user_id_name})
		end
	end

	get '/fail' do
		if session[:fail_message] == nil
			redirect('/')
		end
		slim(:fail, locals:{error_message:session[:fail_message], redirect_to:session[:redirect_to]})
	end

	get '/logout' do
		session[:user] = nil
		redirect('/')
	end

	post '/login' do
		username = params["username"]
		password = params["password"]
		db = connect
		begin
			password_digest = fetch_userinfo(username, "password").join
			password_digest = BCrypt::Password.new(password_digest)
		rescue
			session[:fail_message] = "Bad login"
			session[:redirect_to] = "/"
			redirect('/fail')
		end
		if password_digest == password
			session[:user] = username
			redirect('/start')
		else
			session[:fail_message] = "Bad login"
			session[:redirect_to] = "/"
			redirect('/fail')
		end
	end

	post '/register' do
		username = params["username"]
		password2 = params["password2"]
		password = params["password"]
		if username.length <= 0
			session[:fail_message] = "Username too short"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		if password.length <= 0
			session[:fail_message] = "Password too short"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		if password2 != password
			session[:fail_message] = "Passwords does not match"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		password_digest = BCrypt::Password.create(password)
		db = connect
		begin
			db.execute("INSERT INTO users (name, password) VALUES (?,?)",[username,password_digest])
		rescue
			session[:fail_message] = "Username already in use"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		redirect('/')
	end

	post '/start/groups/create' do
		db = connect
		group_name = params["group_name"]
		user_id = fetch_userinfo(session[:user], "id").join
		db.execute("INSERT INTO groups (name, groupleaderid) VALUES (?,?)",[group_name,user_id])
		group_id = fetch("id", "groups", "name", group_name).join
		db.execute("INSERT INTO user_group (userid, groupid) VALUES (?,?)",[user_id, group_id])
		redirect('/start')
	end

	post '/start/post_message/:group_id' do
		if session[:user] == nil
			redirect('/')
		end
		group_id = params["group_id"]
		users = fetch_users_from_group(group_id)
		message = params["message"]
		user_id = fetch_userinfo(session[:user], "id").join
		checker = 0
		users.each do |user|
			if user[0].to_s == user_id
				checker = 1
			end
		end
		if checker == 0
			redirect('/logout')
		end
		db = connect
		db.execute("INSERT INTO messages (userid, groupid, message) VALUES (?,?,?)",[user_id,group_id,message])
		redirect("/start/groups/#{group_id}")
	end

end