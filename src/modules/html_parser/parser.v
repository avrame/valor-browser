module html_parser
import os { read_file }
import strings { new_builder }
import dom { Node, Text, Element, AttrMap }

struct Parser {
	input string
	mut:
	pos int
}

// Read the current rune without consuming it.
fn (p Parser) current_rune() rune  {
	return p.input.runes()[p.pos]
}

// Do the next runes start with the given string?
fn (p Parser) starts_with(s string) bool {
	return p.input[p.pos..].starts_with(s)
}

// Return true if all input is consumed.
fn (p Parser) eof() bool {
	return p.pos >= p.input.len
}

// Return the current rune, and advance self.pos to the next rune.
fn (mut p Parser) consume_rune() rune {
	current_rune := p.input.runes()[p.pos]
	p.pos += 1
	return current_rune
}

// Consume characters until `test` returns false.
fn (mut p Parser) consume_while(test fn (rune) bool) string {
	mut result := new_builder(0)
	for !p.eof() && test(p.current_rune()) {
		result.write_string(p.consume_rune().str())
	}
	return result.str()
}

// Consume and discard zero or more whitespace characters.
fn (mut p Parser) consume_whitespace() {
	p.consume_while(fn (r rune) bool { return r.str().is_blank() })
}

// Parse a tag or attribute name.
fn (mut p Parser) parse_tag_name() string {
	return p.consume_while(fn (r rune) bool {
		return match r {
			`a`...`z`, `A`...`Z`, `0`...`9` { true }
			else { false }
		}
	})
}

// Parse a single node.
fn (mut p Parser) parse_node() Node {
	return match p.current_rune() {
		`<`		{ p.parse_element() }
		else 	{ p.parse_text() }
	}
}

// Parse a text node.
fn (mut p Parser) parse_text() Node {
	return Text.new(p.consume_while(fn (r rune) bool { return r != `<` }))
}

// Parse a single element, including its open tag, contents, and closing tag.
fn (mut p Parser) parse_element() Node {
	// Opening tag.
	assert p.consume_rune() == `<`
	tag_name := p.parse_tag_name()
	attrs := p.parse_attributes()
	assert p.consume_rune() == `>`

	// Contents.
	children := p.parse_nodes()

	// Closing tag.
	assert p.consume_rune() == `<`
	assert p.consume_rune() == `/`
	assert p.parse_tag_name() == tag_name
	assert p.consume_rune() == `>`

	return Element.new(tag_name, attrs, children)
}

// Parse a single name="value" pair.
fn (mut p Parser) parse_attr() (string, string) {
	name := p.parse_tag_name();
	assert p.consume_rune() == `=`
	value := p.parse_attr_value()
	return name, value
}

// Parse a quoted value.
fn (mut p Parser) parse_attr_value() string {
	open_quote := p.consume_rune()
	assert open_quote == `"` || open_quote == `'`
	value := p.consume_while(
		fn [open_quote](r rune) bool {
			return r != open_quote
		}
	)
	assert p.consume_rune() == open_quote
	return value
}

// Parse a list of name="value" pairs, separated by whitespace.
fn (mut p Parser) parse_attributes() AttrMap {
	mut attributes := map[string]string
	for {
		p.consume_whitespace()
		if p.current_rune() == `>` { break }
		name, value := p.parse_attr()
		attributes[name] = value
	}
	return attributes
}

// Parse a sequence of sibling nodes.
fn (mut p Parser) parse_nodes() []Node {
	mut nodes := []Node{}
	for {
		p.consume_whitespace();
		if p.eof() || p.starts_with("</") { break }
		nodes << p.parse_node()
	}
	return nodes
}

// Parse an HTML document and return the root element.
pub fn parse(source string) Node {
	mut parser := Parser { pos: 0, input: source }
	mut nodes := parser.parse_nodes()

	// If the document contains a root element, just return it. Otherwise, create one.
	if nodes.len == 1 {
		return nodes[0]
	} else {
		return Element.new('html', map[string]string{}, nodes)
	}
}
