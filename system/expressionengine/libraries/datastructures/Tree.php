<?php  if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**
 * ExpressionEngine - by EllisLab
 *
 * @package		ExpressionEngine
 * @author		EllisLab Dev Team
 * @copyright	Copyright (c) 2003 - 2012, EllisLab, Inc.
 * @license		http://ellislab.com/expressionengine/user-guide/license.html
 * @link		http://ellislab.com
 * @since		Version 2.0
 * @filesource
 */
 
// ------------------------------------------------------------------------

/*

 THIS FILE CONTAINS:

 EE_Tree		 - singleton tree builder
 EE_TreeNode	 - main tree object (returned from EE_Tree::load)
 EE_TreeIterator - iteration helper (returned from EE_TreeNode::flat_iterator)

*/

// ------------------------------------------------------------------------

/**
 * ExpressionEngine Tree Factory Class
 *
 * @package		ExpressionEngine
 * @subpackage	Core Datastructures
 * @category	Core
 * @author		EllisLab Dev Team
 * @link		http://ellislab.com
 */
class EE_Tree {

	/**
	 * Tree Factory
	 *
	 * Takes an array of rows that each have an id and parent id (as you
	 * would get from the db) and returns a tree structure
	 *
	 * @param data - array of array('unique_id' => x, 'parent_id' => y, ...data)
	 * @param config array
	 *		- key : data's unique id key
	 *		- parent_id: data's parent_id key
	 *
	 * @return Object<ImmutableTree>
	 */
	public function from_list($data, array $conf = NULL)
	{
		$conf = array_merge(
			array(
				'id'	 		 => 'id',
				'parent' 	 	 => 'parent_id',
				'class_name'	 => 'EE_TreeNode'
			),
			(array) $conf
		);

		if ( ! isset($conf['name_key']))
		{
			$conf['name_key'] = $conf['id'];
		}

		return $this->_build_tree($data, $conf);
	}

	// --------------------------------------------------------------------

	/**
	 * Flatten the tree to a list of data objects.
	 *
	 * @return array similar to what was passed to EE_Tree::load
	 */
	public function to_list(EE_TreeNode $tree)
	{
		$it = $this->iterator();
		$result = array();

		foreach ($it as $node)
		{
			$result[] = $node->data();
		}

		return $result;
	}

	// --------------------------------------------------------------------

	/**
	 * Tree Builder
	 *
	 * Re-sorts the data from from_list() and turns it into two datastructures:
	 *
	 * An array of tree root nodes, with children in the __children__ key
	 * of their respective parents. Thus forming a tree as a nested array.
	 * 
	 * A lookup table of id => row, where each item is actually a reference
	 * into the tree. This way we can do quick by-index lookups.
	 *
	 * @param data - array of array('unique_id' => x, 'parent_id' => y, ...data)
	 * @param unique id key
	 * @param parent id key
	 *
	 * @return Object<ImmutableTree>
	 */
	protected function _build_tree($data, $conf)
	{
		$nodes = array();

		$child_key = $conf['id'];
		$parent_key = $conf['parent'];

		$name = $conf['name_key'];
		$klass = $conf['class_name'];

		// First we create a lookup table of id => object
		// This lets us build the tree on references which
		// will in turn allow for quick subtree lookup.
		foreach ($data as $row)
		{
			$id = $row[$child_key];
			$nodes[$id] = new $klass($row[$name], $row);
		}

		$tree = new EE_TreeNode('__root__');

		// And now build the actual tree by assigning children
		foreach ($data as $row)
		{
			$parent = $row[$parent_key];
			$node = $nodes[$row[$child_key]];

			if (isset($nodes[$parent]))
			{
				$nodes[$parent]->add($node);
			}
			else
			{
				$tree->add($node);
			}
		}

		return $tree;
	}
}

// ------------------------------------------------------------------------

/**
 * ExpressionEngine Tree Node Class
 *
 * @package		ExpressionEngine
 * @subpackage	Core Datastructures
 * @category	Core
 * @author		EllisLab Dev Team
 * @link		http://ellislab.com
 *
 * If you're completely new to this ideas:
 * @see http://xlinux.nist.gov/dads/HTML/tree.html
 */
class EE_TreeNode {

	protected $name;
	protected $data;

	protected $parent;
	protected $children;
	protected $children_names;

	private $_frozen = FALSE;
	
	public function __construct($name, $payload = NULL)
	{
		$this->name = $name;
		$this->data = $payload;

		$this->children = array();
		$this->children_names = array();
	}

	// --------------------------------------------------------------------

