module css_types

struct Stylesheet {
	rules []Rule
}

struct Rule {
	selectors    []Selector
	declarations []Declaration
}

struct Selector {
	id       string
	class    string
	tag_name string
}

pub fn (s Selector) specificity() Specificity {
	// http://www.w3.org/TR/selectors/#specificity
	a := s.id.len
	b := s.class.len
	c := s.tag_name.len
	return Specificity{a, b, c}
}

pub struct Specificity {
	a int
	b int
	c int
}

struct Declaration {
	name  string
	value Value
}

type Value = Color | Keyword | Length

type Keyword = string

struct Length {
	value f32
	unit  Unit
}

pub enum Unit {
	px
	em
	rem
	percent
}

struct Color {
	r u8
	g u8
	b u8
	a u8
}
