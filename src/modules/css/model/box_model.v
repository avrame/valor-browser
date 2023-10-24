module css

// Build the tree of LayoutBoxes, but don't perform any layout calculations yet.
fn build_layout_tree(style_node StyledNode) LayoutBox {
	// Create the root box.
	box_type := create_box_type(style_node.display()) or { panic(err) }
	mut root := create_layout_box(box_type)

	// Create the descendant boxes.
	for _, child in style_node.children {
		match child.display() {
			.block {
				root.children << build_layout_tree(child)
				return root
			}
			.inline {
				root.get_inline_container().children << build_layout_tree(child)
				return root
			}
			.@none {} // Skip nodes with `display: none;`
		}
	}

	return root
}

fn create_box_type(display Display) !BoxType {
	return match display {
		.block { return BlockNode(style_node) }
		.inline { return InlineNode(style_node) }
		.@none { return error('Root node has display: none.') }
	}
}

struct LayoutBox {
	box_type   BoxType
	dimensions Dimensions
	children   []LayoutBox
}

// Where a new inline child should go.
fn (lb LayoutBox) get_inline_container() LayoutBox {
	return match lb.box_type {
		InlineNode, AnonymousBlock {
			return lb
		}
		BlockNode {
			// If we've just generated an anonymous block box, keep using it.
			// Otherwise, create a new one.
			last_child := lb.children.last() or { panic(err) }
			if last_child.box_type.type_name() != 'AnonymousBlock' {
				lb.children << AnonymousBlock{}
			}

			return lb.children.last()
		}
	}
}

// Constructor function
fn create_layout_box(box BoxType) LayoutBox {
	return LayoutBox{box, Dimensions{}, []LayoutBox{}}
}

type BoxType = AnonymousBlock | BlockNode | InlineNode

struct BlockNode {
	style_node StyledNode
}

struct InlineNode {
	style_node StyledNode
}

struct AnonymousBlock {}

// CSS box model. All sizes are in px.

struct Dimensions {
	// Position of the content area relative to the document origin:
	content Rect
	// Surrounding edges:
	padding EdgeSizes
	border  EdgeSizes
	margin  EdgeSizes
}

struct Rect {
	x      f32
	y      f32
	width  f32
	height f32
}

struct EdgeSizes {
	left   f32
	right  f32
	top    f32
	bottom f32
}
