import "package:darwin/darwin.dart";
import "package:test/test.dart";

void main() {
  group("TreePhenotype", () {
    test("genesAsString", () {
      TestTreePhenotype phenotype = new TestTreePhenotype();
      phenotype.root = _createGeneNodeTestFixture();
      expect(phenotype.genesAsString,
          equals(expectedPrettyPrintGeneNodeTestFixture));
    });
  });

  group("GeneNode", () {
    test("iterator", () {
      GeneNode root = _createGeneNodeTestFixture();
      List<String> expectedNodeIteration = [
        "Node1",
        "Child1",
        "Grandchild1.1",
        "Grandchild1.2",
        "Child2",
        "Grandchild2.1"
      ];

      int nodeIndex = 0;
      for (GeneNode node in root) {
        expect(node.prettyPrintName, equals(expectedNodeIteration[nodeIndex]));
        nodeIndex++;
      }
      expect(nodeIndex, equals(6));
    });
  });
}

GeneNode _createGeneNodeTestFixture() {
  GeneNode root = new TestGeneNode("Node1");

  GeneNode child1 = new TestGeneNode("Child1");
  GeneNode child2 = new TestGeneNode("Child2");
  root.addChild(child1);
  root.addChild(child2);

  GeneNode grandChild1 = new TestGeneNode("Grandchild1.1");
  GeneNode grandChild2 = new TestGeneNode("Grandchild1.2");
  GeneNode grandChild3 = new TestGeneNode("Grandchild2.1");
  child1.addChild(grandChild1);
  child1.addChild(grandChild2);
  child2.addChild(grandChild3);

  return root;
}

String expectedPrettyPrintGeneNodeTestFixture = '''\\-Node1
  |-Child1
  | |-Grandchild1.1
  | \\-Grandchild1.2
  \\-Child2
    \\-Grandchild2.1
''';

class TestGeneNode extends GeneNode {
  final String value;

  TestGeneNode(this.value);

  @override
  String get prettyPrintName => value;

  @override
  GeneNode deepCloneSubclass() {
    return new TestGeneNode(value);
  }
}

class TestTreePhenotype extends TreePhenotype<TestGeneNode> {
  @override
  TestGeneNode mutateGene(TestGeneNode gene, num strength) => null;
}
