currentProject = window.location.pathname.split("/")[window.location.pathname.split("/").length-2]

if Layer.prototype.imageFill == undefined
	Layer.prototype.imageFill = (q) ->
		if !q
			q=""
		if localStorage.getItem("fillImages")
			fillImages = JSON.parse(localStorage.getItem("fillImages"))
			project = _.findIndex(fillImages.projects, {name : currentProject})
			if project != -1
				if @name != ""
					imageNb = _.findIndex(fillImages.projects[project].imageList, {name : @name})
					if(imageNb != -1)
						@image = fillImages.projects[project].imageList[imageNb].url
						@imageSaved = true

		if !@imageSaved
			if !@name
				throw "A name for the layer you want to fill is required"
				return 0
			oReq = new XMLHttpRequest()
			res = "null"
			oReq.onload = ->
				buffer = oReq.response
				res = JSON.parse(buffer)
			oReq.open("GET", "https://api.unsplash.com/photos/random?query=#{q}&client_id=aff8cc7683bb0054396a790d5d0e942a93de3ae93ac83b8d13f6bf89a96b3ba8", false)
			oReq.send()
			if res.errors
				throw "Search term didn't give any result"
				return 0
			showCredit(res, this, q)
			@image = res.urls.regular
else
	throw "Method imageFill already exists"

showCredit = (photo, layer, q) ->
	credit = new Layer
		name: "credit"
		y: Align.bottom(-8)
		height: 30
		borderRadius: 8
		width: Screen.width - 20
		x: Align.center
		clip: true
		opacity: 0
		animOptions:
			time: 0.3
			delay: 0.2

	credit.states.on =
		opacity: 1
		animOptions:
			time: 0.3
	credit.stateCycle()

	keepImage = new TextLayer
		name: "keep"
		parent: credit
		text: "✔︎"
		fontSize: 20
		textAlign: "center"
		color: "#ffffff"
		backgroundColor: "#69C640"
		lineHeight: 1.55
		width: 40
		height: 30
		x: Align.right
		y: 0

	keepImage.states.selected =
		backgroundColor: "#2D561C"
		animOptions:
			time: 0.1

	keepImage.on Events.Tap, ->
		keepImage.stateCycle()
		fillImages = {projects: []}
		if localStorage.getItem("fillImages")
			fillImages = JSON.parse(localStorage.getItem("fillImages"))
		projectNb = _.findIndex(fillImages.projects, {name : currentProject})
		if projectNb < 0
			projectNb = fillImages.projects.length
			newProject = {name: currentProject, imageList: []}
			fillImages.projects.push(newProject)
		fillImages.projects[projectNb].imageList.push({name: layer.name, url : photo.urls.regular})
		localStorage.setItem("fillImages", JSON.stringify(fillImages))
		credit.stateCycle()
		credit.on Events.StateSwitchEnd, ->
			credit.destroy()

	changeImage = new TextLayer
		name: "change"
		parent: credit
		text: "✘"
		fontSize: 20
		textAlign: "center"
		color: "#ffffff"
		backgroundColor: "#D5373C"
		width: 40
		height: 30
		lineHeight: 1.55
		x: Align.right(-40)
		y: 0

	changeImage.states.selected =
		backgroundColor: "#741E21"
		animOptions:
			time: 0.1

	changeImage.on Events.Tap, ->
		changeImage.stateCycle()
		credit.stateCycle()
		credit.on Events.StateSwitchEnd, ->
			credit.destroy()
			layer.imageFill(q)

	creditUnsplash = new TextLayer
		name: "Unsplash"
		parent: credit
		fontSize: 10
		color: "#000000"
		textDecoration: "underline"
		text: "Image from Unsplash"
		y: Align.center
		x: 12
	creditUnsplash.on Events.Tap, ->
		window.open("https://unsplash.com/?utm_source=framerImageFill&utm_medium=referral&utm_campaign=api-credit", "_blank")

	creditPhoto = new TextLayer
		name: "Photographer"
		parent: credit
		fontSize: 10
		color: "#000000"
		textDecoration: "underline"
		text: "Photo by #{photo.user.username}"
		truncate: true
		width: credit.width - 122 - 80
		y: Align.center
		x: 122

	creditPhoto.on Events.Tap, ->
		window.open("https://unsplash.com/@#{photo.user.username}?utm_source=framerImageFill&utm_medium=referral&utm_campaign=api-credit", "_blank")
