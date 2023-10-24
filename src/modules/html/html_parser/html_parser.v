module html_parser

import parser { Parser }
import html.dom { AttrMap, Element, Node, Text }

pub struct HtmlParser {
	Parser
}

// Parse a tag or attribute name.
fn (mut p HtmlParser) parse_tag_name() string {
	return p.consume_while(fn (r rune) bool {
		return match r {
			`a`...`z`, `A`...`Z`, `0`...`9` { true }
			else { false }
		}
	})
}

// Parse a single node.
fn (mut p HtmlParser) parse_node() Node {
	return match p.current_rune() {
		`<` { p.parse_element() }
		else { p.parse_text() }
	}
}

// Parse a text node.
fn (mut p HtmlParser) parse_text() Node {
	return Text.new(p.consume_while(fn (r rune) bool {
		return r != `<`
	}))
}

// Parse a single element, including its open tag, contents, and closing tag.
fn (mut p HtmlParser) parse_element() Node {
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
fn (mut p HtmlParser) parse_attr() (string, string) {
	name := p.parse_tag_name()
	assert p.consume_rune() == `=`
	value := p.parse_attr_value()
	return name, value
}

// Parse a quoted value.
fn (mut p HtmlParser) parse_attr_value() string {
	open_quote := p.consume_rune()
	assert open_quote == `"` || open_quote == `'`
	value := p.consume_while(fn [open_quote] (r rune) bool {
		return r != open_quote
	})
	assert p.consume_rune() == open_quote
	return value
}

// Parse a list of name="value" pairs, separated by whitespace.
fn (mut p HtmlParser) parse_attributes() AttrMap {
	mut attributes := map[string]string{}
	for {
		p.consume_whitespace()
		if p.current_rune() == `>` {
			break
		}
		name, value := p.parse_attr()
		attributes[name] = value
	}
	return attributes
}

// Parse a sequence of sibling nodes.
fn (mut p HtmlParser) parse_nodes() []Node {
	mut nodes := []Node{}
	for {
		p.consume_whitespace()
		if p.eof() || p.starts_with('</') {
			break
		}
		nodes << p.parse_node()
	}
	return nodes
}

// Parse an HTML document and return the root element.
pub fn parse_html(source string) Node {
	mut html_parser := HtmlParser{
		pos: 0
		input: source
	}
	mut nodes := html_parser.parse_nodes()

	// If the document contains a root element, just return it. Otherwise, create one.
	if nodes.len == 1 {
		return nodes[0]
	} else {
		return Element.new('html', map[string]string{}, nodes)
	}
}
