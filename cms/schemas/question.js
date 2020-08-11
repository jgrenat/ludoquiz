export default {
  name: "question",
  title: "Question",
  type: "object",
  fields: [
    {
      name: "question",
      title: "Question",
      type: "string"
    },
    {
      name: "image",
      title: "Image",
      type: "image"
    },
    {
      name: "answers",
      title: "Answers",
      type: "array",
      of: [{ type: "answer" }],
      validation: Rule => [
        Rule.required().min(2),
        Rule.custom(answers => {
          const correctAnswerCounts = (answers || []).filter(
            answer => answer.isCorrect
          ).length;
          return correctAnswerCounts === 1
            ? true
            : "There should be one and only one correct answer. Currently there are " +
                correctAnswerCounts +
                " correct answer(s).";
        })
      ]
    }
  ]
};
