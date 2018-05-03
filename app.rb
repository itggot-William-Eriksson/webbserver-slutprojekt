class App < Sinatra::Base

require_relative 'module.rb'

include Database

	use Rack::Session::Cookie,	:key => 'rack.session',
								:expire_after => 62312738213721837897,
								:secret => 'myhiddensecret'

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
		user_id = fetch_userinfo(session[:user], "id").join
		groups = fetch("groupid", "user_group", "userid", user_id)
		invites = fetch("*", "invites", "invitedid", user_id)
		allgroups = fetch("groupid", "user_group", "", "")
		group_id_name = {}
		allgroups.each do |group_id|
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
		users = fetch_userinfo_from_group(group_id)
		messages = fetch("*", "messages", "groupid", group_id)
		leader_id = fetch_group_leader(group_id).join
		logged_in_user = fetch_userinfo(session[:user], "")
		logged_in_user[0].delete_at(2)
		if users.include?(logged_in_user[0])
			while messages.length > message_limit
				messages.delete_at(0)
			end
			if leader_id.to_s == logged_in_user[0][0].to_s
				all_users = fetch_all_users()
				all_invited_users = fetch_userinfo_from_invite_by_groupid(group_id)
				p all_invited_users
				p users
				all_users = all_users.reject {|w| users.include? w}
				all_users = all_users.reject {|w| all_invited_users.include? w}
				slim(:groupifleader, locals:{users:users, messages:messages, group_id:group_id, all_users:all_users})
			else
				slim(:group, locals:{users:users, messages:messages, group_id:group_id})
			end
		else
			session[:fail_message] = "You are not allowed to do that"
			session[:user] = nil
			session[:redirect_to] = "/logout"
			redirect('/fail')
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

	get '/start/invite/:group_id/:user_id' do
		if session[:user] == nil
			redirect('/')
		end
		group_id = params["group_id"]
		reciever_id = params["user_id"]
		sender_id = fetch_group_leader(group_id).join
		logged_in_user = fetch_userinfo(session[:user], "")
		logged_in_user[0].delete_at(2)
		if  logged_in_user[0][0].to_s == sender_id.to_s
			db = connect
			checkfor = db.execute("SELECT * FROM invites WHERE groupid = ? AND invitedid = ?", [group_id,reciever_id]).join
			if checkfor != ""
				session[:fail_message] = "User already invited"
				session[:redirect_to] = "/start/groups/#{group_id}"
				redirect('/fail')
			else
				db.execute("INSERT INTO invites (groupid, inviterid, invitedid) VALUES (?,?,?)",[group_id,sender_id,reciever_id])
				redirect("/start/groups/#{group_id}")
			end
		else
			session[:fail_message] = "You are not allowed to do that"
			session[:user] = nil
			session[:redirect_to] = "/logout"
			redirect('/fail')
		end
	end

	get '/start/decline/:invite_id' do
		if session[:user] == nil
			redirect('/')
		end
		db = connect
		invite_id = params["invite_id"]
		user_id = fetch_userinfo(session[:user], "id").join
		invite = fetch_invite_info(invite_id)
		p user_id, invite[3], invite
		if user_id.to_s != invite[0][3].to_s
			session[:fail_message] = "You are not allowed to do that"
			session[:user] = nil
			session[:redirect_to] = "/logout"
			redirect('/fail')
		else
			remove_invite(invite_id)
			redirect("/start")
		end
	end
	
	get '/start/accept/:invite_id' do
		if session[:user] == nil
			redirect('/')
		end
		db = connect
		invite_id = params["invite_id"]
		user_id = fetch_userinfo(session[:user], "id").join
		invite = fetch_invite_info(invite_id)
		if user_id.to_s != invite[0][3].to_s
			session[:fail_message] = "You are not allowed to do that"
			session[:user] = nil
			session[:redirect_to] = "/logout"
			redirect('/fail')
		else
			remove_invite(invite_id)
			db.execute("INSERT INTO user_group (userid, groupid) VALUES (?,?)",[user_id, invite[0][1]])
			redirect("/start")
		end
	end

	post '/register' do
		username = params["username"]
		password2 = params["password2"]
		password = params["password"]
		if username.length < 3 || username.length > 20
			session[:fail_message] = "Username must be between 3 and 20 characters"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		if password.length < 3 || password.length > 40
			session[:fail_message] = "Password must be between 3 and 40 characters"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		if password2 != password
			session[:fail_message] = "Passwords does not match"
			session[:redirect_to] = "/register"
			redirect('/fail')
		end
		if username.strip == ""
			session[:fail_message] = "Username must contain letters"
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
		if group_name.length < 3 || group_name.length > 60
			session[:fail_message] = "Group name must be between 3 and 60 characters"
			session[:redirect_to] = "/start"
			redirect('/fail')
		end
		p group_name
		if group_name.strip == ""
			session[:fail_message] = "Group name must contain letters"
			session[:redirect_to] = "/start"
			redirect('/fail')
		end
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
		users = fetch_userinfo_from_group(group_id)
		message = params["message"]
		if message.length < 1 || message.length > 40
			session[:fail_message] = "Message must be between 1 and 40 characters"
			session[:redirect_to] = "/start/groups/#{group_id}"
			redirect('/fail')
		end
		if message.strip == ""
			session[:fail_message] = "Message must contain letters"
			session[:redirect_to] = "/start/groups/#{group_id}"
			redirect('/fail')
		end
		logged_in_user = fetch_userinfo(session[:user], "")
		logged_in_user[0].delete_at(2)
		if users.include?(logged_in_user[0])
			db = connect
			db.execute("INSERT INTO messages (userid, groupid, message) VALUES (?,?,?)",[logged_in_user[0][0],group_id,message])
			redirect("/start/groups/#{group_id}")
		else
			session[:fail_message] = "You are not allowed to do that"
			session[:user] = nil
			session[:redirect_to] = "/logout"
			redirect('/fail')
		end
	end

end