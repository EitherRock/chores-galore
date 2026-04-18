extends CanvasLayer

@onready var left_page: RichTextLabel = $Panel/LeftPage
@onready var right_page: RichTextLabel = $Panel/RightPage

var current_page = 0
var pages = []
var book_data = null


func show_text(data):
	book_data = data
	pages = data.pages

	current_page = 0
	visible = true

	update_pages()


func update_pages():
	# PAGE 0 = TITLE PAGE (RIGHT ONLY)
	if current_page == 0:
		left_page.text = ""
		right_page.text = book_data.title
		right_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_page.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		right_page.add_theme_font_size_override('normal_font_size', 30)
		return

	# REAL CONTENT STARTS AT PAGE 1
	right_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	right_page.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	right_page.add_theme_font_size_override('normal_font_size', 16)

	var left_index = current_page
	var right_index = current_page + 1

	left_page.text = pages[left_index] if left_index < pages.size() else ""
	right_page.text = pages[right_index] if right_index < pages.size() else ""


func next_page():
	# Special case: leaving title page
	if current_page == 0:
		current_page = 1
		update_pages()
		return

	# Normal paging (step by 2)
	if current_page + 2 < pages.size():
		current_page += 2
		update_pages()


func prev_page():
	# If we're at first real page, go back to title
	if current_page <= 1:
		current_page = 0
		update_pages()
		return

	# Normal backwards paging
	if current_page - 2 >= 1:
		current_page -= 2
		update_pages()


#extends CanvasLayer
#
#@onready var left_page: RichTextLabel = $Panel/LeftPage
#@onready var right_page: RichTextLabel = $Panel/RightPage
#
#var current_page = 0
#var pages = []
#
#func show_text(book_data):
	#print('bookui shoiwng text')
	#pages = book_data.pages
	#visible = true
	#
	#if current_page == 0:
		#right_page.text = book_data.title
		#right_page.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#right_page.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		#right_page.add_theme_font_size_override('normal_font_size', 24)
	#else:
		#left_page.text = pages[current_page]
		#right_page.text = pages[current_page + 1]
		#
#
#func next_page():
	#if current_page < pages.size() - 1:
		#current_page += 1
#
#func prev_page():
	#if current_page > 0:
		#current_page -= 1
#
