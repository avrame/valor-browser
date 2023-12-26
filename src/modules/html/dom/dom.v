module dom

import datatypes { Set }

struct NodeBase {
	children []Node
}

pub enum NodeType {
	text
	element
}

pub type Node = Element | Text

pub struct Text {
	NodeBase
	node_type NodeType = .text
	content   string
}

pub fn Text.new(data string) Text {
	return Text{
		content: data
	}
}

pub struct Element {
	NodeBase
	node_type    NodeType = .element
	element_data ElementData
}

pub fn Element.new(name string, attrs AttrMap, children []Node) Element {
	return Element{
		children: children
		element_data: ElementData{
			tag_name: name
			attributes: attrs
		}
	}
}

pub struct ElementData {
pub:
	tag_name   string
	attributes AttrMap
}

pub type AttrMap = map[string]string

pub fn (ed ElementData) id() ?string {
	return ed.attributes['id']
}

pub fn (ed ElementData) classes() Set[string] {
	mut class_set := Set[string]{}
	class_attr := ed.attributes['class'] or { return class_set }
	for class in string(class_attr).split(' ') {
		class_set.add(class)
	}
	return class_set
}
