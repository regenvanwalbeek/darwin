part of darwin;

class GeneticAlgorithm<T extends Phenotype> {
  final int generationSize;
  int MAX_EXPERIMENTS = 20000;
  /**
   * When any [Phenotype] scores lower than this, the genetic algorithm
   * has ended.
   */
  num THRESHOLD_RESULT = 0.01;
  final int MAX_GENERATIONS_IN_MEMORY = 100;

  int currentExperiment = 0;
  int currentGeneration = 0;

  Stream<Generation<T>> get onGenerationEvaluated =>
      _onGenerationEvaluatedController.stream;
  StreamController<Generation<T>> _onGenerationEvaluatedController;

  List<Generation<T>> generations = new List<Generation>();
  Iterable<T> get population =>
      generations.expand((Generation<T> gen) => gen.members);
  final PhenotypeEvaluator evaluator;
  final GenerationBreeder breeder;

  GeneticAlgorithm(Generation firstGeneration, this.evaluator, this.breeder,
      {PrintFunction printf: print, PrintFunction statusf: print})
      : generationSize = firstGeneration.members.length,
        _printf = printf,
        _statusf = statusf {
    generations.add(firstGeneration);
    evaluator._printf = printf;

    _onGenerationEvaluatedController = new StreamController<Generation<T>>();
  }

  Completer _doneCompleter;
  Future runUntilDone() {
    _doneCompleter = new Completer();
    _evaluateNextGeneration();
    return _doneCompleter.future;
  }

  final PrintFunction _printf;

  /**
   * Function used for printing info about the progress of the genetic
   * algorithm. This is the standard console [print] by default.
   */
  printf(String stringToPrint) {
    if (_printf == null) {
      return;
    }

    _printf(stringToPrint);
  }

  final PrintFunction _statusf;

  /**
   * Function used for showing status of the genetic algorithm, with the
   * assumption that previous status text is rewritten by new status text.
   * This is also initialized with [print] by default, but that's not
   * the ideal implementation.
   */
  statusf(String stringToDisplay) {
    if (_statusf == null) {
      return;
    }

    _statusf(stringToDisplay);
  }

  void _evaluateNextGeneration() {
    evaluateLastGeneration().then((_) {
      printf("Applying niching to results.");
      breeder.applyFitnessSharingToResults(generations.last);
      printf("Generation #$currentGeneration evaluation done. Results:");
      generations.last.members.forEach((T member) {
        printf("- ${member.result.toStringAsFixed(2)}");
      });
      printf("- ${generations.last.averageFitness.toStringAsFixed(2)} AVG");
      printf("- ${generations.last.bestFitness.toStringAsFixed(2)} BEST");
      statusf("""
GENERATION #$currentGeneration
AVG  ${generations.last.averageFitness.toStringAsFixed(2)}
BEST ${generations.last.bestFitness.toStringAsFixed(2)}
""");
      printf("---");
      _onGenerationEvaluatedController.add(generations.last);
      if (currentExperiment >= MAX_EXPERIMENTS) {
        printf("All experiments done ($currentExperiment)");
        _doneCompleter.complete();
        return;
      }
      if (generations.last.members
          .any((T ph) => ph.result < THRESHOLD_RESULT)) {
        printf("One of the phenotypes got over the threshold.");
        _doneCompleter.complete();
        return;
      }
      _createNewGeneration();
      currentGeneration++;
      _evaluateNextGeneration();
    });
  }

  void _createNewGeneration() {
    printf("CREATING NEW GENERATION");
    generations.add(breeder.breedNewGeneration(generations));

    // calculating genesAsString can be expensive, so null check before deciding to print
    if (_printf != null) {
      printf("var newGen = [");
      generations.last.members.forEach((ph) => printf("${ph.genesAsString},"));
      printf("];");
    }

    while (generations.length > MAX_GENERATIONS_IN_MEMORY) {
      printf("- exceeding max generations, removing one from memory");
      generations.removeAt(0);
    }
  }

  int memberIndex;
  void _evaluateNextGenerationMember() {
    T currentPhenotype = generations.last.members[memberIndex];
    evaluator.evaluate(currentPhenotype).then((num result) {
      currentPhenotype.result = result;

      currentExperiment++;
      memberIndex++;
      if (memberIndex < generations.last.members.length) {
        _evaluateNextGenerationMember();
      } else {
        generations.last.computeSummary();
        _generationCompleter.complete();
        return;
      }
    });
  }

  Completer _generationCompleter;

  /**
   * Evaluates the latest generation and completes when done.
   *
   * TODO: Allow for multiple members being evaluated in parallel via
   * isolates.
   */
  Future evaluateLastGeneration() {
    _generationCompleter = new Completer();

    memberIndex = 0;
    _evaluateNextGenerationMember();

    return _generationCompleter.future;
  }
}

typedef void PrintFunction(Object o);