	/**
	 * Retrieve the payload data.
	 *
	 * If they payload is an array we treat the entire object as an
	 * accessor to the payload. Otherwise the key must be "data" to
	 * mimic regular object access.
	 *
	 * @return void
	 */
	public function __get($key)
	{
		if (is_array($this->data))
		{
			return $this->data[$key];
		}
		if ($key == 'data')
		{
			return $this->data;
		}

		throw new InvalidArgumentException('Payload cannot be retrieved.');
	}

	// --------------------------------------------------------------------

	/**
	 * Change the payload data.
	 *
	 * If they payload is an array we treat the entire object as an
	 * accessor to the payload. Otherwise the key must be "data" to
	 * mimic regular object access.
	 *
	 * @return void
	 */
	public function __set($key, $value)
	{
		if ($this->_frozen)
		{
			throw new RuntimeException('Cannot modify payload. Tree node is frozen.');
		}

		if (is_array($this->data))
		{
			$this->data[$key] = $value;
		}
		elseif ($key == 'data')
		{
			$this->data = $value;
		}
		else
		{
			throw new InvalidArgumentException('Payload cannot be modified.');
		}
	}

	// --------------------------------------------------------------------

	/**
	 * Post-process node cloning
	 *
	 * Cloning needs to unfreeze the node for the benefit of the
	 * subtree_copy method. Not to mention dev sanity.
	 *
	 * @return void
	 */
	public function __clone()
	{
		$this->_frozen = FALSE;
	}

	// Public Setters

	// --------------------------------------------------------------------

	/**
	 * Add a child node to the current node.
	 *
	 * Notifies the child of its parent and adds the child name to
	 * the child name array. Does not enforce unique names since it
	 * may be desireable to have non-unique named children. It's on
	 * the developer to not rely on the get() method in that case
	 *
	 * @return void
	 */
	public function add(EE_TreeNode $child)
	{
		if ($child == $this)
		{
			throw new RuntimeException('Cannot add tree node to itself.');
		}

		if ($this->_frozen)
		{
			throw new RuntimeException('Cannot add child. Tree node is frozen.');
		}

		$this->children[] = $child;
		$this->children_names[$child->name] = $child;
		$child->_set_parent($this);
	}

	// Getters

	// --------------------------------------------------------------------

	/**
	 * Get the node's name
	 *
	 * @return <string?> name
	 */
	public function name()
	{
		return $this->name;
	}

	// --------------------------------------------------------------------

	/**
	 * Get the node's payload
	 *
	 * @return <mixed> payload
	 */
	public function data()
	{
		return $this->data;
	}

	// --------------------------------------------------------------------

	/**
	 * Get the node's depth relative to its root, where the root's
	 * depth is 0.
	 *
	 * @return <Integer> depth
	 */
	public function depth()
	{
		if ($this->is_root())
		{
			return 0;
		}

		return 1 + $this->parent()->depth();
	}

	// Traversal

	// --------------------------------------------------------------------

	/**
	 * Get all of the tree's root node
	 *
	 * If the current node is not a root node, we move our
	 * way up until we have a root.
	 *
	 * @return <EE_TreeNode>
	 */
	public function root()
	{
		$root = $this;

		while ( ! $root->is_root())
		{
			$root = $root->parent();
		}

		return $root;
	}

	// --------------------------------------------------------------------

	/**
	 * Get all of the node's children
	 *
	 * @return array[<EE_TreeNode>s]
	 */
	public function children()
	{
		return $this->children;
	}

	// --------------------------------------------------------------------

	/**
	 * Get the node's first child
	 *
	 * For the very common case where you only have one root. The tree
	 * library always has to assume that you might have multiple roots when
	 * it generates data from db results.
	 *
	 * @return <EE_TreeNode>
	 */
	public function first_child()
	{
		return $this->children[0];
	}

	// --------------------------------------------------------------------

	/**
	 * Get the node's parent
	 *
	 * @return <EE_TreeNode>
	 */
	public function parent()
	{
		return $this->parent;
	}

	// --------------------------------------------------------------------

	/**
	 * Get all of a node's siblings
	 *
	 * @return array[<EE_TreeNode>s]
	 */
	public function siblings()
	{
		$siblings = array();

		if ( ! $this->is_root())
		{
			foreach ($this->parent()->children() as $sibling)
			{
				if ($sibling != $this)
				{
					$siblings[] = $sibling;
				}
			}
		}

		return $siblings;
	}

	// Utility

	// --------------------------------------------------------------------

	/**
	 * Check if the node has parents
	 *
	 * @return boolean
	 */
	public function is_root()
	{
		return ! isset($this->parent);
	}

	// --------------------------------------------------------------------

	/**
	 * Check if the node has children
	 *
	 * @return boolean
	 */
	public function is_leaf()
	{
		return count($this->children) == 0;
	}

