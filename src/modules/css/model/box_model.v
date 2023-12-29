module css

import arrays

// Build the tree of LayoutBoxes, but don't perform any layout calculations yet.
fn build_layout_tree(style_node StyledNode) LayoutBox {
	// Create the root box.
	box_type := create_box_type(style_node) or { panic(err) }
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

fn create_box_type(sn StyledNode) !BoxType {
	return match sn.display() {
		.block { BlockNode{sn} }
		.inline { InlineNode{sn} }
		.@none { error('Root node has display: none.') }
	}
}

struct LayoutBox {
	box_type BoxType
mut:
	dimensions Dimensions
	children   []LayoutBox
}

// Constructor function
fn create_layout_box(box BoxType) LayoutBox {
	return LayoutBox{box, Dimensions{}, []LayoutBox{}}
}

// Where a new inline child should go.
fn (mut lb LayoutBox) get_inline_container() &LayoutBox {
	return match lb.box_type {
		InlineNode, AnonymousBlock {
			lb
		}
		BlockNode {
			// If we've just generated an anonymous block box, keep using it.
			// Otherwise, create a new one.
			mut last_child := lb.children.last()
			if last_child.box_type.type_name() != 'AnonymousBlock' {
				lb.children << create_layout_box(AnonymousBlock{})
			}

			last_child = lb.children.last()

			return &last_child
		}
	}
}

fn (mut lb LayoutBox) layout(containing_block Dimensions) {
	match lb.box_type {
		BlockNode {
			lb.layout_block(containing_block)
		}
		InlineNode {} // TODO
		AnonymousBlock {} // TODO
	}
}

fn (mut lb LayoutBox) layout_block(containing_block Dimensions) {
	// Child width can depend on parent width, so we need to calculate
	// this box's width before laying out its children.
	lb.calculate_block_width(containing_block)

	// Determine where the box is located within its container.
	lb.calculate_block_position(containing_block)

	// Recursively lay out the children of this box.
	lb.layout_block_children()

	// Parent height can depend on child height, so `calculate_height`
	// must be called *after* the children are laid out.
	lb.calculate_block_height()
}

fn (lb LayoutBox) calculate_block_width(containing_block Dimensions) {
	style := lb.get_style_node()

	// `width` has initial value `auto`.
	auto := Keyword('auto')
	mut width := style.value('width') or { auto }

	// margin, border, and padding have initial value 0.
	zero := Length{0.0, Unit.px}

	mut margin_left := style.lookup('margin-left', 'margin', &zero)
	mut margin_right := style.lookup('margin-right', 'margin', &zero)
	border_left := style.lookup('border-left-width', 'border-width', &zero)
	border_right := style.lookup('border-right-width', 'border-width', &zero)
	padding_left := style.lookup('padding-left', 'padding', &zero)
	padding_right := style.lookup('padding-right', 'padding', &zero)

	total := arrays.sum([margin_left, margin_right, border_left, border_right, padding_left,
		padding_right, width].map(fn (val Value) f32 {
		return match val {
			Length { val.to_px() }
			else { 0.0 }
		}
	})) or { 0.0 }

	// If width is not auto and the total is wider than the container, treat auto margins as 0.
	if width.str() != auto && total > containing_block.content.width {
		if margin_left.str() == 'auto' {
			margin_left = Length{0.0, .px}
		}
		if margin_right.str() == 'auto' {
			margin_right = Length{0.0, .px}
		}
	}

	underflow := containing_block.content.width - total

	match [width.str() == auto, margin_left.str() == auto, margin_right.str() == auto] {
		// If the values are overconstrained, calculate margin_right.
		[false, false, false] {
			margin_right = Length{margin_right.to_px() + underflow, .px}
		}
		// If exactly one size is auto, its used value follows from the equality.
		[false, false, true] {
			margin_right = Length{underflow, .px}
		}
		[false, true, false] {
			margin_left = Length{underflow, .px}
		}
		// If width is set to auto, any other auto values become 0.
		[true, false, false], [true, false, true], [true, true, false], [true, true, true] {
			if margin_left.str() == auto {
				margin_left = Length{0.0, .px}
			}
			if margin_right.str() == auto {
				margin_right = Length{0.0, .px}
			}

			if underflow >= 0.0 {
				// Expand width to fill the underflow.
				width = Length{underflow, .px}
			} else {
				// Width can't be negative. Adjust the right margin instead.
				width = Length{0.0, .px}
				margin_right = Length{margin_right.to_px() + underflow, .px}
			}
		}
		// If margin-left and margin-right are both auto, their used values are equal.
		[false, true, true] {
			margin_left = Length{underflow / 2.0, .px}
			margin_right = Length{underflow / 2.0, .px}
		}
		else {
			// do nothing
		}
	}
}

fn (lb LayoutBox) calculate_block_position(containing_block Dimensions) {
	style := lb.get_style_node()
	mut d := lb.dimensions

	// margin, border, and padding have initial value 0.
	zero := Length{0.0, .px}

	// If margin-top or margin-bottom is `auto`, the used value is zero.
	d.margin.top = style.lookup('margin-top', 'margin', zero).to_px()
	d.margin.bottom = style.lookup('margin-bottom', 'margin', zero).to_px()

	d.border.top = style.lookup('border-top-width', 'border-width', zero).to_px()
	d.border.bottom = style.lookup('border-bottom-width', 'border-width', zero).to_px()

	d.padding.top = style.lookup('padding-top', 'padding', zero).to_px()
	d.padding.bottom = style.lookup('padding-bottom', 'padding', zero).to_px()

	d.content.x = containing_block.content.x + d.margin.left + d.border.left + d.padding.left

	// Position the box below all the previous boxes in the container.
	d.content.y = containing_block.content.height + containing_block.content.y + d.margin.top +
		d.border.top + d.padding.top
}

fn (mut lb LayoutBox) layout_block_children() {
	mut d := lb.dimensions
	for mut child in lb.children {
		child.layout(d)
		// Track the height so each child is laid out below the previous content.
		d.content.height = d.content.height + child.dimensions.margin_box().height
	}
}

fn (mut lb LayoutBox) calculate_block_height() {
	// If the height is set to an explicit length, use that exact length.
	// Otherwise, just keep the value set by `layout_block_children`.
	height := lb.get_style_node().value('height') or { return }
	if height.type_name() == 'Length' {
		lb.dimensions.content.height = height.to_px()
	}
}

fn (lb LayoutBox) get_style_node() StyledNode {
	return match lb.box_type {
		BlockNode, InlineNode { lb.box_type.style_node }
		AnonymousBlock { panic('Anonymous block box has no style node') }
	}
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
mut:
	// Position of the content area relative to the document origin:
	content Rect
	// Surrounding edges:
	padding EdgeSizes
	border  EdgeSizes
	margin  EdgeSizes
}

// The area covered by the content area plus its padding.
fn (d Dimensions) padding_box() Rect {
	return d.content.expanded_by(d.padding)
}

// The area covered by the content area plus padding and borders.
fn (d Dimensions) border_box() Rect {
	return d.padding_box().expanded_by(d.border)
}

// The area covered by the content area plus padding, borders, and margin.
fn (d Dimensions) margin_box() Rect {
	return d.border_box().expanded_by(d.margin)
}

struct Rect {
mut:
	x      f32
	y      f32
	width  f32
	height f32
}

fn (r Rect) expanded_by(edge EdgeSizes) Rect {
	return Rect{
		x: r.x - edge.left
		y: r.y - edge.top
		width: r.width + edge.left + edge.right
		height: r.height + edge.top + edge.bottom
	}
}

struct EdgeSizes {
mut:
	left   f32
	right  f32
	top    f32
	bottom f32
}
