import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { Plus, Eye, Edit, Trash2, Play, Users, Clock, BookOpen, Award, TrendingUp, Star, Download, Upload, X, Save } from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { KPICard } from '@/components/Common/KPICard'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { formatCurrency } from '@/lib/utils'

const mockCourses = [
  {
    courseId: 'C001',
    title: 'AI Automation Mastery',
    description: 'Complete guide to building AI-powered automation systems',
    category: 'AI & Automation',
    level: 'Intermediate',
    duration: '8 weeks',
    lessons: 24,
    enrolledStudents: 156,
    completionRate: 78,
    rating: 4.8,
    reviews: 89,
    price: 15000,
    status: 'Published',
    createdBy: 'John Smith',
    createdOn: '2024-01-10',
    lastUpdated: '2024-01-20',
    thumbnail: 'https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    courseId: 'C002',
    title: 'WhatsApp Business Automation',
    description: 'Master WhatsApp automation for business growth',
    category: 'Marketing Automation',
    level: 'Beginner',
    duration: '4 weeks',
    lessons: 16,
    enrolledStudents: 203,
    completionRate: 85,
    rating: 4.9,
    reviews: 124,
    price: 8000,
    status: 'Published',
    createdBy: 'Jane Doe',
    createdOn: '2024-01-08',
    lastUpdated: '2024-01-18',
    thumbnail: 'https://images.pexels.com/photos/267350/pexels-photo-267350.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    courseId: 'C003',
    title: 'Advanced CRM Integration',
    description: 'Connect and automate your CRM workflows',
    category: 'CRM & Sales',
    level: 'Advanced',
    duration: '6 weeks',
    lessons: 18,
    enrolledStudents: 89,
    completionRate: 65,
    rating: 4.7,
    reviews: 45,
    price: 12000,
    status: 'Published',
    createdBy: 'Mike Wilson',
    createdOn: '2024-01-12',
    lastUpdated: '2024-01-19',
    thumbnail: 'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    courseId: 'C004',
    title: 'Email Marketing Automation',
    description: 'Build powerful email sequences and campaigns',
    category: 'Email Marketing',
    level: 'Intermediate',
    duration: '5 weeks',
    lessons: 20,
    enrolledStudents: 134,
    completionRate: 72,
    rating: 4.6,
    reviews: 67,
    price: 10000,
    status: 'Draft',
    createdBy: 'Sarah Johnson',
    createdOn: '2024-01-15',
    lastUpdated: '2024-01-21',
    thumbnail: 'https://images.pexels.com/photos/4439901/pexels-photo-4439901.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    courseId: 'C005',
    title: 'Social Media Automation',
    description: 'Automate your social media presence and engagement',
    category: 'Social Media',
    level: 'Beginner',
    duration: '3 weeks',
    lessons: 12,
    enrolledStudents: 178,
    completionRate: 88,
    rating: 4.9,
    reviews: 98,
    price: 6000,
    status: 'Published',
    createdBy: 'Alex Chen',
    createdOn: '2024-01-05',
    lastUpdated: '2024-01-16',
    thumbnail: 'https://images.pexels.com/photos/267371/pexels-photo-267371.jpeg?auto=compress&cs=tinysrgb&w=400'
  }
]

const statusColors: Record<string, string> = {
  'Published': 'bg-green-100 text-green-800',
  'Draft': 'bg-yellow-100 text-yellow-800',
  'Archived': 'bg-gray-100 text-gray-800',
  'Under Review': 'bg-blue-100 text-blue-800'
}

const levelColors: Record<string, string> = {
  'Beginner': 'bg-green-100 text-green-800',
  'Intermediate': 'bg-yellow-100 text-yellow-800',
  'Advanced': 'bg-red-100 text-red-800'
}

const categoryColors: Record<string, string> = {
  'AI & Automation': 'bg-purple-100 text-purple-800',
  'Marketing Automation': 'bg-blue-100 text-blue-800',
  'CRM & Sales': 'bg-orange-100 text-orange-800',
  'Email Marketing': 'bg-pink-100 text-pink-800',
  'Social Media': 'bg-indigo-100 text-indigo-800'
}

