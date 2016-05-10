//= require pusher.min

var pusher = new Pusher('78511c9f413a61ee66ee', {
  encrypted: true
});

var display_chat_message = function(data) {
	    	var msg = '<div class="message"><span><span id="person">' + data.username + ':</span>  ' 
	    		+ data.message + "</span></div>";

	      $( "div#chatbox" ).append(msg);
	      console.log("appended");
	      $('div#chatbox').animate({
  			scrollTop:$('div#chatbox').get(0).scrollHeight}, 'fast');
}

var input_is_empty = function() {
	var value = $('input#chatbox').val();
	return _.isEmpty(value);
}

$(document).ready(function() {
	console.log('DOM LOADED');

	$('button#send').click(function() {
		if(!input_is_empty()) {
			var URI = '/chat/message';
			var message = $('input#chatbox').val();
			var payload = {
				message: message
			}
			$.post(URI,payload,function(response) {
				console.log(response);
			});
		}
	});
});
