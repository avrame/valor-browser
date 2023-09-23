module parser
import os { read_file }
import strings { new_builder }

pub struct Parser {
	input string
	mut:
	pos int
}

// Read the current rune without consuming it.
pub fn (p Parser) current_rune() rune  {
	return p.input.runes()[p.pos]
}

// Do the next runes start with the given string?
pub fn (p Parser) starts_with(s string) bool {
	return p.input[p.pos..].starts_with(s)
}

// Return true if all input is consumed.
pub fn (p Parser) eof() bool {
	return p.pos >= p.input.len
}

// Return the current rune, and advance self.pos to the next rune.
pub fn (mut p Parser) consume_rune() rune {
	current_rune := p.input.runes()[p.pos]
	p.pos += 1
	return current_rune
}

// Consume characters until `test` returns false.
pub fn (mut p Parser) consume_while(test fn (rune) bool) string {
	mut result := new_builder(0)
	for !p.eof() && test(p.current_rune()) {
		result.write_string(p.consume_rune().str())
	}
	return result.str()
}

// Consume and discard zero or more whitespace characters.
pub fn (mut p Parser) consume_whitespace() {
	p.consume_while(fn (r rune) bool { return r.str().is_blank() })
}
