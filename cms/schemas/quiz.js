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
      type: 'string',
      validation: Rule => Rule.required()
    },
    {
      name: 'slug',
      title: 'Slug',
      type: 'slug',
      options: {
        source: 'title',
        maxLength: 100
      },
      validation: Rule => Rule.required()
    },
    {
      title: 'Publication date',
      name: 'publicationDate',
      type: 'datetime',
      validation: Rule => Rule.required()
    },
    {
      name: 'image',
      title: 'Image',
      type: 'image',
      validation: Rule => Rule.required()
    },
    {
      name: 'description',
      title: 'Description',
      type: 'blockContent',
      validation: Rule => Rule.required()
    },
    {
      name: 'questions',
      title: 'Questions',
      type: 'array',
      of: [{type: 'question'}],
      validation: Rule => Rule.required().min(2)
    },
  ]
}