	// --------------------------------------------------------------------

	/**
	 * Freeze the node
	 *
	 * Prevents data and child manipulations. Cloning a frozen node will
	 * unfreeze it.
	 *
	 * @return void
	 */
	public function freeze()
	{
		$this->_frozen = TRUE;
	}

	// --------------------------------------------------------------------

	/**
	 * Get a child by name
	 *
	 * You are responsible for adding children with unique names. If you
	 * do not, then this method will return the last child node of the
	 * given name.
	 *
	 * @return <EE_TreeNode>
	 */
	public function get($name)
	{
		return $this->children_names[$name];
	}

	// --------------------------------------------------------------------

	/**
	 * Create a subtree on this node.
	 *
	 * Clones the current node to turn it into a root node off the
	 * original tree.
	 *
	 * This is a *shallow* copy! The root node you receive is a clone, but
	 * its children remain on the tree. If you need a clone for anything
	 * other than traversal, consider using the subtree_copy() method instead.
	 *
	 * @return <EE_TreeNode>
	 */
	public function subtree()
	{
		$root = clone $this;
		$root->parent = NULL;
		return $root;
	}

	// --------------------------------------------------------------------

	/**
	 * Create a full subtree copy from this node down.
	 *
	 * Clones the current node and all of its children. This is a deep
	 * copy, everything will be cloned. If all you need is a new root
	 * for traversal, consider using subtree() instead.
	 *
	 * @return <EE_TreeNode>
	 */
	public function subtree_copy()
	{
		$root = $this->subtree();

		foreach ($root->children() as $node)
		{
			$root->add($node->subtree());
		}

		return $root;
	}

	// --------------------------------------------------------------------

	/**
	 * Get an iterator of the flattened tree
	 *
	 * This is pretty much only useful if you're going to be constructing
	 * a RecursiveIteratorIterator that isn't SELF_FIRST. Otherwise you
	 * most definitely want iterator()
	 *
	 * @return Object<TreeIterator>
	 */
	public function flat_iterator()
	{
		return new EE_TreeIterator(array($this));
	}

	// --------------------------------------------------------------------

	/**
	 * Preorder Tree Iterator
	 *
	 * Creates a preorder tree iterator from the current node down.
	 *
	 * @return <RecursiveIteratorIterator> with SELF_FIRST
	 */
	public function preorder_iterator()
	{
		return new RecursiveIteratorIterator(
			$this->flat_iterator(),
			RecursiveIteratorIterator::SELF_FIRST
		);
	}

	// --------------------------------------------------------------------

	/**
	 * Leaf Iterator
	 *
	 * Iterates across all the leaf nodes
	 *
	 * @return <RecursiveIteratorIterator> with LEAVES_ONLY
	 */
	public function leaf_iterator()
	{
		return new RecursiveIteratorIterator(
			$this->flat_iterator(),
			RecursiveIteratorIterator::LEAVES_ONLY
		);
	}

	// --------------------------------------------------------------------

	/**
	 * Set parent
	 *
	 * Links up the parent node for upwards traversal. Should only ever
	 * be called from add() to maintain referential integrity.
	 * 
	 * In theory add() has access to the property directly, but sometimes
	 * it's useful to override this with additional functionality.
	 *
	 * @param <EE_TreeNode> New parent node
	 * @return void
	 */
	protected function _set_parent(EE_TreeNode $parent)
	{
		$this->parent = $parent;
	}
}

// ------------------------------------------------------------------------

/**
 * ExpressionEngine Tree Iterator Class
 *
 * @package		ExpressionEngine
 * @subpackage	Core Datastructures
 * @category	Core
 * @author		EllisLab Dev Team
 * @link		http://ellislab.com
 */
class EE_TreeIterator extends RecursiveArrayIterator {

	/**
	 * Override RecursiveArrayIterator's child detection method.
	 * We really don't want to count object properties as children.
	 *
	 * @return boolean
	 */
	public function hasChildren()
	{
		return ! $this->current()->is_leaf();
	}

	// --------------------------------------------------------------------

	/**
	 * Override RecursiveArrayIterator's get child method to skip
	 * ahead into the children array and not try to iterate over the
	 * over the public name property.
	 *
	 * @return Object<EE_TreeIterator>
	 */
	public function getChildren()
	{
		$children = $this->current()->children();

		// Using ref as per PHP source
		if (empty($this->ref))
		{
			$this->ref = new ReflectionClass($this);
		}

		return $this->ref->newInstance($children);
	}
}


/* End of file Tree.php */
/* Location: ./system/expressionengine/libraries/datastructures/Tree.php */