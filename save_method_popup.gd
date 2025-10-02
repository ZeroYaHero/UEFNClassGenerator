class_name SaveMethodPopup extends Popup

signal clicked(Method)

enum Method { SAVE, COPY, GENERATE}

func _ready() -> void:
	$VBoxContainer/HBoxContainer/Button.pressed.connect(clicked.emit.bind(Method.SAVE))
	$VBoxContainer/HBoxContainer/Button2.pressed.connect(clicked.emit.bind(Method.COPY))
	$VBoxContainer/HBoxContainer/Button3.pressed.connect(clicked.emit.bind(Method.GENERATE))
