import "package:unittest/unittest.dart";
import "package:darwin/darwin.dart";
import "dart:math";
import "dart:async";

void main() {
  Generation<MyPhenotype> firstGeneration;
  MyEvaluator evaluator;
  GenerationBreeder breeder;
  GeneticAlgorithm algo;
  
  group("Genetic algorithm", () {
    
    // Set up the variables.
    setUp(() {
      // Create first generation.
      firstGeneration = new Generation<MyPhenotype>();
      
      // Fill it with random phenotypes.
      while (firstGeneration.members.length < 10) {
        var member = new MyPhenotype.Random();
        // Guard against a winning phenotype in first generation.
        if (member.genes.any((gene) => gene == false)) {
          firstGeneration.members.add(member);
        }
      }
      
      // Evaluators take each phenotype and assign a fitness value to it according
      // to some fitness function.
      evaluator = new MyEvaluator();
      
      // Breeders are in charge of creating new generations from previous ones (that
      // have been graded by the evaluator). 
      breeder = new GenerationBreeder(() => new MyPhenotype())
        ..crossoverPropability = 0.8;
      
      algo = new GeneticAlgorithm(firstGeneration, evaluator, breeder,
          printf: (_) {return;}, statusf: (_) {return;});
    });
    
    test("terminates", () {
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          expect(algo.currentGeneration, greaterThan(0));
        }));
    });
    
    test("converges to better fitness", () {
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          // Remember, lower fitness result is better.
          expect(algo.generations.first.bestFitness,
              greaterThanOrEqualTo(algo.generations.last.bestFitness));
        }));
    });
    
    test("works without fitness sharing", () {
      breeder.fitnessSharing = false;
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          // Remember, lower fitness result is better.
          expect(algo.generations.first.bestFitness,
              greaterThanOrEqualTo(algo.generations.last.bestFitness));
        }));
    });
    
    test("works without elitism", () {
      breeder.elitismCount = 0;
      // Start the algorithm.
      algo.runUntilDone()
        .then(expectAsync1((_) {
          // Remember, lower fitness result is better.
          expect(algo.generations.first.bestFitness,
              greaterThanOrEqualTo(algo.generations.last.bestFitness));
        }));
    });
    
    test("onGenerationEvaluatedController works", () {
      // Register the hook;
      algo.onGenerationEvaluated.listen(expectAsync1((Generation g) {
        expect(g.averageFitness, isNotNull);
        expect(g.best, isNotNull);
      }, max: -1));
      
      // Start the algorithm.
      algo.runUntilDone()
      .then(expectAsync1((_) {
        // Wait for done.
      }));
    });
    
    test("Generation.best is assigned to last generation after done", () {
      // Start the algorithm.
      algo.runUntilDone()
      .then(expectAsync1((_) {
        expect(algo.generations.last.best, isNotNull);
      }));
    });
  });
}

Random random = new Random(); 

class MyEvaluator extends PhenotypeEvaluator<MyPhenotype> {
  Future<num> evaluate(MyPhenotype phenotype) {
    // This implementation just counts false values - the more false values,
    // the worse outcome of the fitness function.
    return new Future.value(
        phenotype.genes.where((bool v) => v == false).length);
  }
}

class MyPhenotype extends Phenotype<bool> {
  static int geneCount = 6;
  
  MyPhenotype();
  
  MyPhenotype.Random() {
    genes = new List<bool>(geneCount);
    for (int i = 0; i < geneCount; i++) {
      genes[i] = random.nextBool();
    }
  }
  
  bool mutateGene(bool gene, num strength) {
    return !gene;
  }
}