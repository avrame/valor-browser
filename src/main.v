module main

import os { abs_path, read_file }
import html.html_parser { parse_html }

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
	html_dom := parse_html(html_str)

	println(html_dom)
}
