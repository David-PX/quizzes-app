enum QuizDifficulty {
  easy('Easy', 'A gentle start to test your knowledge'),
  medium('Medium', 'Take your knowledge a little further'),
  hard('Hard', 'Put your knowledge to the test');

  const QuizDifficulty(this.label, this.description);

  final String label;
  final String description;
}
