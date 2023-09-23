module main
import os { read_file, abs_path }
import dom { Element, Text }
import parser.html { parse }


fn main() {
	// html_dom := Element.new(
	// 	'html',
	// 	{ 'xmlns': 'http://www.w3.org/1999/xhtml' },
	// 	[
	// 		Element.new('body', map[string]string{}, [
	// 			Element.new('h1', map[string]string{}, [
	// 				Text.new('Hello, World!')
	// 			]),
	// 			Element.new('p', map[string]string{}, [
	// 				Text.new('This is a paragraph!')
	// 			]),
	// 		])
	// 	]
	// )
	html_str := read_file(abs_path('html/index.html')) or {
		println(err)
		exit(-1)
	}
	html_dom := parse(html_str)

	println(html_dom)
}
