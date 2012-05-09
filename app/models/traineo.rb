class Traineo
  def initialize
    @agent = Mechanize.new

    # Login
    @page = @agent.get 'http://traineo.com/login'
    form = @page.form
    form.send("user[username]", Rails.application.config.traineo_username)
    form.send("user[password]", Rails.application.config.traineo_password)
    page = @agent.submit(form)

    # Get weight page and submit
    @page = @agent.get 'http://traineo.com/weight'
    @form = @page.form
  end

  def log(date, weight)
    @form.date = date
    @form.weight_input = weight

    page = @agent.submit(@form)
  end

end