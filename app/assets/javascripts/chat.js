var input_is_empty = function() {
	var value = $('input#chatbox').val();
	return _.isEmpty(value);
}

$(document).ready(function() {
	console.log('DOM LOADED');

	$('button#send').click(function() {
		if(!input_is_empty()) {
			var URI = '/chat/message'
			var message = $('input#chatbox').val();
			var payload = {
				message:message
			}
			$.post(URI,payload,function(response) {
				console.log(response); // don't need
			});
		}
	});
});
