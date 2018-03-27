defmodule ChessWeb.Router do
  use ChessWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :get_current_user
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  #Taken from Nat Tuck's lecture notes, not sure where it should go
  def get_current_user(conn, _params) do
    user_id = get_session(conn, :user_id)
    if user_id do
      user = Chess.Accounts.get_user(user_id || -1)
      assign(conn, :current_user, user)
    else
      assign(conn, :current_user, nil)
    end
  end

  scope "/", ChessWeb do
    pipe_through :browser # Use the default browser stack
    resources "/users", UserController
    resources "/games", GameController
    post "/games/:id", GameController, :update

    get "/", PageController, :index
    get "/feed", PageController, :feed
    #Taken from Nat Tuck's lecture notes
    post "/session", SessionController, :create
    delete "/session", SessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", ChessWeb do
  #   pipe_through :api
  # end
end
