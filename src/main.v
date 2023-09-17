module main
import dom { Element, Text }


fn main() {
	html := Element.new(
		'html',
		{ 'xmlns': 'http://www.w3.org/1999/xhtml' },
		[
			Element.new('body', map[string]string{}, [
				Element.new('h1', map[string]string{}, [
					Text.new('Hello, World!')
				]),
				Element.new('p', map[string]string{}, [
					Text.new('This is a paragraph!')
				]),
			])
		]
	)
	println(html)
}
