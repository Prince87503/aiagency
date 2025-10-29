import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { supabase } from '@/lib/supabase'
import { WorkflowAutomationModal } from '@/components/Automations/WorkflowAutomationModal'
import { 
  Plus, Play, Pause, Edit, Trash2, Copy, Settings, Zap, 
  Clock, Users, Mail, MessageCircle, Phone, Calendar,
  TrendingUp, Activity, CheckCircle, AlertCircle, Eye,
  Filter, Search, BarChart, Target, Workflow, Bot,
  ArrowRight, ArrowDown, GitBranch, Timer, Bell,
  Database, Globe, Smartphone, CreditCard, FileText,
  Send, UserPlus, Award, BookOpen, Star, Download
} from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { KPICard } from '@/components/Common/KPICard'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { formatDate } from '@/lib/utils'

const mockTemplates = [
  {
    id: 'TEMP-001',
    name: 'Lead Nurturing Sequence',
    description: '7-day email sequence for new leads with course recommendations',
    category: 'Lead Nurturing',
    uses: 45,
    rating: 4.8,
    actions: ['Email Sequence', 'WhatsApp Follow-up', 'Course Recommendation'],
    thumbnail: 'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    id: 'TEMP-002',
    name: 'Student Onboarding',
    description: 'Complete onboarding flow for new course enrollments',
    category: 'Student Engagement',
    uses: 67,
    rating: 4.9,
    actions: ['Welcome Email', 'Course Access', 'Community Invite'],
    thumbnail: 'https://images.pexels.com/photos/3861969/pexels-photo-3861969.jpeg?auto=compress&cs=tinysrgb&w=400'
  },
  {
    id: 'TEMP-003',
    name: 'Abandoned Cart Recovery',
    description: 'Win back customers who abandoned their course purchase',
    category: 'Sales Recovery',
    uses: 23,
    rating: 4.6,
    actions: ['Email Reminder', 'Discount Offer', 'SMS Follow-up'],
    thumbnail: 'https://images.pexels.com/photos/4439901/pexels-photo-4439901.jpeg?auto=compress&cs=tinysrgb&w=400'
  }
]

const statusColors: Record<string, string> = {
  'Active': 'bg-green-100 text-green-800',
  'Paused': 'bg-yellow-100 text-yellow-800',
  'Draft': 'bg-gray-100 text-gray-800',
  'Error': 'bg-red-100 text-red-800'
}

const categoryColors: Record<string, string> = {
  'Lead Nurturing': 'bg-blue-100 text-blue-800',
  'Student Engagement': 'bg-purple-100 text-purple-800',
  'Payment Recovery': 'bg-red-100 text-red-800',
  'Demo Management': 'bg-orange-100 text-orange-800',
  'Affiliate Management': 'bg-green-100 text-green-800',
  'Sales Recovery': 'bg-yellow-100 text-yellow-800'
}


