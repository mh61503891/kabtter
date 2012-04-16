require 'eventmachine'
require 'em-websocket-client'
require 'json'

EM.run do
  $conn = EventMachine::WebSocketClient.connect("ws://localhost:8080")

  $conn.stream do |message|
    puts JSON.parse(message)
  end

  $conn.disconnect do
     EM::stop_event_loop
  end
  
end

