$(function(){
    // CONFIG
    var config = {ws: {}, message: {}};
    config.ws.protocol = (location.protocol=='https:') ? 'wss' : 'ws';
    config.ws.port = 8080;
    config.ws.url = config.ws.protocol + '://' + location.hostname + ':' + config.ws.port;
    config.message.limit = 25;
    // WEBSOCKET
    try{
	new WebSocket(config.ws.url).addEventListener('message', function(event){
	    display_message($.parseJSON(event.data), 'top');
	}, false);
    }catch(e){
	noty({
	    text: 'お使いのブラウザはWebSocket非対応です。',
	    layout: 'topCenter'
	});
    }
    // EVENTS
//    $('#message-form-name').keypress(function(event){ if(event.keyCode == 13){
//	post_message();
//    }});
//    $('#message-form-text').keypress(function(event){ if(event.keyCode == 13){
//	post_message();
//    }});
    $('#message-form-button').click(function(event){
	post_message();
    });
    $('#messages-loading-bar').click(function(event){
	get_messages(config.message.limit, 'lt', $last);
    });
    // FUNCTION
    var $last;
    function get_messages(limit, op, id){
	$.getJSON('messages.json', {
	    op: op,
	    id: id,
	    limit: limit
	}).success(function(data) {
	    $.each(data, function(index, value){
		display_message(value, 'bottom', index*20);
		$last = value.id;
	    });
	    if (data.length < limit){
		$('#messages-loading-bar').fadeOut("slow");
	    }
	});
    };
    function post_message(){
	$.post('messages.json', {
	    name: $('#message-form-name').val(),
	    text: $('#message-form-text').val()
	}).success(function(){
	    $('#message-form-text').val('');
	}).error(function(response){
	    text = $.map($.parseJSON(response.responseText), function(n, i){
		return n + '.';
	    }).join(' ');
	    noty({
		text: text,
		layout: 'topCenter'
	    });
	});
    }
    function display_message(message, direction, delay){
	item = $('#message-tmpl').tmpl(message);
	item.hide();
	if(direction == 'top'){
	    $('#messages').prepend(item);
	}else if(direction == 'bottom'){
	    $('#messages').append(item);
	}
	item.delay(delay).fadeIn("slow");
    }
    // INITIALIZE
    $("input").uniform();
    get_messages(config.message.limit, 'gt');
});
