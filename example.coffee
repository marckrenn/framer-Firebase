

# Please deactivate Auto Refresh and reload manually using CMD+R!


# The required information is located at https://firebase.google.com → Console → YourProject → ...
demoDB = new Firebase
	projectID: "framer-demo" # ... Database → first part of URL
	secret: "K2ZJjo4RXG5nlHEWgjgwBzNkeVJCz9YZAQF8dk9g" # ... Project Settings → Service Accounts → Database Secrets → Show (mouse-over)



# Layers

new BackgroundLayer

slider = new SliderComponent
slider.center()

slider.knob.backgroundColor = "grey"
slider.knob.draggable.momentum = false



# Events + Firebase

slider.knob.onDragEnd ->
	demoDB.put("/sliderValue",slider.value) # `put´ writes data to Firebase,
											 # see http://bit.ly/firebasePut

demoDB.onChange "/sliderValue", (value) -> # Retreives data onLoad and when it was changed
											# see http://bit.ly/firebaseOnChange
	slider.animateToValue(value) unless slider.knob.isDragging


