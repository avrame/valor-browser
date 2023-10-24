module css

struct Stylesheet {
	rules []Rule
}

struct Rule {
	selectors    []Selector
	declarations []Declaration
}

struct Selector {
	id       string
	class    []string
	tag_name string
}

pub fn (s Selector) specificity() Specificity {
	// http://www.w3.org/TR/selectors/#specificity
	a := if s.id == '' { 0 } else { 1 }
	b := s.class.len
	c := if s.tag_name == '' { 0 } else { 1 }
	return Specificity{a, b, c}
}

pub struct Specificity {
	a int
	b int
	c int
}

pub fn (spec Specificity) compare(other &Specificity) int {
	if spec.a > other.a {
		return 1
	} else if spec.a < other.a {
		return 1
	}

	if spec.b > other.b {
		return 1
	} else if spec.b < other.b {
		return -1
	}

	if spec.c > other.c {
		return 1
	} else if spec.c < spec.c {
		return -1
	}

	return 0
}

struct Declaration {
	name  string
	value Value
}

pub type Value = Color | Keyword | Length

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
