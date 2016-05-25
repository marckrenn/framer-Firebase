


# 'Firebase REST API Class' module v1.0
# by Marc Krenn, May 24th, 2016 | marc.krenn@gmail.com | @marc_krenn

# Documentation of this Module:
# ------ : ------- Firebase REST API: https://firebase.google.com/docs/reference/rest/database/


# ToDo: add Debug property and functions



# Firebase REST API Class ----------------------------

class exports.Firebase extends Framer.BaseClass


	constructor: (@options={}) ->
		@proj   = @options.projectID ?= null
		@secret = @options.secret    ?= null
		@server = @options.server    ?= undefined # required for WebKit XSS workaround
		super

		if @server is undefined
			Utils.domLoadJSON "https://#{@proj}.firebaseio.com/.settings/owner.json", (a,server) ->
				print "Add ______ server:" + '   "' + server + '"' + " _____ to your instance of Firebase."


	request = (project, secret, path, callback, method, data, parameters) ->

		url = "https://#{project}.firebaseio.com#{path}.json?auth=#{secret}"


		# Ugly coding ahead! Allowing optional paramters to AJAX request

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
		xhttp.onreadystatechange = ->

			unless parameters is undefined
				if parameters.print is "silent" or typeof parameters.download is "string" then return # ugh

			if xhttp.readyState is 4 and callback isnt undefined # uughhh
				callback(JSON.parse(xhttp.responseText))

		xhttp.open(method, url, true)
		xhttp.setRequestHeader("Content-type", "application/json; charset=utf-8")
		xhttp.send(data="#{JSON.stringify(data)}")


	# Available methods

	get:    (path, callback,       parameters) -> request(@proj, @secret, path, callback, "GET",    null, parameters)
	put:    (path, data, callback, parameters) -> request(@proj, @secret, path, callback, "PUT",    data, parameters)
	post:   (path, data, callback, parameters) -> request(@proj, @secret, path, callback, "POST",   data, parameters)
	patch:  (path, data, callback, parameters) -> request(@proj, @secret, path, callback, "PATCH",  data, parameters)
	delete: (path, callback,       parameters) -> request(@proj, @secret, path, callback, "DELETE", null, parameters)


	onChange: (path, callback) ->

		switch Utils.isWebKit()
			when true then url = "https://#{@server}#{path}.json?auth=#{@secret}&ns=#{@proj}&sse=true" # Webkit XSS workaround
			else           url = "https://#{@proj}.firebaseio.com#{path}.json?auth=#{@secret}"

		source = new EventSource(url)

		source.addEventListener "put",   (ev) -> callback(JSON.parse(ev.data).data, "put",   JSON.parse(ev.data).patch)
		source.addEventListener "patch", (ev) -> callback(JSON.parse(ev.data).data, "patch", JSON.parse(ev.data).patch)



