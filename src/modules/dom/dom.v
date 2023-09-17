module dom

struct NodeBase {
	children []Node
}

pub struct Text {
	NodeBase
	content string
}

pub fn Text.new(data string) Text {
	return Text { content: data }
}

pub struct Element {
	NodeBase
	element_data ElementData
}

pub fn Element.new(name string, attrs AttrMap, children []Node) Element {
	return Element {
		children: children,
		element_data: ElementData{ tag_name: name, attributes: attrs }
	}
}

type Node = Text | Element

struct ElementData {
	tag_name string
	attributes AttrMap
}

type AttrMap = map[string]string
