import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Plus, BookOpen, FolderOpen, PlayCircle, FileText, Edit, Trash2, ArrowLeft, X } from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { supabase } from '@/lib/supabase'
import { CourseModal } from '@/components/LMS/CourseModal'
import { CategoryModal } from '@/components/LMS/CategoryModal'
import { LessonModal } from '@/components/LMS/LessonModal'

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
  price: number
  created_at: string
}

interface Category {
  id: string
  course_id: string
  title: string
  description?: string
  order_index: number
  created_at: string
}

interface Lesson {
  id: string
  category_id: string
  title: string
  description?: string
  video_url?: string
  thumbnail_url?: string
  duration?: string
  order_index: number
  is_free: boolean
  created_at: string
}

interface Attachment {
  id: string
  lesson_id: string
  file_name: string
  file_url: string
  file_type?: string
  file_size?: string
  created_at: string
}

type View = 'courses' | 'categories' | 'lessons'

export function LMS() {
  const [view, setView] = useState<View>('courses')
  const [courses, setCourses] = useState<Course[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [lessons, setLessons] = useState<Lesson[]>([])
  const [attachments, setAttachments] = useState<Attachment[]>([])
  const [selectedCourse, setSelectedCourse] = useState<Course | null>(null)
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null)
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null)
  const [loading, setLoading] = useState(true)

  const [showCourseModal, setShowCourseModal] = useState(false)
  const [showCategoryModal, setShowCategoryModal] = useState(false)
  const [showLessonModal, setShowLessonModal] = useState(false)
  const [editingItem, setEditingItem] = useState<any>(null)

  useEffect(() => {
    fetchCourses()
  }, [])

  useEffect(() => {
    if (selectedCourse) {
      fetchCategories(selectedCourse.id)
    }
  }, [selectedCourse])

  useEffect(() => {
    if (selectedCategory) {
      fetchLessons(selectedCategory.id)
    }
  }, [selectedCategory])

  useEffect(() => {
    if (selectedLesson) {
      fetchAttachments(selectedLesson.id)
    }
  }, [selectedLesson])

  const fetchCourses = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('courses')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error
      setCourses(data || [])
    } catch (err) {
      console.error('Error fetching courses:', err)
    } finally {
      setLoading(false)
    }
  }

  const fetchCategories = async (courseId: string) => {
    try {
      const { data, error } = await supabase
        .from('categories')
        .select('*')
        .eq('course_id', courseId)
        .order('order_index', { ascending: true })

      if (error) throw error
      setCategories(data || [])
    } catch (err) {
      console.error('Error fetching categories:', err)
    }
  }

  const fetchLessons = async (categoryId: string) => {
    try {
      const { data, error } = await supabase
        .from('lessons')
        .select('*')
        .eq('category_id', categoryId)
        .order('order_index', { ascending: true })

      if (error) throw error
      setLessons(data || [])
    } catch (err) {
      console.error('Error fetching lessons:', err)
    }
  }

  const fetchAttachments = async (lessonId: string) => {
    try {
      const { data, error } = await supabase
        .from('lesson_attachments')
        .select('*')
        .eq('lesson_id', lessonId)
        .order('created_at', { ascending: true })

      if (error) throw error
      setAttachments(data || [])
    } catch (err) {
      console.error('Error fetching attachments:', err)
    }
  }

  const handleDeleteCourse = async (id: string) => {
    if (!confirm('Are you sure? This will delete all categories and lessons in this course.')) return

    try {
      const { error } = await supabase.from('courses').delete().eq('id', id)
      if (error) throw error
      fetchCourses()
    } catch (err) {
      console.error('Error deleting course:', err)
      alert('Failed to delete course')
    }
  }

  const handleDeleteCategory = async (id: string) => {
    if (!confirm('Are you sure? This will delete all lessons in this category.')) return

    try {
      const { error } = await supabase.from('categories').delete().eq('id', id)
      if (error) throw error
      if (selectedCourse) fetchCategories(selectedCourse.id)
    } catch (err) {
      console.error('Error deleting category:', err)
      alert('Failed to delete category')
    }
  }

  const handleDeleteLesson = async (id: string) => {
    if (!confirm('Are you sure? This will delete all attachments for this lesson.')) return

    try {
      const { error } = await supabase.from('lessons').delete().eq('id', id)
      if (error) throw error
      if (selectedCategory) fetchLessons(selectedCategory.id)
    } catch (err) {
      console.error('Error deleting lesson:', err)
      alert('Failed to delete lesson')
    }
  }

  const handleDeleteAttachment = async (id: string) => {
    if (!confirm('Are you sure you want to delete this attachment?')) return

    try {
      const { error } = await supabase.from('lesson_attachments').delete().eq('id', id)
      if (error) throw error
      if (selectedLesson) fetchAttachments(selectedLesson.id)
    } catch (err) {
      console.error('Error deleting attachment:', err)
      alert('Failed to delete attachment')
    }
  }

  const handleViewCourse = (course: Course) => {
    setSelectedCourse(course)
    setSelectedCategory(null)
    setSelectedLesson(null)
    setView('categories')
  }

  const handleViewCategory = (category: Category) => {
    setSelectedCategory(category)
    setSelectedLesson(null)
    setView('lessons')
  }

  const handleBackToCourses = () => {
    setSelectedCourse(null)
    setSelectedCategory(null)
    setSelectedLesson(null)
    setView('courses')
  }

  const handleBackToCategories = () => {
    setSelectedCategory(null)
    setSelectedLesson(null)
    setView('categories')
  }

  const renderCourses = () => (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-900">All Courses</h2>
          <p className="text-gray-600 mt-1">Manage your course library</p>
        </div>
        <Button
          onClick={() => {
            setEditingItem(null)
            setShowCourseModal(true)
          }}
          className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add Course
        </Button>
      </div>

      {loading ? (
        <div className="text-center py-12 text-gray-500">Loading courses...</div>
      ) : courses.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            No courses yet. Create your first course!
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {courses.map((course) => (
            <motion.div
              key={course.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <Card className="hover:shadow-lg transition-shadow cursor-pointer">
                <CardContent className="p-0">
                  <div className="aspect-video bg-gradient-to-br from-blue-100 to-green-100 flex items-center justify-center">
                    {course.thumbnail_url ? (
                      <img src={course.thumbnail_url} alt={course.title} className="w-full h-full object-cover" />
                    ) : (
                      <BookOpen className="w-16 h-16 text-gray-400" />
                    )}
                  </div>
                  <div className="p-4">
                    <div className="flex items-start justify-between mb-2">
                      <h3 className="font-bold text-lg">{course.title}</h3>
                      <Badge className={
                        course.status === 'Published' ? 'bg-green-100 text-green-800' :
                        course.status === 'Draft' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-gray-100 text-gray-800'
                      }>
                        {course.status}
                      </Badge>
                    </div>
                    <p className="text-sm text-gray-600 mb-3 line-clamp-2">{course.description}</p>
                    <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                      <span>{course.instructor}</span>
                      <span>{course.level}</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button
                        size="sm"
                        onClick={() => handleViewCourse(course)}
                        className="flex-1"
                      >
                        <FolderOpen className="w-4 h-4 mr-2" />
                        View Categories
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setEditingItem(course)
                          setShowCourseModal(true)
                        }}
                      >
                        <Edit className="w-4 h-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleDeleteCourse(course.id)}
                        className="text-red-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
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
          <h2 className="text-2xl font-bold text-gray-900">{selectedCourse?.title}</h2>
          <p className="text-gray-600 mt-1">Manage course categories and modules</p>
        </div>
        <Button
          onClick={() => {
            setEditingItem(null)
            setShowCategoryModal(true)
          }}
          className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add Category
        </Button>
      </div>

      {categories.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            No categories yet. Create your first category!
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {categories.map((category, index) => (
            <motion.div
              key={category.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="hover:shadow-lg transition-shadow">
                <CardContent className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                          <span className="font-bold text-blue-600">{index + 1}</span>
                        </div>
                        <h3 className="text-xl font-bold text-gray-900">{category.title}</h3>
                      </div>
                      {category.description && (
                        <p className="text-gray-600 ml-13">{category.description}</p>
                      )}
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button
                        size="sm"
                        onClick={() => handleViewCategory(category)}
                      >
                        <PlayCircle className="w-4 h-4 mr-2" />
                        View Lessons
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setEditingItem(category)
                          setShowCategoryModal(true)
                        }}
                      >
                        <Edit className="w-4 h-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleDeleteCategory(category.id)}
                        className="text-red-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}
    </div>
  )

  const renderLessons = () => (
    <div className="space-y-6">
      <div className="flex items-center space-x-4">
        <Button variant="outline" onClick={handleBackToCategories}>
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Categories
        </Button>
        <div className="flex-1">
          <h2 className="text-2xl font-bold text-gray-900">{selectedCategory?.title}</h2>
          <p className="text-gray-600 mt-1">Manage lessons in this category</p>
        </div>
        <Button
          onClick={() => {
            setEditingItem(null)
            setSelectedLesson(null)
            setShowLessonModal(true)
          }}
          className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
        >
          <Plus className="w-4 h-4 mr-2" />
          Add Lesson
        </Button>
      </div>

      {lessons.length === 0 ? (
        <Card>
          <CardContent className="text-center py-12 text-gray-500">
            No lessons yet. Create your first lesson!
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {lessons.map((lesson, index) => (
            <motion.div
              key={lesson.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className="hover:shadow-lg transition-shadow">
                <CardContent className="p-6">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex-1">
                      <div className="flex items-center space-x-3 mb-2">
                        <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center">
                          <PlayCircle className="w-5 h-5 text-green-600" />
                        </div>
                        <div>
                          <h3 className="text-lg font-bold text-gray-900">{lesson.title}</h3>
                          {lesson.duration && (
                            <span className="text-sm text-gray-500">{lesson.duration}</span>
                          )}
                        </div>
                        {lesson.is_free && (
                          <Badge className="bg-blue-100 text-blue-800">Free Preview</Badge>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          setEditingItem(lesson)
                          setSelectedLesson(lesson)
                          setShowLessonModal(true)
                        }}
                      >
                        <Edit className="w-4 h-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => handleDeleteLesson(lesson.id)}
                        className="text-red-600"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>

                  {lesson.description && (
                    <p className="text-gray-600 mb-4 ml-13">{lesson.description}</p>
                  )}

                  {lesson.video_url && (
                    <div className="mb-4 ml-13">
                      <div className="flex items-center space-x-2 text-sm text-gray-600">
                        <PlayCircle className="w-4 h-4" />
                        <a href={lesson.video_url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">
                          {lesson.video_url}
                        </a>
                      </div>
                    </div>
                  )}

                  {selectedLesson?.id === lesson.id && attachments.length > 0 && (
                    <div className="ml-13 mt-4 p-4 bg-gray-50 rounded-lg">
                      <h4 className="font-semibold text-gray-900 mb-3">Attachments</h4>
                      <div className="space-y-2">
                        {attachments.map((attachment) => (
                          <div key={attachment.id} className="flex items-center justify-between p-2 bg-white rounded border">
                            <div className="flex items-center space-x-3">
                              <FileText className="w-5 h-5 text-gray-400" />
                              <div>
                                <a href={attachment.file_url} target="_blank" rel="noopener noreferrer" className="text-sm font-medium text-blue-600 hover:underline">
                                  {attachment.file_name}
                                </a>
                                {attachment.file_size && (
                                  <span className="text-xs text-gray-500 ml-2">({attachment.file_size})</span>
                                )}
                              </div>
                            </div>
                            <Button
                              size="sm"
                              variant="ghost"
                              onClick={() => handleDeleteAttachment(attachment.id)}
                              className="text-red-600"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </div>
                        ))}
                      </div>
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

  return (
    <div className="p-6">
      <PageHeader
        title="Learning Management System"
        subtitle="Create and manage your courses, categories, and lessons"
      />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="mt-8"
      >
        {view === 'courses' && renderCourses()}
        {view === 'categories' && renderCategories()}
        {view === 'lessons' && renderLessons()}
      </motion.div>

      <CourseModal
        isOpen={showCourseModal}
        onClose={() => {
          setShowCourseModal(false)
          setEditingItem(null)
        }}
        course={editingItem}
        onSuccess={fetchCourses}
      />

      {selectedCourse && (
        <CategoryModal
          isOpen={showCategoryModal}
          onClose={() => {
            setShowCategoryModal(false)
            setEditingItem(null)
          }}
          courseId={selectedCourse.id}
          category={editingItem}
          onSuccess={() => fetchCategories(selectedCourse.id)}
        />
      )}

      {selectedCategory && (
        <LessonModal
          isOpen={showLessonModal}
          onClose={() => {
            setShowLessonModal(false)
            setEditingItem(null)
            setSelectedLesson(null)
          }}
          categoryId={selectedCategory.id}
          lesson={editingItem}
          onSuccess={() => fetchLessons(selectedCategory.id)}
        />
      )}
    </div>
  )
}
