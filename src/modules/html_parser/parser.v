module html_parser
import strings { new_builder }
import dom { Node, Text, Element }

struct Parser {
	pos int
	input string
}

// Read the current character without consuming it.
fn (p Parser) next_char() rune  {
	return p.input.runes()[p.pos + 1..p.pos + 2]
}

// Do the next characters start with the given string?
fn (p Parser) starts_with(s: string) bool {
	p.input.starts_with(s)
}

// Return true if all input is consumed.
fn (p Parser) eof() bool {
	p.pos >= p.input.len
}

// Return the current character, and advance self.pos to the next character.
fn (p Parser) consume_char() rune {
	cur_char = p.input.runes()[p.pos..p.pos + 1]
	p.pos += 1
	return cur_char
}

// Consume characters until `test` returns false.
fn (p Parser) consume_while(test fn (rune) bool) {
	mut result = new_builder(0)
	for !p.eof() && test(p.next_char()) {
		result.write_string(p.consume_char().string())
	}
	return result
}

// Consume and discard zero or more whitespace characters.
fn (p Parser) consume_whitespace() {
	p.consume_while(fn (r rune) bool { return r.string().is_blank() })
}

// Parse a tag or attribute name.
fn (p Parser) parse_tag_name() string {
	return p.consume_while(fn (r rune) bool {
		return match r {
			`a`...`z`, `A`...`Z`, `0`...`9` { true }
			else { false }
		}
	)
}

// Parse a single node.
fn (p Parser) parse_node() Node {
	return match p.next_char() {
		`<`		{ p.parse_element() }
		else 	{ p.parse_text() }
	}
}

// Parse a text node.
fn (p Parser) parse_text() Node {
	return Text.new(p.consume_while(fn (r rune) { return r != `<` })
}

// Parse a single element, including its open tag, contents, and closing tag.
fn (p Parser) parse_element() Node {
	// Opening tag.
	assert!(p.consume_char() == `<`)
	tag_name := p.parse_tag_name()
	attrs := p.parse_attributes()
	assert!(p.consume_char() == `>`)

	// Contents.
	children := p.parse_nodes()

	// Closing tag.
	assert!(p.consume_char() == `<`)
	assert!(p.consume_char() == `/`)
	assert!(p.parse_tag_name() == tag_name)
	assert!(p.consume_char() == `>`)

	return Element.new(tag_name, attrs, children)
}
