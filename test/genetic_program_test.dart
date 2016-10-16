import "dart:async";
import "dart:math";

import "package:darwin/darwin.dart";
import "package:test/test.dart";

void main() {
  Generation<MyTreePhenotype> firstGeneration;
  MyEvaluator evaluator;
  TreeGenerationBreeder breeder;
  GeneticAlgorithm<MyTreePhenotype> algo;

  group("Genetic program", () {
    // Set up the variables.
    setUp(() {
      const complexValueToCalculate = 9001;

      // Create first generation.
      firstGeneration = new Generation<MyTreePhenotype>();

      // Fill it with random phenotypes.
      while (firstGeneration.members.length < 10) {
        var member = new MyTreePhenotype.Random();
        // Guard against a winning phenotype in first generation.
        if (member.root.eval() != complexValueToCalculate) {
          firstGeneration.members.add(member);
        }
      }

      // Evaluators take each phenotype and assign a fitness value to it according
      // to some fitness function.
      evaluator = new MyEvaluator(complexValueToCalculate);

      // Breeders are in charge of creating new generations from previous ones (that
      // have been graded by the evaluator).
      breeder = new TreeGenerationBreeder<MyTreePhenotype>(
          () => new MyTreePhenotype())..crossoverPropability = 0.8;

      algo = new GeneticAlgorithm(firstGeneration, evaluator, breeder,
          printf: null, statusf: null);

      algo.THRESHOLD_RESULT = .1;
    });

    test("terminates", () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.currentGeneration, greaterThan(0));
    });

    test("converges to better fitness", () async {
      // Start the algorithm.
      await algo.runUntilDone();

      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("works without fitness sharing", () async {
      breeder.fitnessSharing = false;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("works without elitism", () async {
      breeder.elitismCount = 0;
      // Start the algorithm.
      await algo.runUntilDone();
      // Remember, lower fitness result is better.
      expect(algo.generations.first.bestFitness,
          greaterThanOrEqualTo(algo.generations.last.bestFitness));
    });

    test("onGenerationEvaluatedController works", () async {
      // Register the hook;
      algo.onGenerationEvaluated.listen((Generation g) {
        expect(g.averageFitness, isNotNull);
        expect(g.best, isNotNull);
      });

      // Start the algorithm.
      algo.runUntilDone();
    });

    test("Generation.best is assigned to last generation after done", () async {
      // Start the algorithm.
      await algo.runUntilDone();
      expect(algo.generations.last.best, isNotNull);
    });
  });
}

Random random = new Random();

/// An evaluator that checks how close a tree matches some value when the tree
/// is evaluated
class MyEvaluator extends PhenotypeEvaluator<MyTreePhenotype> {
  final num complexValueToCalculate;

  MyEvaluator(this.complexValueToCalculate);

  Future<num> evaluate(MyTreePhenotype phenotype) {
    num calculatedValue = phenotype.root.eval();
    num distance = (calculatedValue - complexValueToCalculate).abs();
    if (distance == double.INFINITY || distance == double.NAN) {
      distance =
          double.MAX_FINITE; // evolution missed the boat! drown the expression!
    }
    return new Future.value(distance);
  }
}

class MyTreePhenotype extends TreePhenotype<MyGeneNode> {
  static int geneCount = 6;

  MyTreePhenotype();

  MyTreePhenotype.Random() {
    root = new MyGeneNode.RandomTree(0);
  }

  @override
  GeneNode mutateGene(MyGeneNode gene, num strength) {
    return gene.mutate();
  }
}

abstract class MyGeneNode extends GeneNode {
  static const int _maxDepth = 5;

  MyGeneNode();

  /// Constructs a random tree and returns a [MyGeneNode] root. [depth] is how
  /// deep the [MyGeneNode] is in another tree. Use 0 when generating a tree
  /// root
  factory MyGeneNode.RandomTree(int depth) {
    if (depth == _maxDepth) {
      return new IntegerNode.Random();
    }

    int randomInt = random.nextInt(10);
    if (randomInt < 4) {
      return new OperatorNode.RandomTree(depth);
    } else {
      return new IntegerNode.Random();
    }
  }

  num eval();

  MyGeneNode mutate();
}

/// A terminal node that represents an integer value
class IntegerNode extends MyGeneNode {
  final int value;

  @override
  String get prettyPrintName => value.toString();

  IntegerNode(this.value);

  IntegerNode.Random() : this.value = random.nextInt(10);

  @override
  num eval() => value;

  @override
  GeneNode deepCloneSubclass() {
    return new IntegerNode(value);
  }

  @override
  MyGeneNode mutate() {
    return new IntegerNode.Random();
  }
}

/// Primitive function nodes that can perform a mathematical operation on two
/// values
abstract class OperatorNode extends MyGeneNode {
  OperatorNode();

  factory OperatorNode.RandomTree(int depth) {
    int childDepth = depth + 1;

    OperatorNode node = new OperatorNode.RandomNode()
      ..addChild(new MyGeneNode.RandomTree(childDepth))
      ..addChild(new MyGeneNode.RandomTree(childDepth));

    return node;
  }

  factory OperatorNode.RandomNode() {
    int randomInt = random.nextInt(4);
    switch (randomInt) {
      case 0:
        return new AddNode();
      case 1:
        return new SubtractNode();
      case 2:
        return new MultiplyNode();
      case 3:
        return new DivideNode();
    }
    return null;
  }

  @override
  num eval() {
    return _evaluateOperator(
        _getTypedChild(0).eval(), _getTypedChild(1).eval());
  }

  MyGeneNode _getTypedChild(int index) => this.children[index];

  num _evaluateOperator(num first, num second);

  GeneNode mutate() {
    return new OperatorNode.RandomNode();
  }
}

class AddNode extends OperatorNode {
  @override
  String get prettyPrintName => "Add";

  @override
  num _evaluateOperator(num first, num second) {
    return first + second;
  }

  @override
  GeneNode deepCloneSubclass() {
    return new AddNode();
  }
}

class SubtractNode extends OperatorNode {
  @override
  String get prettyPrintName => "Sub";

  @override
  num _evaluateOperator(num first, num second) {
    return first - second;
  }

  @override
  GeneNode deepCloneSubclass() {
    return new SubtractNode();
  }
}

class MultiplyNode extends OperatorNode {
  @override
  String get prettyPrintName => "Mult";

  @override
  num _evaluateOperator(num first, num second) {
    return first * second;
  }

  @override
  GeneNode deepCloneSubclass() {
    return new MultiplyNode();
  }
}

class DivideNode extends OperatorNode {
  @override
  String get prettyPrintName => "Div";

  @override
  num _evaluateOperator(num first, num second) {
    return first / second;
  }

  @override
  GeneNode deepCloneSubclass() {
    return new DivideNode();
  }
}
