part of darwin;

/**
 * A phenotype (also called chromosome or genotype) is one particular solution
 * to the problem (equation). The solution is encoded in [genes].
 *
 * After being evaluated by an [Evaluator], the phenotypes [result] is filled
 * with the output of the fitness function. If niching is at play, the result
 * is then modified into [_resultWithFitnessSharingApplied].
 *
 * Phenotype can have genes of any type [T], although most often, [T] will be
 * either [bool] (binary genes) or [num] (continuous genes).
 *
 * Subclasses must define [mutateGene], which returns a gene mutated by a given
 * strength.
 */
abstract class Phenotype<T> {
  num result = null;
  num _resultWithFitnessSharingApplied =
      null; // TODO Is this only applicable for ListPhenotypes?

  T mutateGene(T gene, num strength);

  toString() => "Phenotype<$genesAsString>";

  String get genesAsString;
}

abstract class ListPhenotype<T> extends Phenotype<T> {
  List<T> genes;

  @override
  String get genesAsString => JSON.encode(genes);
}

/// A phenotype that can be represented in tree form, which is useful for
/// generating a genetic program
///
/// Implementations of [mutateGene] can return null to denote that the phenotype
/// should not be mutated. Else [mutateGene] should return a [GeneNode] with
/// no parents or children.
abstract class TreePhenotype<T extends GeneNode> extends Phenotype<T> {
  T root;

  @override
  String get genesAsString {
    StringBuffer treeBuffer = new StringBuffer('');
    root.writeTreeToBuffer(treeBuffer, '', true);
    return treeBuffer.toString();
  }
}

abstract class GeneNode extends Iterable<GeneNode> {
  /// Parent node in the tree
  GeneNode parent;

  /// Child nodes in the tree
  List<GeneNode> children;

  /// How the node should be displayed when printing the tree format
  String get prettyPrintName;

  /// Helper for adding a child node
  addChild(GeneNode child) {
    if (children == null) {
      children = [];
    }
    children.add(child);
    child.parent = this;
  }

  GeneNode deepClone(GeneNode parent) {
    GeneNode clone = deepCloneSubclass();
    clone.parent = parent;
    clone.children = _deepCloneChildren(clone);
    return clone;
  }

  GeneNode deepCloneSubclass();

  /// TODO i don't really like this, works for now, come back to this

  List<GeneNode> _deepCloneChildren(GeneNode parent) {
    List<GeneNode> clonedChildren = null;
    if (children != null) {
      clonedChildren = [];
      children.forEach((GeneNode child) {
        clonedChildren.add(child.deepClone(parent));
      });
    }
    return clonedChildren;
  }

  @override
  Iterator<GeneNode> get iterator => new GeneNodeIterator(this);

  void writeTreeToBuffer(StringBuffer treeAsString, String indent, bool isLastChild) {
    treeAsString.write(indent);
    if (isLastChild) {
      treeAsString.write("\\-");
      indent += "  ";
    } else {
      treeAsString.write("|-");
      indent += "| ";
    }
    treeAsString.write('$prettyPrintName\n');

    if (children != null) {
      for (var childIndex = 0; childIndex < children.length; childIndex++) {
        children[childIndex].writeTreeToBuffer(treeAsString, indent, childIndex == children.length - 1);
      }
    }
  }
}

class GeneNodeIterator extends Iterator<GeneNode> {
  GeneNode _currentNode = null;
  List<GeneNode> _nodesToVisit;

  GeneNodeIterator(GeneNode startingNode) {
    _nodesToVisit = [startingNode];
  }

  @override
  GeneNode get current => _currentNode;

  @override
  bool moveNext() {
    if (_nodesToVisit.isEmpty) {
      return false;
    }

    /// Always add and remove from the end of _nodesToVisit list for performance
    _currentNode = _nodesToVisit.removeLast();
    List<GeneNode> children = _currentNode.children;
    if (children != null) {
      for (int nodeIndex = children.length - 1; nodeIndex >= 0; nodeIndex--) {
        _nodesToVisit.add(children[nodeIndex]);
      }
    }
    return true;
  }
}
