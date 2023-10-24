module css

import encoding.hex
import parser { Parser }
import css_types {
	Declaration,
	Rule,
	Selector,
	Specificity,
	Stylesheet,
	Unit,
	Value,
}

struct CssParser {
	Parser
}

// Parse a whole CSS stylesheet.
pub fn parse_css(source string) Stylesheet {
	mut parser := CssParser{
		pos: 0
		input: source
	}
	return Stylesheet{
		rules: parser.parse_rules()
	}
}

// Parse one simple selector, e.g.: `type#id.class1.class2.class3`
fn (mut p CssParser) parse_simple_selector() Selector {
	mut selector := Selector{}
	for !parser.eof() {
		match parser.current_rune() {
			`#` {
				parser.consume_rune()
				selector.id = parser.parse_identifier()
			}
			`.` {
				parser.consume_rune()
				selector.class << parser.parse_identifier()
			}
			`*` {
				// universal selector
				parser.consume_rune()
			}
			else {
				if valid_identifier_rune(parser.current_rune()) {
					selector.tag_name = parser.parse_identifier()
				} else {
					break
				}
			}
		}
	}
	return selector
}

// Parse a list of rule sets, separated by optional whitespace.
fn (parser CssParser) parse_rules() []Rule {
	mut rules := []Rule{}
	for {
		parser.consume_whitespace()
		if parser.eof() {
			break
		}
		rules << parser.parse_rule()
	}
	return rules
}

fn (parser CssParser) parse_rule() Rule {
	return Rule{
		selectors: parser.parse_selectors()
		declarations: parser.parse_declarations()
	}
}

// Parse a comma-separated list of selectors.
fn (parser CssParser) parse_selectors() []Selector {
	mut selectors := []Selector{}
	for {
		selectors << parser.parse_simple_selector()
		parser.consume_whitespace()
		match parser.current_rune() {
			`,` {
				parser.consume_rune()
				parser.consume_whitespace()
			}
			`{` {
				break
			} // start of declarations
			else {
				panic
				!('Unexpected character {} in selector list')
			}
		}
	}
	// Return selectors with highest specificity first, for use in matching.
	selectors.sort_with_compare(fn (a &Specificity, b &Specificity) int {
		return a.compare(b)
	})
	return selectors
}

// Parse a list of declarations enclosed in `{ ... }`.
fn (parser CssParser) parse_declarations() []Declaration {
	assert parser.consume_rune() == `{`
	mut declarations := []Declaration{}
	for {
		parser.consume_whitespace()
		if parser.current_rune() == '}' {
			parser.consume_rune()
			break
		}
		declarations << parser.parse_declaration()
	}
	return declarations
}

// Parse one `<property>: <value>;` declaration.
fn (parser CssParser) parse_declaration() Declaration {
	property_name := parser.parse_identifier()
	parser.consume_whitespace()

	assert parser.consume_rune() == `:`
	parser.consume_whitespace()

	value := parser.parse_value()
	parser.consume_whitespace()

	assert parser.consume_rune() == `;`

	return Declaration{property_name, value}
}

// Methods for parsing values:

fn (parser CssParser) parse_value() Value {
	return match parser.next_char() {
		`0`...`10` { parser.parse_length() }
		'#' { parser.parse_color() }
		else { parser.parse_identifier() }
	}
}

fn (parser CssParser) parse_length() Value {
	return Length{
		value: parser.parse_float()
		unit: parser.parse_unit()
	}
}

fn (parser CssParser) parse_float() f32 {
	return parser.consume_while(fn (r rune) bool {
		return match r {
			`0`...`9`, `.` { true }
			else { false }
		}
	})
}

fn (parser CssParser) parse_unit() Unit {
	return match parser.parse_identifier() {
		'px' {}
		else { panic('unrecognized unit') }
	}
}

fn (parser CssParser) parse_color() Value {
	assert parser.consume_char() == `#`
	return Color{
		r: parser.parse_hex_pair()
		g: parser.parse_hex_pair()
		b: parser.parse_hex_pair()
		a: 255
	}
}

/// Parse two hexadecimal digits.
fn (parser CssParser) parse_hex_pair() u8 {
	hex_str := parser.input[parser.pos..parser.pos + 2]
	parser.pos += 2
	return encoding.hex(hex_str)
}

/// Parse a property name or keyword.
fn (parser CssParser) parse_identifier() string {
	parser.consume_while(valid_identifier_rune)
}

fn valid_identifier_rune(r rune) bool {
	return match r {
		`a`...`z`, `A`...`Z`, `0`...`9`, `-`, `_` { return true } // TODO: Include U+00A0 and higher.
		else { return false }
	}
}
