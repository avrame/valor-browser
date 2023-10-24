module css

import arrays { find_first, flat_map, map_indexed }
import html.dom { ElementData, Node }
import datatypes { Set }

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

fn matches_simple_selector(elem &ElementData, selector &Selector) bool {
	// Check type selector
	if selector.tag_name != elem.tag_name {
		return false
	}

	// Check ID selector
	if selector.id != elem.attributes['id'] {
		return false
	}

	// Check class selectors
	elem_classes := elem.classes() as Set[string]
	if selector.class.any(!elem_classes.exists(it)) {
		return false
	}

	// We didn't find any non-matching selector components.
	return true
}

struct MatchedRule {
	specificity Specificity
	rule        Rule
}

fn match_rule(elem &ElementData, rule Rule) ?MatchedRule {
	selector := find_first(rule.selectors, fn [elem] (selector Selector) bool {
		return matches(elem, selector)
	}) or { return none }

	return MatchedRule{selector.specificity(), rule}
}

// Find all CSS rules that match the given element.
fn matching_rules(elem ElementData, stylesheet Stylesheet) []MatchedRule {
	return flat_map[Rule, MatchedRule](stylesheet.rules, fn [elem] (rule Rule) []MatchedRule {
		mut matched_rules := []MatchedRule{}
		matched_rule := match_rule(elem, rule) or { return matched_rules }
		matched_rules << matched_rule
		return matched_rules
	})
}

// Apply styles to a single element, returning the specified values.
fn specified_values(elem ElementData, stylesheet Stylesheet) PropertyMap {
	mut values := PropertyMap{}
	mut matched_rules := matching_rules(elem, stylesheet)

	// Go through the rules from lowest to highest specificity.
	matched_rules.sort_with_compare(fn (a MatchedRule, b MatchedRule) {
		return a.specificity.compare(b.specificity)
	})

	for matched_rule in matched_rules {
		for _, declaration in matched_rule.rule.declarations {
			values[declaration.name] = declaration.value
		}
	}

	return values
}

// Apply a stylesheet to an entire DOM tree, returning a StyledNode tree.
pub fn style_tree(root Node, stylesheet Stylesheet) StyledNode {
	specified_values := match root.node_type {
		.element {
			specified_values(root, stylesheet)
		}
		.text {
			map[string]Value{}
		}
	}

	children := map_indexed[Node, StyledNode](root.children, fn (_ int, child Node) []StyledNode {
		return style_tree(child, stylesheet)
	})

	return StyledNode.new(root, specified_values, children)
}
