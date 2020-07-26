import icon from 'react-icons/lib/md/local-movies'

export default {
  name: 'quiz',
  title: 'Quiz',
  type: 'document',
  icon,
  fields: [
    {
      name: 'title',
      title: 'Title',
      type: 'string'
    },
    {
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 100
      }
    },
    {
      title: 'Publication date',
      name: 'publicationDate',
      type: 'datetime'
    },
    {
      name: 'image',
      title: 'Image',
      type: 'image'
    },
    {
      name: 'description',
      title: 'Description',
      type: 'blockContent'
    },
    {
      name: 'questions',
      title: 'Questions',
      type: 'array',
      of: [{type: 'question'}]
    },
  ]
}
