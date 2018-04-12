class App < Sinatra::Base

require_relative 'module.rb'

include Database

enable :sessions

	get '/' do
		slim(:hem)
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
			invites = fetch("*", "invites", "invited-id", user_id)
		end
		slim(:start, locals:{username:session[:user]})
	end

	get '/fail' do
		if session[:fail_message] == nil
			redirect('/')
		end
		slim(:fail, locals:{error_message:session[:fail_message], redirect_to:session[:redirect_to]})
	end

	post '/login' do
		username = params["username"]
		password = params["password"]
		db = connect
		p fetch_userinfo(username, "password")
		begin
			password_digest = fetch_userinfo(username, "password").join
			p password_digest
			password_digest = BCrypt::Password.new(password_digest)
		rescue
			session[:fail_message] = "Something bad happened"
			session[:redirect_to] = "/"
			redirect('/fail')
		end
		if password_digest == password
			session[:user] = username
			redirect('/start')
		else
			session[:fail_message] = "wrong password"
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

end