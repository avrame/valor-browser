module css

import arrays { find_first, flat_map, map_indexed }
import html.dom { Element, ElementData, Node, Text }
import datatypes { Set }

// Map from CSS property names to values.
type PropertyMap = map[string]Value

// A node with associated style data.
pub struct StyledNode {
	node     Node // pointer to a DOM node
	children []StyledNode
pub:
	specified_values PropertyMap
}

// Return the specified value of a property if it exists, otherwise `None`.
fn (sn StyledNode) value(name string) ?Value {
	return sn.specified_values[name] or { return none }
}

// The value of the `display` property (defaults to inline).
fn (sn StyledNode) display() Display {
	display := sn.value('display') or { Keyword('inline') }
	return match display {
		Keyword('block') { .block }
		Keyword('none') { .@none }
		else { .inline }
	}
}

fn (sn StyledNode) lookup(name string, fallback_name string, default Value) Value {
	return sn.value(name) or { sn.value(fallback_name) or { return default } }
}

enum Display {
	@none
	inline
	block
}

fn matches(elem &ElementData, selector Selector) bool {
	return matches_simple_selector(elem, selector)
}

fn matches_simple_selector(elem ElementData, selector Selector) bool {
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
	mut values := PropertyMap(map[string]Value{})
	mut matched_rules := matching_rules(elem, stylesheet)

	// Go through the rules from lowest to highest specificity.
	matched_rules.sort_with_compare(fn (a &MatchedRule, b &MatchedRule) int {
		return a.specificity.compare(b.specificity)
	})

	for mr in matched_rules {
		for _, declaration in mr.rule.declarations {
			values[declaration.name] = declaration.value
		}
	}

	return values
}

// Apply a stylesheet to an entire DOM tree, returning a StyledNode tree.
pub fn style_tree(root Node, stylesheet Stylesheet) StyledNode {
	spec_values := match root {
		Element {
			specified_values(root.element_data, stylesheet)
		}
		Text {
			map[string]Value{}
		}
	}

	children := map_indexed[Node, StyledNode](root.children, fn [stylesheet] (_ int, child Node) StyledNode {
		return style_tree(child, stylesheet)
	})

	return StyledNode{root, children, spec_values}
}
