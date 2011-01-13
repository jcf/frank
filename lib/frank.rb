require 'rubygems'
require 'sinatra/base'
require 'redis'
require 'ohm'
require 'ohm/contrib'
require 'haml'

Ohm.connect

module Frank
  class Document < Ohm::Model
    include Ohm::Timestamping

    attribute :title
    attribute :body
    attribute :created_at

    index :title

    def before_create
      self.created_at = Time.now.strftime('%A')
    end

    def validate
      assert_present :title
      assert_present :body
    end
  end

  class App < Sinatra::Base
    get '/frank.css' do
      sass :frank
    end

    get '/' do
      @documents   = Document.all
      @document  ||= Document.new

      @errors = @document.errors.present do |e|
        e.on [:title, :not_present], "Gimme a title!"
        e.on [:body, :not_present], "How about a body?"
      end

      haml :index
    end

    get '/documents/:id' do
      @document = Document[params[:id]]
      haml :document
    end

    post '/documents' do
      @document = Document.new(params[:document])
      if @document.save
        redirect '/documents/' + @document.id
      else
        redirect '/'
      end
    end

    # delete '/documents/:id' do
    #   Document.delete(id)
    #   redirect_to '/'
    # end
  end
end

at_exit do
  Ohm.flush
end
