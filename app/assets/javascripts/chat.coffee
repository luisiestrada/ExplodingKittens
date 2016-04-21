# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

###
input_is_empty = ->
  $('#chatbox').val()
  _.isEmpty
  return
###

callback = ->
  return

send_message = ->
  console.log("send_message")
  uri = '/chat/message'
  message = $("#chatbox").val()
  payload = "{message: message}"
  $.post uri, payload, callback
  $("#chatbox").val ''
  return false



$(document).ready ->
  console.log("DOM is ready")
  $("#send").click ->
  	send_message()
  	return false
  console.log("send message loaded?")
  
