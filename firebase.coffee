# Documentation of this Module: https://github.com/marckrenn/framer-Firebase
# ------ : ------- Firebase REST API: https://firebase.google.com/docs/reference/rest/database/

# Firebase REST API Class ----------------------------

class exports.Firebase extends Framer.BaseClass


	@.define "status",
		get: -> @_status # readOnly

	constructor: (@options={}) ->
		@projectID = @options.projectID ?= null
		@secret    = @options.secret    ?= null
		@debug     = @options.debug     ?= false
		@_status                        ?= "disconnected"

		@secretEndPoint = if @secret then "?auth=#{@secret}" else "?" # hotfix
		super

		console.log "Firebase: Connecting to Firebase Project '#{@projectID}' ... \n URL: 'https://#{@projectID}.firebaseio.com'" if @debug
		@.onChange "connection"

	request = (project, secret, path, callback, method, data, parameters, debug) ->

		url = "https://#{project}.firebaseio.com#{path}.json#{secret}"

		if parameters?
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
		
		console.log "Firebase: New '#{method}'-request with data: '#{JSON.stringify(data)}' \n URL: '#{url}'" if debug
		
		options =
			method: method
			headers:
				'content-type': 'application/json; charset=utf-8'
		
		if data?
			options.body = JSON.stringify(data)

		r = fetch(url, options)
		.then (res) ->
			if !res.ok then throw Error(res.statusText)
			json = res.json()
			json.then callback
			return json
		.catch (error) => console.warn(error)
		
		return r

	# Third argument can also accept options, rather than callback
	parseArgs = (l, args..., cb) ->
		if typeof args[l-1] is "object"
			args[l] = args[l-1]
			args[l-1] = null

		return cb.apply(null, args)

	# Available methods

	get:    (args...) -> parseArgs 2, args..., (path, 		 callback, parameters) => request(@projectID, @secretEndPoint, path, callback, "GET",    null, parameters, @debug)
	put:    (args...) -> parseArgs 3, args..., (path, data, callback, parameters) => request(@projectID, @secretEndPoint, path, callback, "PUT",    data, parameters, @debug)
	post:   (args...) -> parseArgs 3, args..., (path, data, callback, parameters) => request(@projectID, @secretEndPoint, path, callback, "POST",   data, parameters, @debug)
	patch:  (args...) -> parseArgs 3, args..., (path, data, callback, parameters) => request(@projectID, @secretEndPoint, path, callback, "PATCH",  data, parameters, @debug)
	delete: (args...) -> parseArgs 2, args..., (path, 	  	 callback, parameters) => request(@projectID, @secretEndPoint, path, callback, "DELETE", null, parameters, @debug)


	onChange: (path, callback) ->


		if path is "connection"

			url = "https://#{@projectID}.firebaseio.com/.json#{@secretEndPoint}"
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

			return

		url = "https://#{@projectID}.firebaseio.com#{path}.json#{@secretEndPoint}"
		source = new EventSource(url)
		console.log "Firebase: Listening to changes made to '#{path}' \n URL: '#{url}'" if @debug

		source.addEventListener "put", (ev) =>
			callback(JSON.parse(ev.data).data, "put", JSON.parse(ev.data).path, _.tail(JSON.parse(ev.data).path.split("/"),1)) if callback?
			console.log "Firebase: Received changes made to '#{path}' via 'PUT': #{JSON.parse(ev.data).data} \n URL: '#{url}'" if @debug

		source.addEventListener "patch", (ev) =>
			callback(JSON.parse(ev.data).data, "patch", JSON.parse(ev.data).path, _.tail(JSON.parse(ev.data).path.split("/"),1)) if callback?
			console.log "Firebase: Received changes made to '#{path}' via 'PATCH': #{JSON.parse(ev.data).data} \n URL: '#{url}'" if @debug
