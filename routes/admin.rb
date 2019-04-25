  class Imageboard
  get '/login' do
    locals = {
      title: "Admin Login - #{$CONFIG[:site_name]}",
      type: 'admin',
      boards: Board.all
    }

    slim :login, locals: locals
  end

  get "/delete/:post" do
    if session[:user].nil?
      flash[:error] = "You are not authorized to do that."
      return redirect '/'
    end

    post = Post.find_by(number: params[:post])

    if post.nil?
      flash[:error] = "The post given doesn't exist!"
      return redirect '/'
    end

    yarn = Yarn.find_by(number: params[:post])

    # If there's a yarn with the post's number, then we're dealing with a thread.
    if !yarn.nil?
      Post.where(yarn: params[:post]).delete_all
      yarn.delete
    end

    post.delete
    flash[:error] = "Post deleted."
    return redirect '/'
  end

  get "/ban/:post" do
    if session[:user].nil?
        flash[:error] = "You are not authorized to do that."
        return redirect '/'
    end

    post = Post.find_by(number: params[:post])

    if post.nil?
      flash[:error] = "The post given doesn't exist!"
      return redirect '/'
    end

    yarn = Yarn.find_by(number: params[:post])

    if !yarn.nil?
      Post.where(yarn: params[:post]).delete_all
      yarn.delete
    end

    post.delete

    # delete any other posts and threads made by the user
    Ban.delete_by post.ip

    Ban.create({
        ip: post.ip
    })

    flash[:error] = "User banned and all posts by that IP deleted."
    return redirect '/'
  end

  get '/logout' do
    if !session[:user].nil?
      session[:user] = nil
      flash[:error] = "You are now logged out."
    end

    return redirect '/'
  end

  post '/login' do
    if !params.has_key?("username") or !params.has_key?("password")
      flash[:error] = "Username or password missing."
      return redirect "/login"
    end

    if !User.exists?(params[:username])
      flash[:error] = "Username or password invalid!"
      return redirect "/login"
    end

    if !User.authorized?(params[:username], params[:password])
      flash[:error] = "Username or password invalid!"
      return redirect "/login"
    end

    session[:user] = params[:username]
    flash[:error] = "You are now logged in."
    return redirect "/"
  end

  get '/banned' do
    locals = {
      title: "Banned - #{$CONFIG[:site_name]}",
      type: 'banned',
      boards: Board.all
    }

    slim :banned, locals: locals
  end
end
