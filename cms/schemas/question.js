export default {
  name: 'question',
  title: 'Question',
  type: 'object',
  fields: [
    {
      name: 'question',
      title: 'Question',
      type: 'string'
    },
    {
      name: 'image',
      title: 'Image',
      type: 'image'
    },
    {
      name: 'answers',
      title: 'Answers',
      type: 'array',
      of: [{type: 'answer'}]
    }
  ]
}
