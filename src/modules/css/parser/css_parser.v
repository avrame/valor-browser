module css

import encoding.hex
import parser { Parser }
import css.css_types {
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
	for !p.eof() {
		match p.current_rune() {
			`#` {
				p.consume_rune()
				selector.id = p.parse_identifier()
			}
			`.` {
				p.consume_rune()
				selector.class << p.parse_identifier()
			}
			`*` {
				// universal selector
				p.consume_rune()
			}
			else {
				if valid_identifier_rune(p.current_rune()) {
					selector.tag_name = p.parse_identifier()
				} else {
					break
				}
			}
		}
	}
	return selector
}

// Parse a list of rule sets, separated by optional whitespace.
fn (p CssParser) parse_rules() []Rule {
	mut rules := []css_types.Rule{}
	for {
		p.consume_whitespace()
		if p.eof() {
			break
		}
		rules << p.parse_rule()
	}
	return rules
}

fn (p CssParser) parse_rule() Rule {
	return Rule{
		selectors: p.parse_selectors()
		declarations: p.parse_declarations()
	}
}

// Parse a comma-separated list of selectors.
fn (p CssParser) parse_selectors() []Selector {
	mut selectors := []css_types.Selector{}
	for {
		selectors << p.parse_simple_selector()
		p.consume_whitespace()
		match p.current_rune() {
			`,` {
				p.consume_rune()
				p.consume_whitespace()
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
		if a < b {
			return -1
		}
		if a > b {
			return 1
		}
		return 0
	})
	return selectors
}

// Parse a list of declarations enclosed in `{ ... }`.
fn (p CssParser) parse_declarations() []Declaration {
	assert p.consume_rune() == `{`
	mut declarations := []css_types.Declaration{}
	for {
		p.consume_whitespace()
		if p.current_rune() == '}' {
			p.consume_rune()
			break
		}
		declarations << p.parse_declaration()
	}
	return declarations
}

// Parse one `<property>: <value>;` declaration.
fn (p CssParser) parse_declaration() Declaration {
	property_name := p.parse_identifier()
	p.consume_whitespace()

	assert p.consume_rune() == `:`
	p.consume_whitespace()

	value := p.parse_value()
	p.consume_whitespace()

	assert p.consume_rune() == `;`

	return Declaration{property_name, value}
}

// Methods for parsing values:

fn (p CssParser) parse_value() Value {
	return match p.next_char() {
		`0`...`10` { p.parse_length() }
		'#' { p.parse_color() }
		else { p.parse_identifier() }
	}
}

fn (p CssParser) parse_length() Value {
	return Length{
		value: p.parse_float()
		unit: p.parse_unit()
	}
}

fn (p CssParser) parse_float() f32 {
	return p.consume_while(fn (r rune) bool {
		return match r {
			`0`...`9`, `.` { true }
			else { false }
		}
	})
}

fn (p CssParser) parse_unit() Unit {
	return match p.parse_identifier() {
		'px' {}
		else { panic('unrecognized unit') }
	}
}

fn (p CssParser) parse_color() Value {
	assert p.consume_char() == `#`
	return Color{
		r: p.parse_hex_pair()
		g: p.parse_hex_pair()
		b: p.parse_hex_pair()
		a: 255
	}
}

/// Parse two hexadecimal digits.
fn (p CssParser) parse_hex_pair() u8 {
	hex_str := p.input[p.pos..p.pos + 2]
	p.pos += 2
	return encoding.hex(hex_str)
}

/// Parse a property name or keyword.
fn (p CssParser) parse_identifier() string {
	p.consume_while(valid_identifier_rune)
}

fn valid_identifier_rune(r rune) bool {
	return match r {
		`a`...`z`, `A`...`Z`, `0`...`9`, `-`, `_` { return true } // TODO: Include U+00A0 and higher.
		else { return false }
	}
}
