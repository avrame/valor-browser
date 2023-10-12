module css

import html.dom { ElementData, Node }

// Map from CSS property names to values.
type PropertyMap = map[string]Value

// A node with associated style data.
struct StyledNode {
	node             &Node // pointer to a DOM node
	specified_values PropertyMap
	children         []StyledNode
}

fn matches(elem &ElementData, selector &Selector) bool {
	return matches_simple_selector(elem, selector)
}

fn matches_simple_selector() bool {
}
