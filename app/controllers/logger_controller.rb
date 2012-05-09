require 'date'

class LoggerController < ApplicationController

  def initialize

    config = {
        :username =>  Rails.application.config.evernote_username,
        :password => Rails.application.config.evernote_password,
        :consumer_key => Rails.application.config.evernote_key,
        :consumer_secret => Rails.application.config.evernote_secret
    }

    @user_store = Evernote::UserStore.new(Rails.application.config.evernote_user_url, config)

    auth_result = @user_store.authenticate

    user = auth_result.user
    @auth_token = auth_result.authenticationToken

    note_store_url = Rails.application.config.evernote_notestore_url + "/#{user.shardId}"
    @note_store = Evernote::NoteStore.new(note_store_url)
  end

  def index

    page = params[:page] || 1
    @next_page = page.to_i + 1
    @prev_page = page.to_i - 1

    if @prev_page == 0 then
      @prev_page = 1
    end

    @per_page = Rails.application.config.notes_per_page

    @notebooks = @note_store.listNotebooks(@auth_token)
    @found = "Found #{@notebooks.size} notebooks:"
    default_notebook = @notebooks[3]

    filter = Evernote::EDAM::NoteStore::NoteFilter.new;
    filter.notebookGuid = default_notebook.guid
    filter.order = 1
    notes = @note_store.findNotes(@auth_token, filter, @per_page * (page.to_i-1), @per_page)
    notes.notes.each do |note|
      note.created = Time.at(note.created/1000).strftime("%B %-d, %Y")
    end

    @notes = notes

    render :index, :layout => "application"
  end

  def log
    traineo = Traineo.new

    notes = params["notes"]

    @note_array = []
    notes.each do |note|
      retrieved_note = @note_store.getNote(@auth_token, note, false, false, false, false)
      date = Time.at(retrieved_note.created/1000).strftime("%B %-d, %Y")
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
