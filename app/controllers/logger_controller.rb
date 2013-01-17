require 'date'

class LoggerController < ApplicationController

  def initialize

    config = {
        :username =>  Rails.application.config.evernote_username,
        :password => Rails.application.config.evernote_password,
        :consumer_key => Rails.application.config.evernote_key,
        :consumer_secret => Rails.application.config.evernote_secret
    }



    # client = EvernoteOAuth::Client.new(
    #   :consumer_key => config.consumer_key,
    #   :consumer_secret => config.consumer_secret,
    #   :sandbox => true
    # )
    # @auth_token = "S=s38:U=3e8fa6:E=14392fb3221:C=13c3b4a0621:P=1cd:A=en-devtoken:H=e0dc3bc1a9cf7d73de357385c18a2552"
    # # @user_store = EvernoteOAuth::Client.new(:token => token).user_store
    # # user = @user_store.getUser()
    # @client = EvernoteOAuth::Client.new(:token => @auth_token)
    # puts @client.note_store
    # @note_store = EvernoteOAuth::Client.new(:token => @auth_token).note_store

  end

  def login
  end

  def index
    token = session[:authtoken]
    client = EvernoteOAuth::Client.new(:token => token)
    @note_store = client.note_store

    page = params[:page] || 1
    @next_page = page.to_i + 1
    @prev_page = page.to_i - 1

    if @prev_page == 0 then
      @prev_page = 1
    end

    @per_page = Rails.application.config.notes_per_page

    @notebooks = @note_store.listNotebooks
    @found = "Found #{@notebooks.size} notebooks:"

    default_notebook = nil
    @notebooks.each do |notebook|
      if notebook.name == "Weight"
        default_notebook = notebook
      end
    end

    filter = Evernote::EDAM::NoteStore::NoteFilter.new;
    filter.notebookGuid = default_notebook.guid
    filter.order = 1
    notes = @note_store.findNotes(filter, @per_page * (page.to_i-1), @per_page)
    notes.notes.each do |note|
      note.created = Time.at(note.created/1000).getlocal('+10:00').strftime("%B %-d, %Y %H:%M")
    end 
    @notes = notes
    render :index, :layout => "application"
  end

  def log
    token = session[:authtoken]
    client = EvernoteOAuth::Client.new(:token => token)
    @note_store = client.note_store

    traineo = Traineo.new

    notes = params["notes"]

    @note_array = []
    notes.each do |note|
      retrieved_note = @note_store.getNote(note, false, false, false, false)
      date = Time.at(retrieved_note.created/1000).getlocal('+10:00').strftime("%B %-d, %Y")
      weight = retrieved_note.title.split(" ")[0].to_f
      weight = fixweight(weight)

      traineo.log date, weight

      @note_array << [date, weight]

    end
  end

  def manual_log
    agent = Mechanize.new

    # Login
    page = agent.get 'http://traineo.com/login'
    form = page.form
    form.send("user[username]", Rails.application.config.traineo_username)
    form.send("user[password]", Rails.application.config.traineo_password)
    page = agent.submit(form)

    # Get weight page and submit
    page = agent.get 'http://traineo.com/weight'
    form = page.form

    form.date = 'March 14, 2012'
    form.weight_input = '98.5'

    page = agent.submit(form)

    raise page.inspect
  end

  def fixweight(weight)
    return (weight > 130) ? fixweight(weight / 10) : weight
  end
end
