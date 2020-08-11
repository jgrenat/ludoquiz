export default {
  name: 'answer',
  title: 'Answer',
  type: 'object',
  fields: [
    {
      name: 'answer',
      title: 'Answer',
      type: 'string'
    },
    {
      name: 'isCorrect',
      title: 'Is correct?',
      type: 'boolean'
    }
  ],
  preview: {
    select: {
      title: 'answer',
      isCorrect: 'isCorrect'
    },
    prepare({ title, isCorrect }) {
      return {
        title: title + (isCorrect ? ' ✅' : '')
      }
    }
  }
}