export function Automations() {
  const [activeTab, setActiveTab] = useState<'automations' | 'templates' | 'analytics'>('automations')
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [categoryFilter, setCategoryFilter] = useState('')
  const [automations, setAutomations] = useState<any[]>([])
  const [templates, setTemplates] = useState(mockTemplates)
  const [loading, setLoading] = useState(false)
  const [modalOpen, setModalOpen] = useState(false)
  const [modalMode, setModalMode] = useState<'create' | 'edit' | 'view'>('create')
  const [selectedAutomation, setSelectedAutomation] = useState<any>(null)

  useEffect(() => {
    fetchAutomations()
    fetchTemplates()
  }, [])

  const fetchAutomations = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('automations')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error

      const formattedData = (data || []).map(automation => ({
        id: automation.id,
        name: automation.name,
        description: automation.description,
        status: automation.status,
        category: automation.category,
        runsToday: automation.runs_today || 0,
        totalRuns: automation.total_runs || 0,
        successRate: Number(automation.success_rate) || 0,
        lastRun: automation.last_run ? new Date(automation.last_run).toLocaleString() : 'Never',
        createdBy: automation.created_by,
        createdAt: automation.created_at.split('T')[0],
        tags: automation.tags || [],
        workflowNodes: automation.workflow_nodes || []
      }))
      setAutomations(formattedData)
    } catch (error) {
      console.error('Failed to fetch automations:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchTemplates = async () => {
    try {
      const { data, error } = await supabase
        .from('automation_templates')
        .select('*')
        .order('created_at', { ascending: false })

      if (error) throw error

      if (data && data.length > 0) {
        const formattedData = data.map(template => ({
          id: template.id,
          name: template.name,
          description: template.description,
          category: template.category,
          uses: template.uses || 0,
          rating: Number(template.rating) || 0,
          actions: template.actions || [],
          thumbnail: template.thumbnail || 'https://images.pexels.com/photos/3184292/pexels-photo-3184292.jpeg?auto=compress&cs=tinysrgb&w=400'
        }))
        setTemplates(formattedData)
      }
    } catch (error) {
      console.error('Failed to fetch templates:', error)
    }
  }

  const filteredAutomations = automations.filter(automation => {
    const matchesSearch = automation.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         automation.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         automation.createdBy.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = !statusFilter || automation.status === statusFilter
    const matchesCategory = !categoryFilter || automation.category === categoryFilter
    return matchesSearch && matchesStatus && matchesCategory
  })

  const filteredTemplates = templates.filter(template =>
    template.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    template.description.toLowerCase().includes(searchTerm.toLowerCase())
  )

  // Calculate KPIs
  const totalAutomations = automations.length
  const activeAutomations = automations.filter(a => a.status === 'Active').length
  const totalRunsToday = automations.reduce((sum, a) => sum + a.runsToday, 0)
  const avgSuccessRate = automations.reduce((sum, a) => sum + a.successRate, 0) / automations.length

  const toggleAutomationStatus = async (automationId: string) => {
    const automation = automations.find(a => a.id === automationId)
    if (!automation) return

    const newStatus = automation.status === 'Active' ? 'Paused' : 'Active'

    try {
      const { error } = await supabase
        .from('automations')
        .update({ status: newStatus })
        .eq('id', automationId)

      if (error) throw error

      setAutomations(prev => prev.map(a =>
        a.id === automationId
          ? { ...a, status: newStatus }
          : a
      ))
    } catch (error) {
      console.error('Failed to update automation status:', error)
      alert('Failed to update automation status. Please try again.')
    }
  }

  const duplicateAutomation = async (automationId: string) => {
    const automation = automations.find(a => a.id === automationId)
    if (!automation) return

    try {
      const { data, error } = await supabase
        .from('automations')
        .insert([{
          name: `${automation.name} (Copy)`,
          description: automation.description,
          status: 'Draft',
          trigger: automation.trigger,
          trigger_type: automation.triggerType,
          actions: automation.actions,
          category: automation.category,
          runs_today: 0,
          total_runs: 0,
          success_rate: 0,
          created_by: automation.createdBy,
          tags: automation.tags
        }])
        .select()
        .single()

      if (error) throw error

      if (data) {
        const newAutomation = {
          id: data.id,
          name: data.name,
          description: data.description,
          status: data.status,
          trigger: data.trigger,
          triggerType: data.trigger_type,
          actions: data.actions || [],
          category: data.category,
          runsToday: 0,
          totalRuns: 0,
          successRate: 0,
          lastRun: 'Never',
          createdBy: data.created_by,
          createdAt: data.created_at.split('T')[0],
          isTemplate: false,
          tags: data.tags || []
        }
        setAutomations(prev => [newAutomation, ...prev])
      }
    } catch (error) {
      console.error('Failed to duplicate automation:', error)
      alert('Failed to duplicate automation. Please try again.')
    }
  }

  const deleteAutomation = async (automationId: string) => {
    if (!confirm('Are you sure you want to delete this automation?')) return

    try {
      const { error } = await supabase
        .from('automations')
        .delete()
        .eq('id', automationId)

      if (error) throw error

      setAutomations(prev => prev.filter(a => a.id !== automationId))
    } catch (error) {
      console.error('Failed to delete automation:', error)
      alert('Failed to delete automation. Please try again.')
    }
  }

  const openCreateModal = () => {
    setSelectedAutomation(null)
    setModalMode('create')
    setModalOpen(true)
  }

  const openEditModal = (automation: any) => {
    setSelectedAutomation(automation)
    setModalMode('edit')
    setModalOpen(true)
  }

  const openViewModal = (automation: any) => {
    setSelectedAutomation(automation)
    setModalMode('view')
    setModalOpen(true)
  }

  const handleSaveAutomation = async (automationData: any) => {
    try {
      setLoading(true)

      if (modalMode === 'create') {
        const { data, error } = await supabase
          .from('automations')
          .insert([{
            name: automationData.name,
            description: automationData.description,
            status: automationData.status,
            category: automationData.category,
            runs_today: 0,
            total_runs: 0,
            success_rate: 0,
            created_by: automationData.created_by,
            tags: automationData.tags,
            workflow_nodes: automationData.workflowNodes || []
          }])
          .select()
          .single()

        if (error) throw error

        if (data) {
          const newAutomation = {
            id: data.id,
            name: data.name,
            description: data.description,
            status: data.status,
            category: data.category,
            runsToday: 0,
            totalRuns: 0,
            successRate: 0,
            lastRun: 'Never',
            createdBy: data.created_by,
            createdAt: data.created_at.split('T')[0],
            tags: data.tags || [],
            workflowNodes: data.workflow_nodes || []
          }
          setAutomations(prev => [newAutomation, ...prev])
          alert('Automation created successfully!')
        }
      } else if (modalMode === 'edit') {
        const { error } = await supabase
          .from('automations')
          .update({
            name: automationData.name,
            description: automationData.description,
            status: automationData.status,
            category: automationData.category,
            tags: automationData.tags,
            workflow_nodes: automationData.workflowNodes || [],
            updated_at: new Date().toISOString()
          })
          .eq('id', selectedAutomation.id)

        if (error) throw error

        setAutomations(prev => prev.map(a =>
          a.id === selectedAutomation.id
            ? {
                ...a,
                name: automationData.name,
                description: automationData.description,
                status: automationData.status,
                category: automationData.category,
                tags: automationData.tags,
                workflowNodes: automationData.workflowNodes || []
              }
            : a
        ))
        alert('Automation updated successfully!')
      }

      setModalOpen(false)
      setSelectedAutomation(null)
    } catch (error) {
      console.error('Failed to save automation:', error)
      alert('Failed to save automation. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const useTemplate = async (templateId: string) => {
    const template = templates.find(t => t.id === templateId)
    if (!template) return

    try {
      const { data, error } = await supabase
        .from('automations')
        .insert([{
          name: template.name,
          description: template.description,
          status: 'Draft',
          trigger: '',
          trigger_type: '',
          actions: template.actions,
          category: template.category,
          runs_today: 0,
          total_runs: 0,
          success_rate: 0,
          created_by: 'Current User',
          tags: []
        }])
        .select()
        .single()

      if (error) throw error

      await supabase
        .from('automation_templates')
        .update({ uses: template.uses + 1 })
        .eq('id', templateId)

      if (data) {
        const newAutomation = {
          id: data.id,
          name: data.name,
          description: data.description,
          status: data.status,
          trigger: data.trigger,
          triggerType: data.trigger_type,
          actions: data.actions || [],
          category: data.category,
          runsToday: 0,
          totalRuns: 0,
          successRate: 0,
          lastRun: 'Never',
          createdBy: data.created_by,
          createdAt: data.created_at.split('T')[0],
          isTemplate: false,
          tags: data.tags || []
        }
        setAutomations(prev => [newAutomation, ...prev])
        setActiveTab('automations')
        alert('Automation created from template successfully!')
      }
    } catch (error) {
      console.error('Failed to create automation from template:', error)
      alert('Failed to create automation. Please try again.')
    }
  }

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`w-4 h-4 ${i < Math.floor(rating) ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
      />
    ))
  }

  const tabs = [
    { id: 'automations', label: 'Automations', icon: Zap },
    { id: 'templates', label: 'Templates', icon: FileText },
    { id: 'analytics', label: 'Analytics', icon: BarChart }
  ]

  return (
    <div className="ppt-slide p-6">
      <PageHeader 
        title="AI Automation Center"
        subtitle="Build → Deploy → Monitor Intelligent Workflows"
        actions={[
          {
            label: 'Create Automation',
            onClick: openCreateModal,
            variant: 'default',
            icon: Plus
          },
          {
            label: 'Import Template',
            onClick: () => setActiveTab('templates'),
            variant: 'outline',
            icon: Download
          },
          {
            label: 'Workflow Builder',
            onClick: openCreateModal,
            variant: 'secondary',
            icon: Workflow
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
            title="Total Automations"
            value={totalAutomations}
            change={12}
            colorScheme="blue"
            icon={Zap}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Active Automations"
            value={activeAutomations}
            change={8}
            colorScheme="green"
            icon={Activity}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Runs Today"
            value={totalRunsToday}
            change={15}
            colorScheme="purple"
            icon={TrendingUp}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Success Rate"
            value={`${avgSuccessRate.toFixed(1)}%`}
            change={5}
            colorScheme="green"
            icon={Target}
          />
        </motion.div>
      </motion.div>

      {/* Tab Navigation */}
      <motion.div 
        className="mb-6"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="flex space-x-1 bg-gray-100 p-1 rounded-lg w-fit">
          {tabs.map((tab) => {
            const Icon = tab.icon
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as any)}
                className={`flex items-center space-x-2 px-6 py-2 rounded-md font-medium transition-all ${
                  activeTab === tab.id
                    ? 'bg-white text-brand-primary shadow-sm'
                    : 'text-gray-600 hover:text-brand-primary'
                }`}
              >
                <Icon className="w-4 h-4" />
                <span>{tab.label}</span>
              </button>
            )
          })}
        </div>
      </motion.div>

      {/* Filters */}
      <motion.div 
        className="mb-6 flex gap-4 flex-wrap"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder={`Search ${activeTab}...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 max-w-md"
          />
        </div>
        {activeTab === 'automations' && (
          <>
            <select
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
            >
              <option value="">All Status</option>
              <option value="Active">Active</option>
              <option value="Paused">Paused</option>
              <option value="Draft">Draft</option>
              <option value="Error">Error</option>
            </select>
            <select
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary"
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
            >
              <option value="">All Categories</option>
              <option value="Lead Nurturing">Lead Nurturing</option>
              <option value="Student Engagement">Student Engagement</option>
              <option value="Payment Recovery">Payment Recovery</option>
              <option value="Demo Management">Demo Management</option>
              <option value="Affiliate Management">Affiliate Management</option>
            </select>
          </>
        )}
      </motion.div>

      {/* Content based on active tab */}
      {activeTab === 'automations' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-8"
        >
          <Card className="shadow-xl">
            <CardHeader>
              <CardTitle>Active Automations</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {filteredAutomations.map((automation, index) => (
                    <motion.div
                      key={automation.id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.1 * index }}
                      className="border border-gray-200 rounded-lg p-6 hover:shadow-lg transition-all duration-300"
                    >
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-start space-x-4">
                          <div className="w-12 h-12 rounded-lg bg-brand-primary/10 flex items-center justify-center">
                            <Workflow className="w-6 h-6 text-brand-primary" />
                          </div>
                          <div className="flex-1">
                            <div className="flex items-center space-x-3 mb-2">
                              <h3 className="text-lg font-semibold text-brand-text">{automation.name}</h3>
                              <Badge className={statusColors[automation.status]}>{automation.status}</Badge>
                              <Badge variant="outline" className={categoryColors[automation.category]}>
                                {automation.category}
                              </Badge>
                            </div>
                            <p className="text-gray-600 mb-3">{automation.description}</p>
                            <div className="flex flex-wrap gap-2 mb-3">
                              {automation.tags.map((tag) => (
                                <Badge key={tag} variant="outline" className="text-xs">
                                  {tag}
                                </Badge>
                              ))}
                            </div>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => toggleAutomationStatus(automation.id)}
                            className={automation.status === 'Active' ? 'text-yellow-600' : 'text-green-600'}
                          >
                            {automation.status === 'Active' ? (
                              <Pause className="w-4 h-4" />
                            ) : (
                              <Play className="w-4 h-4" />
                            )}
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => openViewModal(automation)}
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => openEditModal(automation)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            onClick={() => duplicateAutomation(automation.id)}
                          >
                            <Copy className="w-4 h-4" />
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="text-red-600 hover:text-red-700"
                            onClick={() => deleteAutomation(automation.id)}
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </div>

                      {/* Workflow Preview */}
                      <div className="mb-4 p-4 bg-gray-50 rounded-lg">
                        <div className="flex items-center space-x-2 mb-3">
                          <Workflow className="w-4 h-4 text-brand-primary" />
                          <span className="text-sm font-medium text-brand-text">Workflow</span>
                        </div>
                        <div className="flex items-center space-x-2 overflow-x-auto">
                          {automation.workflowNodes && automation.workflowNodes.length > 0 ? (
                            automation.workflowNodes.map((node: any, idx: number) => (
                              <React.Fragment key={node.id}>
                                <div className={`flex items-center space-x-2 px-3 py-1 rounded-full text-sm whitespace-nowrap ${
                                  node.type === 'trigger'
                                    ? 'bg-blue-100 text-blue-800'
                                    : 'bg-green-100 text-green-800'
                                }`}>
                                  {node.type === 'trigger' ? (
                                    <Zap className="w-3 h-3" />
                                  ) : (
                                    <CheckCircle className="w-3 h-3" />
                                  )}
                                  <span>{node.name}</span>
                                </div>
                                {idx < automation.workflowNodes.length - 1 && (
                                  <ArrowRight className="w-4 h-4 text-gray-400 flex-shrink-0" />
                                )}
                              </React.Fragment>
                            ))
                          ) : (
                            <p className="text-sm text-gray-500 italic">No workflow nodes configured</p>
                          )}
                        </div>
                      </div>

                      {/* Stats */}
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <div className="text-center">
                          <div className="text-2xl font-bold text-brand-primary">{automation.runsToday}</div>
                          <div className="text-sm text-gray-600">Runs Today</div>
                        </div>
                        <div className="text-center">
                          <div className="text-2xl font-bold text-brand-accent">{automation.totalRuns}</div>
                          <div className="text-sm text-gray-600">Total Runs</div>
                        </div>
                        <div className="text-center">
                          <div className="text-2xl font-bold text-green-600">{automation.successRate}%</div>
                          <div className="text-sm text-gray-600">Success Rate</div>
                        </div>
                        <div className="text-center">
                          <div className="text-sm font-medium text-gray-900">{automation.lastRun}</div>
                          <div className="text-sm text-gray-600">Last Run</div>
                        </div>
                      </div>

                      {/* Creator Info */}
                      <div className="mt-4 pt-4 border-t border-gray-200 flex items-center justify-between text-sm text-gray-500">
                        <div className="flex items-center space-x-2">
                          <Avatar className="h-6 w-6">
                            <AvatarFallback className="bg-brand-primary text-white text-xs">
                              {automation.createdBy.split(' ').map(n => n[0]).join('')}
                            </AvatarFallback>
                          </Avatar>
                          <span>Created by {automation.createdBy}</span>
                        </div>
                        <span>Created: {formatDate(automation.createdAt)}</span>
                      </div>
                    </motion.div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      )}

      {activeTab === 'templates' && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8"
        >
          {filteredTemplates.map((template, index) => (
            <motion.div
              key={template.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 * index }}
              whileHover={{ scale: 1.02 }}
              className="h-full"
            >
              <Card className="shadow-xl hover:shadow-2xl transition-all duration-300 h-full flex flex-col">
                <div className="relative">
                  <img
                    src={template.thumbnail}
                    alt={template.name}
                    className="w-full h-48 object-cover rounded-t-lg"
                  />
                  <div className="absolute top-4 right-4">
                    <Badge className={categoryColors[template.category]}>{template.category}</Badge>
                  </div>
                </div>
                
                <CardContent className="p-6 flex-1 flex flex-col">
                  <div className="flex-1">
                    <h3 className="text-xl font-bold text-brand-text mb-2 line-clamp-2">
                      {template.name}
                    </h3>
                    
                    <p className="text-gray-600 mb-4 line-clamp-2">
                      {template.description}
                    </p>
                    
                    <div className="mb-4">
                      <div className="text-sm font-medium text-gray-700 mb-2">Actions Included</div>
                      <div className="flex flex-wrap gap-2">
                        {template.actions.map((action) => (
                          <Badge key={action} variant="outline" className="text-xs">
                            {action}
                          </Badge>
                        ))}
                      </div>
                    </div>
                    
                    <div className="flex items-center justify-between mb-4">
                      <div className="flex items-center space-x-1">
                        {renderStars(template.rating)}
                        <span className="text-sm text-gray-600 ml-2">
                          {template.rating}
                        </span>
                      </div>
                      <div className="text-sm text-gray-500">
                        {template.uses} uses
                      </div>
                    </div>
                  </div>
                  
                  <div className="flex items-center space-x-2 pt-4 border-t">
                    <Button
                      size="sm"
                      variant="default"
                      className="flex-1"
                      onClick={() => useTemplate(template.id)}
                    >
                      <Plus className="w-4 h-4 mr-2" />
                      Use Template
                    </Button>
                    <Button size="sm" variant="outline">
                      <Eye className="w-4 h-4" />
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </motion.div>
      )}

      {activeTab === 'analytics' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          {/* Automation Performance */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <TrendingUp className="w-5 h-5 text-brand-primary" />
                  <span>Top Performing Automations</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {automations
                    .sort((a, b) => b.successRate - a.successRate)
                    .slice(0, 5)
                    .map((automation, index) => {
                      const maxSuccessRate = Math.max(...automations.map(a => a.successRate))
                      const percentage = (automation.successRate / maxSuccessRate) * 100
                      
                      return (
                        <div key={automation.id} className="space-y-2">
                          <div className="flex justify-between items-center">
                            <div className="flex items-center space-x-3">
                              <div className="w-8 h-8 rounded-full bg-brand-primary/10 flex items-center justify-center">
                                <span className="text-sm font-medium text-brand-primary">#{index + 1}</span>
                              </div>
                              <div>
                                <span className="font-medium">{automation.name}</span>
                                <div className="text-sm text-gray-500">{automation.totalRuns} runs</div>
                              </div>
                            </div>
                            <div className="text-right">
                              <div className="font-medium">{automation.successRate}%</div>
                              <div className="text-sm text-gray-500">success</div>
                            </div>
                          </div>
                          <div className="w-full bg-gray-200 rounded-full h-2">
                            <motion.div 
                              className="h-2 rounded-full bg-gradient-to-r from-brand-primary to-brand-accent"
                              initial={{ width: 0 }}
                              animate={{ width: `${percentage}%` }}
                              transition={{ delay: 0.5 + index * 0.1, duration: 0.5 }}
                            />
                          </div>
                        </div>
                      )
                    })}
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Category Distribution */}
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.4 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <BarChart className="w-5 h-5 text-brand-primary" />
                  <span>Automation Categories</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {Object.entries(
                    automations.reduce((acc, automation) => {
                      acc[automation.category] = (acc[automation.category] || 0) + 1
                      return acc
                    }, {} as Record<string, number>)
                  ).map(([category, count]) => {
                    const maxCount = Math.max(...Object.values(
                      automations.reduce((acc, automation) => {
                        acc[automation.category] = (acc[automation.category] || 0) + 1
                        return acc
                      }, {} as Record<string, number>)
                    ))
                    const percentage = (count / maxCount) * 100
                    const totalRuns = automations
                      .filter(a => a.category === category)
                      .reduce((sum, a) => sum + a.totalRuns, 0)
                    
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
                            <div className="font-medium">{count} automation{count !== 1 ? 's' : ''}</div>
                            <div className="text-sm text-gray-500">{totalRuns} runs</div>
                          </div>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                          <motion.div 
                            className="h-2 rounded-full bg-gradient-to-r from-brand-accent to-brand-primary"
                            initial={{ width: 0 }}
                            animate={{ width: `${percentage}%` }}
                            transition={{ delay: 0.7, duration: 0.5 }}
                          />
                        </div>
                      </div>
                    )
                  })}
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Recent Activity */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Activity className="w-5 h-5 text-brand-primary" />
                  <span>Recent Activity</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {[
                    { action: 'Welcome New Leads automation triggered', time: '2 mins ago', status: 'success' },
                    { action: 'Course Completion Follow-up completed', time: '15 mins ago', status: 'success' },
                    { action: 'Payment Failed Recovery started', time: '1 hour ago', status: 'warning' },
                    { action: 'Demo Booking Reminder paused', time: '2 hours ago', status: 'info' },
                    { action: 'Affiliate Commission Alert executed', time: '3 hours ago', status: 'success' }
                  ].map((activity, index) => (
                    <motion.div
                      key={index}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.7 + index * 0.1 }}
                      className="flex items-start space-x-3 p-3 rounded-lg bg-gray-50"
                    >
                      <div className={`p-1 rounded-full ${
                        activity.status === 'success' ? 'bg-green-100' :
                        activity.status === 'warning' ? 'bg-yellow-100' :
                        activity.status === 'info' ? 'bg-blue-100' : 'bg-gray-100'
                      }`}>
                        {activity.status === 'success' ? (
                          <CheckCircle className="w-4 h-4 text-green-600" />
                        ) : activity.status === 'warning' ? (
                          <AlertCircle className="w-4 h-4 text-yellow-600" />
                        ) : (
                          <Clock className="w-4 h-4 text-blue-600" />
                        )}
                      </div>
                      <div className="flex-1">
                        <p className="text-sm font-medium text-gray-900">{activity.action}</p>
                        <p className="text-xs text-gray-500">{activity.time}</p>
                      </div>
                    </motion.div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* System Health */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6 }}
          >
            <Card className="shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Bot className="w-5 h-5 text-brand-primary" />
                  <span>System Health</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {[
                    { metric: 'API Response Time', value: '120ms', status: 'good', target: '< 200ms' },
                    { metric: 'Queue Processing', value: '98.5%', status: 'good', target: '> 95%' },
                    { metric: 'Error Rate', value: '0.2%', status: 'good', target: '< 1%' },
                    { metric: 'Active Connections', value: '1,234', status: 'good', target: '< 2,000' }
                  ].map((health, index) => (
                    <div key={health.metric} className="flex items-center justify-between p-3 border border-gray-200 rounded-lg">
                      <div className="flex items-center space-x-3">
                        <div className={`w-3 h-3 rounded-full ${
                          health.status === 'good' ? 'bg-green-500' :
                          health.status === 'warning' ? 'bg-yellow-500' : 'bg-red-500'
                        }`} />
                        <div>
                          <div className="font-medium text-sm">{health.metric}</div>
                          <div className="text-xs text-gray-500">Target: {health.target}</div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="font-bold text-brand-primary">{health.value}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </motion.div>
        </div>
      )}

      <WorkflowAutomationModal
        isOpen={modalOpen}
        onClose={() => {
          setModalOpen(false)
          setSelectedAutomation(null)
        }}
        onSave={handleSaveAutomation}
        automation={selectedAutomation}
        mode={modalMode}
      />
    </div>
  )
}