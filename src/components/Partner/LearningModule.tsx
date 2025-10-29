import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { BookOpen, PlayCircle, Download, ChevronRight, ArrowLeft, FileText, Clock } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { supabase } from '@/lib/supabase'
import { linkifyText } from '@/lib/linkify'

interface Course {
  id: string
  course_id: string
  title: string
  description: string
  thumbnail_url?: string
  instructor: string
  duration?: string
  level: string
  status: string
}

interface Category {
  id: string
  title: string
  description?: string
  order_index: number
}

interface Lesson {
  id: string
  title: string
  description?: string
  video_url?: string
  thumbnail_url?: string
  duration?: string
  order_index: number
  is_free: boolean
}

interface Attachment {
  id: string
  file_name: string
  file_url: string
  file_type?: string
  file_size?: string
}

export function LearningModule() {
  const [view, setView] = useState<'courses' | 'categories' | 'lesson'>('courses')
  const [courses, setCourses] = useState<Course[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [lessons, setLessons] = useState<Lesson[]>([])
  const [attachments, setAttachments] = useState<Attachment[]>([])
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null)
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchPublishedCourses()
  }, [])

  const fetchPublishedCourses = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('courses')
        .select('*')
        .eq('status', 'Published')
        .order('created_at', { ascending: false })

      if (error) throw error
      setCourses(data || [])
    } catch (err) {
      console.error('Error fetching courses:', err)
    } finally {
      setLoading(false)
    }
  }

  const fetchCategoriesAndLessons = async (courseId: string) => {
    try {
      const { data: categoriesData, error: catError } = await supabase
        .from('categories')
        .select('*')
        .eq('course_id', courseId)
        .order('order_index', { ascending: true })

      if (catError) throw catError

      const categoriesWithLessons = await Promise.all(
        (categoriesData || []).map(async (category) => {
          const { data: lessonsData } = await supabase
            .from('lessons')
            .select('*')
            .eq('category_id', category.id)
            .order('order_index', { ascending: true })

          return {
            ...category,
            lessons: lessonsData || []
          }
        })
      )

      setCategories(categoriesWithLessons as any)
    } catch (err) {
      console.error('Error fetching categories:', err)
    }
  }

  const fetchAttachments = async (lessonId: string) => {
    try {
      const { data, error } = await supabase
        .from('lesson_attachments')
        .select('*')
        .eq('lesson_id', lessonId)

      if (error) throw error
      setAttachments(data || [])
    } catch (err) {
      console.error('Error fetching attachments:', err)
    }
  }

  const handleViewCourse = async (course: Course) => {
    setSelectedCourse(course)
    setSelectedLesson(null)
    await fetchCategoriesAndLessons(course.id)
    setView('categories')
  }

  const handleViewLesson = async (lesson: Lesson) => {
    setSelectedLesson(lesson)
    await fetchAttachments(lesson.id)
    setView('lesson')
  }

  const handleBackToCourses = () => {
    setSelectedCourse(null)
    setSelectedLesson(null)
    setCategories([])
    setView('courses')
  }

  const handleBackToCategories = () => {
    setSelectedLesson(null)
    setAttachments([])
    setView('categories')
  }

  const getEmbedUrl = (url: string) => {
    if (!url) return null

    if (url.includes('youtube.com/watch?v=')) {
      const videoId = url.split('v=')[1]?.split('&')[0]
      return `https://www.youtube.com/embed/${videoId}`
    }

    if (url.includes('youtu.be/')) {
      const videoId = url.split('youtu.be/')[1]?.split('?')[0]
      return `https://www.youtube.com/embed/${videoId}`
    }

    if (url.includes('vimeo.com/')) {
      const videoId = url.split('vimeo.com/')[1]?.split('?')[0]
      return `https://player.vimeo.com/video/${videoId}`
    }

    if (url.match(/\.(mp4|webm|ogg)$/i)) {
      return url
    }

    return null
  }

  const renderCourses = () => (
    <div className="space-y-6">
      <div>
        <h2 className="text-3xl font-bold text-gray-900">Available Courses</h2>
        <p className="text-gray-600 mt-2">Explore our published courses</p>
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">Loading courses...</div>
      ) : courses.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            No courses available yet
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {courses.map((course) => (
            <motion.div
              key={course.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              whileHover={{ y: -5 }}
              transition={{ duration: 0.2 }}
            >
              <Card className="overflow-hidden hover:shadow-xl transition-shadow cursor-pointer h-full">
                <div
                  className="aspect-video bg-gradient-to-br from-blue-100 to-green-100 flex items-center justify-center"
                  onClick={() => handleViewCourse(course)}
                >
                  {course.thumbnail_url ? (
                    <img
                      src={course.thumbnail_url}
                      alt={course.title}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <BookOpen className="w-16 h-16 text-gray-400" />
                  )}
                </div>
                <CardContent className="p-5">
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="font-bold text-lg line-clamp-2">{course.title}</h3>
                  </div>
                  <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                    {course.description}
                  </p>
                  <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                    <span className="flex items-center">
                      <BookOpen className="w-4 h-4 mr-1" />
                      {course.instructor}
                    </span>
                    <Badge variant="outline">{course.level}</Badge>
                  </div>
                  {course.duration && (
                    <div className="flex items-center text-sm text-gray-500 mb-4">
                      <Clock className="w-4 h-4 mr-1" />
                      {course.duration}
                    </div>
                  )}
                  <Button
                    onClick={() => handleViewCourse(course)}
                    className="w-full bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
                  >
                    Start Learning
                    <ChevronRight className="w-4 h-4 ml-2" />
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  )

  const renderCategories = () => (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={handleBackToCourses}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Courses
        </Button>
        <div className="flex-1">
          <h2 className="text-3xl font-bold text-gray-900">{selectedCourse?.title}</h2>
          <p className="text-gray-600 mt-1">{selectedCourse?.description}</p>
        </div>
      </div>

      {categories.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            No content available for this course yet
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-6">
          {categories.map((category: any, categoryIndex) => (
            <motion.div
              key={category.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: categoryIndex * 0.1 }}
            >
              <Card>
                <CardContent className="p-6">
                  <div className="flex items-center space-x-3 mb-4">
                    <div className="w-12 h-12 bg-gradient-to-br from-blue-500 to-green-500 rounded-lg flex items-center justify-center flex-shrink-0">
                      <span className="text-white font-bold text-lg">
                        {categoryIndex + 1}
                      </span>
                    </div>
                    <div>
                      <h3 className="text-xl font-bold text-gray-900">
                        {category.title}
                      </h3>
                      {category.description && (
                        <p className="text-sm text-gray-600">{category.description}</p>
                      )}
                    </div>
                  </div>

                  {category.lessons && category.lessons.length > 0 && (
                    <div className="ml-15 space-y-2">
                      {category.lessons.map((lesson: Lesson, lessonIndex: number) => (
                        <div
                          key={lesson.id}
                          onClick={() => handleViewLesson(lesson)}
                          className="flex items-center justify-between p-4 bg-gray-50 hover:bg-gray-100 rounded-lg cursor-pointer transition-colors group"
                        >
                          <div className="flex items-center space-x-3 flex-1">
                            <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center border-2 border-gray-200 group-hover:border-blue-500 transition-colors">
                              <PlayCircle className="w-5 h-5 text-gray-600 group-hover:text-blue-600" />
                            </div>
                            <div className="flex-1">
                              <div className="flex items-center space-x-2">
                                <span className="font-medium text-gray-900">
                                  {lesson.title}
                                </span>
                                {lesson.is_free && (
                                  <Badge className="bg-blue-100 text-blue-800 text-xs">
                                    Free
                                  </Badge>
                                )}
                              </div>
                              {lesson.duration && (
                                <span className="text-sm text-gray-500">
                                  {lesson.duration}
                                </span>
                              )}
                            </div>
                          </div>
                          <ChevronRight className="w-5 h-5 text-gray-400 group-hover:text-blue-600" />
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  )

  const renderLesson = () => {
    if (!selectedLesson) return null

    const embedUrl = getEmbedUrl(selectedLesson.video_url || '')
    const isDirectVideo = selectedLesson.video_url?.match(/\.(mp4|webm|ogg)$/i)

    return (
      <div className="space-y-6">
        <div className="flex items-center space-x-4">
          <Button variant="outline" onClick={handleBackToCategories}>
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back to Course
          </Button>
          <div className="flex-1">
            <h2 className="text-2xl font-bold text-gray-900">{selectedLesson.title}</h2>
            {selectedLesson.duration && (
              <p className="text-gray-600 mt-1 flex items-center">
                <Clock className="w-4 h-4 mr-1" />
                {selectedLesson.duration}
              </p>
            )}
          </div>
        </div>

        {selectedLesson.thumbnail_url && !selectedLesson.video_url && (
          <Card className="overflow-hidden">
            <CardContent className="p-0">
              <div className="aspect-video bg-gradient-to-br from-blue-100 to-green-100">
                <img
                  src={selectedLesson.thumbnail_url}
                  alt={selectedLesson.title}
                  className="w-full h-full object-cover"
                />
              </div>
            </CardContent>
          </Card>
        )}

        {selectedLesson.video_url && embedUrl && (
          <Card className="overflow-hidden">
            <CardContent className="p-0">
              <div className="aspect-video bg-black">
                {isDirectVideo ? (
                  <video
                    controls
                    className="w-full h-full"
                    src={embedUrl}
                    poster={selectedLesson.thumbnail_url}
                  >
                    Your browser does not support the video tag.
                  </video>
                ) : (
                  <iframe
                    src={embedUrl}
                    className="w-full h-full"
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                    allowFullScreen
                  />
                )}
              </div>
            </CardContent>
          </Card>
        )}

        {selectedLesson.description && (
          <Card>
            <CardContent className="p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">
                About this Lesson
              </h3>
              <div className="text-gray-700 whitespace-pre-wrap">
                {linkifyText(selectedLesson.description)}
              </div>
            </CardContent>
          </Card>
        )}

        {attachments.length > 0 && (
          <Card>
            <CardContent className="p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">
                Course Materials
              </h3>
              <div className="space-y-3">
                {attachments.map((attachment) => (
                  <div
                    key={attachment.id}
                    className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    <div className="flex items-center space-x-3 flex-1">
                      <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center border-2 border-gray-200">
                        <FileText className="w-5 h-5 text-gray-600" />
                      </div>
                      <div className="flex-1">
                        <div className="font-medium text-gray-900">
                          {attachment.file_name}
                        </div>
                        <div className="flex items-center space-x-2 text-sm text-gray-500">
                          {attachment.file_type && (
                            <span>{attachment.file_type}</span>
                          )}
                          {attachment.file_size && (
                            <>
                              <span>•</span>
                              <span>{attachment.file_size}</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => window.open(attachment.file_url, '_blank')}
                    >
                      <Download className="w-4 h-4 mr-2" />
                      Download
                    </Button>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    )
  }

  return (
    <div>
      {view === 'courses' && renderCourses()}
      {view === 'categories' && renderCategories()}
      {view === 'lesson' && renderLesson()}
    </div>
  )
}
