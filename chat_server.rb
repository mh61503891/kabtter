# -*- encoding : utf-8 -*-
require 'bundler'
Bundler.require
require 'erb'
require 'set'

# CONFIG
HTTP_LISTEN_PORT = 3000
WS_LISTEN_PORT = 8080


DataMapper.setup(:default, 'sqlite:message.sqlite')

class Message
  include DataMapper::Resource
  property :id, Serial
  property :name, String, :required => true
  property :text, Text, :required => true
  property :created_at, DateTime
  auto_upgrade!
end

class Application < Sinatra::Base
  helpers Sinatra::JSON

  get '/' do
    erb :index
  end

  get '/messages.json' do
    config = {
      :limit => 25,
      :order => [:id.desc]

    }
    if params[:limit]
      if (0..config[:limit]).include?(params[:limit].to_i)
        config[:limit] = params[:limit].to_i
      else
        @errors = ["limit must be between 0 and #{DEFAULT_LIMIT}"]
        return 400
      end
    end
    if params[:id]
      case params[:op]
      when 'gt'
        config[:id.gt] = params[:id]
      when 'lt'
        config[:id.lt] = params[:id]
      when 'eq'
        config[:id] = params[:id]
      else
        config[:id] = params[:id]
      end
    end
    content_type :json
    Message.all(config).to_json
  end
  
  post '/messages.json' do
    @message = Message.create(params)
    unless @message.errors.empty?
      @errors = @message.errors.full_messages
      return 400
    end
    $SOCKETS.each do |socket|
      socket.send(@message.to_json)
    end
  end

  error 400 do
    json @errors
  end

end


require 'rack'

$SOCKETS = Set.new
EventMachine.run do
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => WS_LISTEN_PORT) do |ws|
    ws.onopen {
      $SOCKETS.add(ws) unless $SOCKETS.include?(ws)
    }
    ws.onclose {
      $SOCKETS.delete(ws) if $SOCKETS.include?(ws)
    }
  end
  Application.run!({:port => HTTP_LISTEN_PORT})
end
