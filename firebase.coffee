


# 'Firebase REST API Class' module v1.1
# by Marc Krenn, September 21st, 2016 | marc.krenn@gmail.com | @marc_krenn

# Documentation of this Module: https://github.com/marckrenn/framer-Firebase
# ------ : ------- Firebase REST API: https://firebase.google.com/docs/reference/rest/database/


# ToDo:
# Fix onChange "connection", `this´ context



# Firebase REST API Class ----------------------------

class exports.Firebase extends Framer.BaseClass


	@.define "status",
		get: -> @_status # readOnly

	constructor: (@options={}) ->
		@projectID = @options.projectID ?= null
		@secret    = @options.secret    ?= null
		@debug     = @options.debug     ?= false
		@_status                        ?= "disconnected"
		super


		console.log "Firebase: Connecting to Firebase Project '#{@projectID}' ... \n URL: 'https://#{@projectID}.firebaseio.com'" if @debug
		@.onChange "connection"


	request = (project, secret, path, callback, method, data, parameters, debug) ->

		url = "https://#{project}.firebaseio.com#{path}.json?auth=#{secret}"


		unless parameters is undefined
			if parameters.shallow            then url += "&shallow=true"
			if parameters.format is "export" then url += "&format=export"

			switch parameters.print
				when "pretty" then url += "&print=pretty"
				when "silent" then url += "&print=silent"

			if typeof parameters.download is "string"
				url += "&download=#{parameters.download}"
				window.open(url,"_self")


			url += "&orderBy=" + '"' + parameters.orderBy + '"' if typeof parameters.orderBy      is "string"
			url += "&limitToFirst=#{parameters.limitToFirst}"   if typeof parameters.limitToFirst is "number"
			url += "&limitToLast=#{parameters.limitToLast}"     if typeof parameters.limitToLast  is "number"
			url += "&startAt=#{parameters.startAt}"             if typeof parameters.startAt      is "number"
			url += "&endAt=#{parameters.endAt}"                 if typeof parameters.endAt        is "number"
			url += "&equalTo=#{parameters.equalTo}"             if typeof parameters.equalTo      is "number"


		xhttp = new XMLHttpRequest
		console.log "Firebase: New '#{method}'-request with data: '#{JSON.stringify(data)}' \n URL: '#{url}'" if debug
		xhttp.onreadystatechange = =>

			unless parameters is undefined
				if parameters.print is "silent" or typeof parameters.download is "string" then return # ugh

			switch xhttp.readyState
				when 0 then console.log "Firebase: Request not initialized \n URL: '#{url}'"       if debug
				when 1 then console.log "Firebase: Server connection established \n URL: '#{url}'" if debug
				when 2 then console.log "Firebase: Request received \n URL: '#{url}'"              if debug
				when 3 then console.log "Firebase: Processing request \n URL: '#{url}'"            if debug
				when 4
					callback(JSON.parse(xhttp.responseText)) if callback?
					console.log "Firebase: Request finished, response: '#{JSON.parse(xhttp.responseText)}' \n URL: '#{url}'" if debug

			if xhttp.status is "404"
				console.warn "Firebase: Invalid request, page not found \n URL: '#{url}'" if debug


		xhttp.open(method, url, true)
		xhttp.setRequestHeader("Content-type", "application/json; charset=utf-8")
		xhttp.send(data = "#{JSON.stringify(data)}")



	# Available methods

	get:    (path, callback,       parameters) -> request(@projectID, @secret, path, callback, "GET",    null, parameters, @debug)
	put:    (path, data, callback, parameters) -> request(@projectID, @secret, path, callback, "PUT",    data, parameters, @debug)
	post:   (path, data, callback, parameters) -> request(@projectID, @secret, path, callback, "POST",   data, parameters, @debug)
	patch:  (path, data, callback, parameters) -> request(@projectID, @secret, path, callback, "PATCH",  data, parameters, @debug)
	delete: (path, callback,       parameters) -> request(@projectID, @secret, path, callback, "DELETE", null, parameters, @debug)



	onChange: (path, callback) ->


		if path is "connection"

			url = "https://#{@projectID}.firebaseio.com/.json?auth=#{@secret}"
			currentStatus = "disconnected"
			source = new EventSource(url)

			source.addEventListener "open", =>
				if currentStatus is "disconnected"
					@._status = "connected"
					callback("connected") if callback?
					console.log "Firebase: Connection to Firebase Project '#{@projectID}' established" if @debug
				currentStatus = "connected"

			source.addEventListener "error", =>
				if currentStatus is "connected"
					@._status = "disconnected"
					callback("disconnected") if callback?
					console.warn "Firebase: Connection to Firebase Project '#{@projectID}' closed" if @debug
				currentStatus = "disconnected"


		else

			url = "https://#{@projectID}.firebaseio.com#{path}.json?auth=#{@secret}"
			source = new EventSource(url)
			console.log "Firebase: Listening to changes made to '#{path}' \n URL: '#{url}'" if @debug

			source.addEventListener "put", (ev) =>
				callback(JSON.parse(ev.data).data, "put", JSON.parse(ev.data).path, _.tail(JSON.parse(ev.data).path.split("/"),1)) if callback?
				console.log "Firebase: Received changes made to '#{path}' via 'PUT': #{JSON.parse(ev.data).data} \n URL: '#{url}'" if @debug

			source.addEventListener "patch", (ev) =>
				callback(JSON.parse(ev.data).data, "patch", JSON.parse(ev.data).path, _.tail(JSON.parse(ev.data).path.split("/"),1)) if callback?
				console.log "Firebase: Received changes made to '#{path}' via 'PATCH': #{JSON.parse(ev.data).data} \n URL: '#{url}'" if @debug