export function Courses() {
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')
  const [levelFilter, setLevelFilter] = useState('')
  const [courses, setCourses] = useState(mockCourses)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [selectedCourse, setSelectedCourse] = useState<any>(null)
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    category: '',
    level: '',
    duration: '',
    lessons: 0,
    price: 0,
    thumbnail: ''
  })

  const filteredCourses = courses.filter(course => {
    const matchesSearch = course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         course.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         course.createdBy.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = !statusFilter || course.status === statusFilter
    const matchesCategory = !categoryFilter || course.category === categoryFilter
    const matchesLevel = !levelFilter || course.level === levelFilter
    return matchesSearch && matchesStatus && matchesCategory && matchesLevel
  })

  const totalCourses = courses.length
  const publishedCourses = courses.filter(c => c.status === 'Published').length
  const totalStudents = courses.reduce((sum, course) => sum + course.enrolledStudents, 0)
  const avgCompletionRate = Math.round(courses.reduce((sum, course) => sum + course.completionRate, 0) / courses.length)
  const totalRevenue = courses.reduce((sum, course) => sum + (course.price * course.enrolledStudents), 0)

  const handleCreateCourse = () => {
    const newCourse = {
      courseId: `C${String(courses.length + 1).padStart(3, '0')}`,
      ...formData,
      enrolledStudents: 0,
      completionRate: 0,
      rating: 0,
      reviews: 0,
      status: 'Draft',
      createdBy: 'Admin User',
      createdOn: new Date().toISOString().split('T')[0],
      lastUpdated: new Date().toISOString().split('T')[0]
    }
    setCourses(prev => [...prev, newCourse])
    setShowCreateModal(false)
    resetForm()
  }

  const handleEditCourse = () => {
    setCourses(prev => prev.map(course => 
      course.courseId === selectedCourse.courseId 
        ? { ...course, ...formData, lastUpdated: new Date().toISOString().split('T')[0] }
        : course
    ))
    setShowEditModal(false)
    resetForm()
  }

  const handleDeleteCourse = (courseId: string) => {
    if (confirm('Are you sure you want to delete this course?')) {
      setCourses(prev => prev.filter(course => course.courseId !== courseId))
    }
  }

  const handleViewCourse = (course: any) => {
    setSelectedCourse(course)
    setShowViewModal(true)
  }

  const handleEditClick = (course: any) => {
    setSelectedCourse(course)
    setFormData({
      title: course.title,
      description: course.description,
      category: course.category,
      level: course.level,
      duration: course.duration,
      lessons: course.lessons,
      price: course.price,
      thumbnail: course.thumbnail
    })
    setShowEditModal(true)
  }

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      category: '',
      level: '',
      duration: '',
      lessons: 0,
      price: 0,
      thumbnail: ''
    })
    setSelectedCourse(null)
  }

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`w-4 h-4 ${i < Math.floor(rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
      />
    ))
  }

  return (
    <div className="ppt-slide p-6">
      <PageHeader 
        title="Course Management"
        subtitle="Create → Publish → Track Performance"
        actions={[
          {
            label: 'Create Course',
            onClick: () => setShowCreateModal(true),
            variant: 'default',
            icon: Plus
          },
          {
            label: 'Bulk Import',
            onClick: () => {},
            variant: 'outline',
            icon: Upload
          },
          {
            label: 'Export Data',
            onClick: () => {},
            variant: 'secondary',
            icon: Download
          }
        ]}
      />

      {/* KPI Cards */}
      <motion.div 
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8"
        initial="hidden"
        animate="visible"
        variants={{
          hidden: { opacity: 0 },
          visible: {
            opacity: 1,
            transition: {
              staggerChildren: 0.1
            }
          }
        }}
      >
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Total Courses"
            value={totalCourses}
            change={12}
            colorScheme="blue"
            icon={BookOpen}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Published Courses"
            value={publishedCourses}
            change={8}
            colorScheme="green"
            icon={Play}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Total Students"
            value={totalStudents}
            change={15}
            colorScheme="purple"
            icon={Users}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Avg Completion"
            value={`${avgCompletionRate}%`}
            change={5}
            colorScheme="green"
            icon={Award}
          />
        </motion.div>
      </motion.div>

      {/* Filters */}
      <motion.div 
        className="mb-6 flex gap-4 flex-wrap"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <Input
          placeholder="Search courses by title, description, or instructor..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="max-w-md"
        />
        <select
          className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">All Status</option>
          <option value="Published">Published</option>
          <option value="Draft">Draft</option>
          <option value="Under Review">Under Review</option>
          <option value="Archived">Archived</option>
        </select>
        <select
          className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value)}
        >
          <option value="">All Categories</option>
          <option value="AI & Automation">AI & Automation</option>
          <option value="Marketing Automation">Marketing Automation</option>
          <option value="CRM & Sales">CRM & Sales</option>
          <option value="Email Marketing">Email Marketing</option>
          <option value="Social Media">Social Media</option>
        </select>
        <select
          className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
          value={levelFilter}
          onChange={(e) => setLevelFilter(e.target.value)}
        >
          <option value="">All Levels</option>
          <option value="Beginner">Beginner</option>
          <option value="Intermediate">Intermediate</option>
          <option value="Advanced">Advanced</option>
        </select>
      </motion.div>

      {/* Course Cards Grid */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8"
      >
        {filteredCourses.map((course, index) => (
          <motion.div
            key={course.courseId}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 * index }}
            whileHover={{ scale: 1.02 }}
            className="h-full"
          >
            <Card className="shadow-xl hover:shadow-2xl transition-all duration-300 h-full flex flex-col">
              <div className="relative">
                <img
                  src={course.thumbnail}
                  alt={course.title}
                  className="w-full h-48 object-cover rounded-t-lg"
                />
                <div className="absolute top-4 right-4">
                  <Badge className={statusColors[course.status]}>{course.status}</Badge>
                </div>
                <div className="absolute top-4 left-4">
                  <Badge className={levelColors[course.level]}>{course.level}</Badge>
                </div>
              </div>
              
              <CardContent className="p-6 flex-1 flex flex-col">
                <div className="flex-1">
                  <div className="mb-3">
                    <Badge variant="outline" className={categoryColors[course.category]}>
                      {course.category}
                    </Badge>
                  </div>
                  
                  <h3 className="text-xl font-bold text-brand-text mb-2 line-clamp-2">
                    {course.title}
                  </h3>
                  
                  <p className="text-gray-600 mb-4 line-clamp-2">
                    {course.description}
                  </p>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4 text-sm">
                    <div className="flex items-center space-x-2">
                      <Clock className="w-4 h-4 text-gray-400" />
                      <span>{course.duration}</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <BookOpen className="w-4 h-4 text-gray-400" />
                      <span>{course.lessons} lessons</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Users className="w-4 h-4 text-gray-400" />
                      <span>{course.enrolledStudents} students</span>
                    </div>
                    <div className="flex items-center space-x-2">
                      <Award className="w-4 h-4 text-gray-400" />
                      <span>{course.completionRate}% complete</span>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center space-x-1">
                      {renderStars(course.rating)}
                      <span className="text-sm text-gray-600 ml-2">
                        {course.rating} ({course.reviews} reviews)
                      </span>
                    </div>
                  </div>
                  
                  <div className="flex items-center justify-between mb-4">
                    <div className="text-2xl font-bold text-brand-primary">
                      {formatCurrency(course.price)}
                    </div>
                    <div className="text-sm text-gray-500">
                      by {course.createdBy}
                    </div>
                  </div>
                  
                  <div className="mb-4">
                    <div className="flex justify-between text-sm mb-1">
                      <span>Completion Rate</span>
                      <span>{course.completionRate}%</span>
                    </div>
                    <div className="w-full bg-gray-200 rounded-full h-2">
                      <div 
                        className="h-2 rounded-full bg-gradient-to-r from-brand-primary to-brand-accent"
                        style={{ width: `${course.completionRate}%` }}
                      />
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center space-x-2 pt-4 border-t">
                  <Button size="sm" variant="default" className="flex-1">
                    <Eye className="w-4 h-4 mr-2" />
                    <span onClick={() => handleViewCourse(course)}>View</span>
                  </Button>
                  <Button size="sm" variant="outline" onClick={() => handleEditClick(course)}>
                    <Edit className="w-4 h-4" />
                  </Button>
                  <Button size="sm" variant="outline" className="text-red-600 hover:text-red-700" onClick={() => handleDeleteCourse(course.courseId)}>
                    <Trash2 className="w-4 h-4" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ))}
      </motion.div>

      {/* Analytics Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {/* Top Performing Courses */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.4 }}
        >
          <Card className="shadow-xl">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <TrendingUp className="w-5 h-5 text-brand-primary" />
                <span>Top Performing Courses</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {courses
                  .sort((a, b) => (b.enrolledStudents * b.price) - (a.enrolledStudents * a.price))
                  .slice(0, 5)
                  .map((course, index) => {
                    const revenue = course.enrolledStudents * course.price
                    const maxRevenue = Math.max(...courses.map(c => c.enrolledStudents * c.price))
                    const percentage = (revenue / maxRevenue) * 100
                    
                    return (
                      <div key={course.courseId} className="space-y-2">
                        <div className="flex justify-between items-center">
                          <div className="flex items-center space-x-3">
                            <div className="w-8 h-8 rounded-full bg-brand-primary/10 flex items-center justify-center">
                              <span className="text-sm font-medium text-brand-primary">#{index + 1}</span>
                            </div>
                            <div>
                              <span className="font-medium">{course.title}</span>
                              <div className="text-sm text-gray-500">{course.enrolledStudents} students</div>
                            </div>
                          </div>
                          <div className="text-right">
                            <div className="font-medium">{formatCurrency(revenue)}</div>
                            <div className="text-sm text-gray-500">{course.rating}★</div>
                          </div>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <motion.div 
                            className="h-2 rounded-full bg-gradient-to-r from-brand-primary to-brand-accent"
                            initial={{ width: 0 }}
                            animate={{ width: `${percentage}%` }}
                            transition={{ delay: 0.6 + index * 0.1, duration: 0.5 }}
                          />
                        </div>
                      </div>
                    )
                  })}
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Course Categories Distribution */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.5 }}
        >
          <Card className="shadow-xl">
            <CardHeader>
              <CardTitle className="flex items-center space-x-2">
                <BookOpen className="w-5 h-5 text-brand-primary" />
                <span>Course Categories</span>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {Object.entries(
                  courses.reduce((acc, course) => {
                    acc[course.category] = (acc[course.category] || 0) + 1
                    return acc
                  }, {} as Record<string, number>)
                ).map(([category, count]) => {
                  const maxCount = Math.max(...Object.values(
                    courses.reduce((acc, course) => {
                      acc[course.category] = (acc[course.category] || 0) + 1
                      return acc
                    }, {} as Record<string, number>)
                  ))
                  const percentage = (count / maxCount) * 100
                  const studentsInCategory = courses
                    .filter(c => c.category === category)
                    .reduce((sum, c) => sum + c.enrolledStudents, 0)
                  
                  return (
                    <div key={category} className="space-y-2">
                      <div className="flex justify-between items-center">
                        <div className="flex items-center space-x-3">
                          <div className={`w-8 h-8 rounded-full flex items-center justify-center ${categoryColors[category]}`}>
                            <span className="text-xs font-medium">
                              {category.charAt(0)}
                            </span>
                          </div>
                          <span className="font-medium">{category}</span>
                        </div>
                        <div className="text-right">
                          <div className="font-medium">{count} course{count !== 1 ? 's' : ''}</div>
                          <div className="text-sm text-gray-500">{studentsInCategory} students</div>
                        </div>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <motion.div 
                          className="h-2 rounded-full bg-gradient-to-r from-brand-accent to-brand-primary"
                          initial={{ width: 0 }}
                          animate={{ width: `${percentage}%` }}
                          transition={{ delay: 0.8, duration: 0.5 }}
                        />
                      </div>
                    </div>
                  )
                })}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Create Course Modal */}
      {showCreateModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-brand-text">Create New Course</h2>
              <Button variant="ghost" size="sm" onClick={() => { setShowCreateModal(false); resetForm(); }}>
                <X className="w-4 h-4" />
              </Button>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Course Title</label>
                <Input
                  value={formData.title}
                  onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Enter course title"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
                <Textarea
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Enter course description"
                  rows={3}
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                  <Select value={formData.category} onValueChange={(value) => setFormData(prev => ({ ...prev, category: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="AI & Automation">AI & Automation</SelectItem>
                      <SelectItem value="Marketing Automation">Marketing Automation</SelectItem>
                      <SelectItem value="CRM & Sales">CRM & Sales</SelectItem>
                      <SelectItem value="Email Marketing">Email Marketing</SelectItem>
                      <SelectItem value="Social Media">Social Media</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Level</label>
                  <Select value={formData.level} onValueChange={(value) => setFormData(prev => ({ ...prev, level: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select level" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Beginner">Beginner</SelectItem>
                      <SelectItem value="Intermediate">Intermediate</SelectItem>
                      <SelectItem value="Advanced">Advanced</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Duration</label>
                  <Input
                    value={formData.duration}
                    onChange={(e) => setFormData(prev => ({ ...prev, duration: e.target.value }))}
                    placeholder="e.g., 8 weeks"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Lessons</label>
                  <Input
                    type="number"
                    value={formData.lessons}
                    onChange={(e) => setFormData(prev => ({ ...prev, lessons: parseInt(e.target.value) || 0 }))}
                    placeholder="Number of lessons"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Price (INR)</label>
                  <Input
                    type="number"
                    value={formData.price}
                    onChange={(e) => setFormData(prev => ({ ...prev, price: parseInt(e.target.value) || 0 }))}
                    placeholder="Course price"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Thumbnail URL</label>
                <Input
                  value={formData.thumbnail}
                  onChange={(e) => setFormData(prev => ({ ...prev, thumbnail: e.target.value }))}
                  placeholder="Enter thumbnail image URL"
                />
              </div>
            </div>
            
            <div className="flex items-center space-x-3 mt-6">
              <Button onClick={handleCreateCourse} disabled={!formData.title || !formData.category}>
                <Save className="w-4 h-4 mr-2" />
                Create Course
              </Button>
              <Button variant="outline" onClick={() => { setShowCreateModal(false); resetForm(); }}>
                Cancel
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* View Course Modal */}
      {showViewModal && selectedCourse && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-brand-text">Course Details</h2>
              <Button variant="ghost" size="sm" onClick={() => setShowViewModal(false)}>
                <X className="w-4 h-4" />
              </Button>
            </div>
            
            <div className="space-y-6">
              {selectedCourse.thumbnail && (
                <img
                  src={selectedCourse.thumbnail}
                  alt={selectedCourse.title}
                  className="w-full h-48 object-cover rounded-lg"
                />
              )}
              
              <div>
                <h3 className="text-xl font-bold text-brand-text mb-2">{selectedCourse.title}</h3>
                <p className="text-gray-600 mb-4">{selectedCourse.description}</p>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Category:</span>
                    <Badge className={categoryColors[selectedCourse.category]} variant="outline">
                      {selectedCourse.category}
                    </Badge>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Level:</span>
                    <Badge className={levelColors[selectedCourse.level]} variant="outline">
                      {selectedCourse.level}
                    </Badge>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Duration:</span>
                    <p className="font-medium">{selectedCourse.duration}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Lessons:</span>
                    <p className="font-medium">{selectedCourse.lessons}</p>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Price:</span>
                    <p className="font-medium text-brand-primary">{formatCurrency(selectedCourse.price)}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Status:</span>
                    <Badge className={statusColors[selectedCourse.status]}>
                      {selectedCourse.status}
                    </Badge>
                  </div>
                </div>
                
                <div className="grid grid-cols-3 gap-4 mb-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Enrolled Students:</span>
                    <p className="font-medium">{selectedCourse.enrolledStudents}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Completion Rate:</span>
                    <p className="font-medium">{selectedCourse.completionRate}%</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Rating:</span>
                    <div className="flex items-center space-x-1">
                      {renderStars(selectedCourse.rating)}
                      <span className="text-sm">({selectedCourse.reviews})</span>
                    </div>
                  </div>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <span className="text-sm font-medium text-gray-700">Created By:</span>
                    <p className="font-medium">{selectedCourse.createdBy}</p>
                  </div>
                  <div>
                    <span className="text-sm font-medium text-gray-700">Created On:</span>
                    <p className="font-medium">{selectedCourse.createdOn}</p>
                  </div>
                </div>
              </div>
            </div>
            
            <div className="flex items-center space-x-3 mt-6">
              <Button onClick={() => { setShowViewModal(false); handleEditClick(selectedCourse); }}>
                <Edit className="w-4 h-4 mr-2" />
                Edit Course
              </Button>
              <Button variant="outline" onClick={() => setShowViewModal(false)}>
                Close
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Course Modal */}
      {showEditModal && selectedCourse && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-brand-text">Edit Course</h2>
              <Button variant="ghost" size="sm" onClick={() => { setShowEditModal(false); resetForm(); }}>
                <X className="w-4 h-4" />
              </Button>
            </div>
            
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Course Title</label>
                <Input
                  value={formData.title}
                  onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
                  placeholder="Enter course title"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Description</label>
                <Textarea
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Enter course description"
                  rows={3}
                />
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Category</label>
                  <Select value={formData.category} onValueChange={(value) => setFormData(prev => ({ ...prev, category: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="AI & Automation">AI & Automation</SelectItem>
                      <SelectItem value="Marketing Automation">Marketing Automation</SelectItem>
                      <SelectItem value="CRM & Sales">CRM & Sales</SelectItem>
                      <SelectItem value="Email Marketing">Email Marketing</SelectItem>
                      <SelectItem value="Social Media">Social Media</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Level</label>
                  <Select value={formData.level} onValueChange={(value) => setFormData(prev => ({ ...prev, level: value }))}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select level" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="Beginner">Beginner</SelectItem>
                      <SelectItem value="Intermediate">Intermediate</SelectItem>
                      <SelectItem value="Advanced">Advanced</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Duration</label>
                  <Input
                    value={formData.duration}
                    onChange={(e) => setFormData(prev => ({ ...prev, duration: e.target.value }))}
                    placeholder="e.g., 8 weeks"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Lessons</label>
                  <Input
                    type="number"
                    value={formData.lessons}
                    onChange={(e) => setFormData(prev => ({ ...prev, lessons: parseInt(e.target.value) || 0 }))}
                    placeholder="Number of lessons"
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">Price (INR)</label>
                  <Input
                    type="number"
                    value={formData.price}
                    onChange={(e) => setFormData(prev => ({ ...prev, price: parseInt(e.target.value) || 0 }))}
                    placeholder="Course price"
                  />
                </div>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Thumbnail URL</label>
                <Input
                  value={formData.thumbnail}
                  onChange={(e) => setFormData(prev => ({ ...prev, thumbnail: e.target.value }))}
                  placeholder="Enter thumbnail image URL"
                />
              </div>
            </div>
            
            <div className="flex items-center space-x-3 mt-6">
              <Button onClick={handleEditCourse} disabled={!formData.title || !formData.category}>
                <Save className="w-4 h-4 mr-2" />
                Save Changes
              </Button>
              <Button variant="outline" onClick={() => { setShowEditModal(false); resetForm(); }}>
                Cancel
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* Revenue Summary */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6 }}
      >
        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <TrendingUp className="w-5 h-5 text-brand-primary" />
              <span>Revenue Summary</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div className="text-center">
                <div className="text-3xl font-bold text-brand-primary mb-2">
                  {formatCurrency(totalRevenue)}
                </div>
                <div className="text-gray-600">Total Revenue</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-brand-accent mb-2">
                  {formatCurrency(Math.round(totalRevenue / totalStudents))}
                </div>
                <div className="text-gray-600">Avg Revenue per Student</div>
              </div>
              <div className="text-center">
                <div className="text-3xl font-bold text-brand-primary mb-2">
                  {formatCurrency(Math.round(totalRevenue / publishedCourses))}
                </div>
                <div className="text-gray-600">Avg Revenue per Course</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </div>
  )
}