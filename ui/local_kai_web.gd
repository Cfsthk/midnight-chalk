extends RefCounted

# Godot Web cannot read system font files. CSS local() can use a face that the
# browser already exposes. Cache one alpha mask per answer and draw it in Godot.
const CSS_NAME := "MidnightLocalKai"
const LOCAL_SOURCES := 'local("BiauKaiHK-Regular"), local("BiauKaiHK"), local("BiauKaiTC-Regular"), local("BiauKai"), local("DFKai-SB"), local("KaiU"), local("標楷體-港澳"), local("標楷體")'

var _face: JavaScriptObject
var _canvas: JavaScriptObject
var _context: JavaScriptObject
var _unavailable: JavaScriptObject
var _masks: Dictionary[String, Texture2D] = {}


func _init() -> void:
	var document := JavaScriptBridge.get_interface("document")
	if not document or not document.fonts or not JavaScriptBridge.get_interface("FontFace"):
		return
	_face = JavaScriptBridge.create_object("FontFace", CSS_NAME, LOCAL_SOURCES)
	document.fonts.add(_face)
	# Keep the optional rejection handler alive for the lifetime of the JS promise.
	_unavailable = JavaScriptBridge.create_callback(func(_args: Array) -> void: pass)
	_face.load().catch(_unavailable)
	_canvas = document.createElement("canvas")
	_context = _canvas.getContext("2d")


func mask_for(text: String, point_size: int) -> Texture2D:
	if not _face or not _context or _face.status != "loaded":
		return null
	if _masks.has(text):
		return _masks[text]
	var style := "%dpx %s" % [point_size, CSS_NAME]
	_context.font = style
	var bounds: JavaScriptObject = _context.measureText(text)
	var left: float = bounds.actualBoundingBoxLeft
	var ascent: float = bounds.actualBoundingBoxAscent
	var width := ceili(left + float(bounds.actualBoundingBoxRight)) + 4
	var height := ceili(ascent + float(bounds.actualBoundingBoxDescent)) + 4
	if width <= 4 or height <= 4:
		return null
	_canvas.width = width
	_canvas.height = height
	_context.font = style
	_context.fillStyle = "#ffffff"
	_context.fillText(text, left + 2.0, ascent + 2.0)
	var pixels: JavaScriptObject = _context.getImageData(0, 0, width, height).data
	var bytes := JavaScriptBridge.js_buffer_to_packed_byte_array(pixels)
	if bytes.size() != width * height * 4:
		return null
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, bytes)
	image.convert(Image.FORMAT_LA8)
	var mask := ImageTexture.create_from_image(image)
	_masks[text] = mask
	return mask
