import React, { useState, useEffect } from 'react'
import { X, Plus, Zap } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { WorkflowNode, WorkflowNodeComponent } from './WorkflowNode'
import { NodeConfigModal } from './NodeConfigModal'

interface WorkflowAutomationModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (automation: any) => void
  automation?: any
  mode: 'create' | 'edit' | 'view'
}

const CATEGORIES = [
  'Lead Nurturing',
  'Student Engagement',
  'Payment Recovery',
  'Demo Management',
  'Affiliate Management',
  'Sales Recovery',
  'Customer Support'
]

export function WorkflowAutomationModal({
  isOpen,
  onClose,
  onSave,
  automation,
  mode
}: WorkflowAutomationModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    status: 'Draft',
    category: '',
    tags: [] as string[],
    created_by: 'Current User'
  })

  const [workflowNodes, setWorkflowNodes] = useState<WorkflowNode[]>([])
  const [nodeConfigOpen, setNodeConfigOpen] = useState(false)
  const [editingNode, setEditingNode] = useState<WorkflowNode | null>(null)
  const [nodeTypeToAdd, setNodeTypeToAdd] = useState<'trigger' | 'action'>('trigger')
  const [newTag, setNewTag] = useState('')

  useEffect(() => {
    if (automation && mode !== 'create') {
      setFormData({
        name: automation.name || '',
        description: automation.description || '',
        status: automation.status || 'Draft',
        category: automation.category || '',
        tags: automation.tags || [],
        created_by: automation.createdBy || 'Current User'
      })
      setWorkflowNodes(automation.workflowNodes || [])
    } else {
      setFormData({
        name: '',
        description: '',
        status: 'Draft',
        category: '',
        tags: [],
        created_by: 'Current User'
      })
      setWorkflowNodes([])
    }
  }, [automation, mode, isOpen])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    if (mode === 'view') return

    if (!formData.name.trim()) {
      alert('Please enter an automation name')
      return
    }

    const triggerNode = workflowNodes.find(n => n.type === 'trigger')
    if (!triggerNode) {
      alert('Please add a trigger to start the workflow')
      return
    }

    onSave({
      ...formData,
      workflowNodes
    })
  }

  const openNodeConfig = (nodeType: 'trigger' | 'action', node: WorkflowNode | null = null) => {
    setNodeTypeToAdd(nodeType)
    setEditingNode(node)
    setNodeConfigOpen(true)
  }

  const handleSaveNode = (node: WorkflowNode) => {
    if (editingNode) {
      setWorkflowNodes(prev => prev.map(n => n.id === node.id ? node : n))
    } else {
      if (node.type === 'trigger') {
        setWorkflowNodes(prev => [node, ...prev.filter(n => n.type !== 'trigger')])
      } else {
        setWorkflowNodes(prev => [...prev, node])
      }
    }
    setEditingNode(null)
  }

  const handleDeleteNode = (nodeId: string) => {
    setWorkflowNodes(prev => prev.filter(n => n.id !== nodeId))
  }

  const addTag = () => {
    if (newTag.trim() && !formData.tags.includes(newTag.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, newTag.trim()]
      }))
      setNewTag('')
    }
  }

  const removeTag = (tag: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(t => t !== tag)
    }))
  }

  if (!isOpen) return null

  const isReadOnly = mode === 'view'
  const triggerNode = workflowNodes.find(n => n.type === 'trigger')
  const actionNodes = workflowNodes.filter(n => n.type === 'action')

  return (
    <>
      <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4 overflow-y-auto">
        <div className="bg-white rounded-lg max-w-5xl w-full max-h-[90vh] overflow-y-auto">
          <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 rounded-lg bg-brand-primary/10 flex items-center justify-center">
                <Zap className="w-5 h-5 text-brand-primary" />
              </div>
              <div>
                <h2 className="text-xl font-bold text-brand-text">
                  {mode === 'create' ? 'Create Workflow Automation' : mode === 'edit' ? 'Edit Workflow' : 'View Workflow'}
                </h2>
                <p className="text-sm text-gray-600">
                  {mode === 'create' ? 'Build a new workflow with triggers and actions' : mode === 'edit' ? 'Update workflow configuration' : 'Workflow details'}
                </p>
              </div>
            </div>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <X className="w-6 h-6" />
            </button>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              <div className="lg:col-span-1 space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-brand-text mb-4">Workflow Info</h3>

                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Name *
                      </label>
                      <Input
                        type="text"
                        value={formData.name}
                        onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                        placeholder="e.g., Welcome New Leads"
                        disabled={isReadOnly}
                        required
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Description
                      </label>
                      <textarea
                        value={formData.description}
                        onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                        placeholder="Describe this workflow"
                        disabled={isReadOnly}
                        rows={3}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50"
                      />
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Status
                      </label>
                      <select
                        value={formData.status}
                        onChange={(e) => setFormData(prev => ({ ...prev, status: e.target.value }))}
                        disabled={isReadOnly}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50"
                      >
                        <option value="Draft">Draft</option>
                        <option value="Active">Active</option>
                        <option value="Paused">Paused</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Category
                      </label>
                      <select
                        value={formData.category}
                        onChange={(e) => setFormData(prev => ({ ...prev, category: e.target.value }))}
                        disabled={isReadOnly}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-brand-primary disabled:bg-gray-50"
                      >
                        <option value="">Select Category</option>
                        {CATEGORIES.map(cat => (
                          <option key={cat} value={cat}>{cat}</option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Tags
                      </label>
                      {!isReadOnly && (
                        <div className="flex space-x-2 mb-2">
                          <Input
                            type="text"
                            value={newTag}
                            onChange={(e) => setNewTag(e.target.value)}
                            placeholder="Add tag"
                            onKeyPress={(e) => {
                              if (e.key === 'Enter') {
                                e.preventDefault()
                                addTag()
                              }
                            }}
                          />
                          <Button
                            type="button"
                            onClick={addTag}
                            disabled={!newTag.trim()}
                            size="sm"
                          >
                            <Plus className="w-4 h-4" />
                          </Button>
                        </div>
                      )}
                      <div className="flex flex-wrap gap-2">
                        {formData.tags.map(tag => (
                          <span
                            key={tag}
                            className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-800"
                          >
                            {tag}
                            {!isReadOnly && (
                              <button
                                type="button"
                                onClick={() => removeTag(tag)}
                                className="ml-1 text-gray-500 hover:text-gray-700"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            )}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                </div>

                <div className="border-t border-gray-200 pt-6 flex flex-col space-y-3">
                  <Button type="button" variant="outline" onClick={onClose} className="w-full">
                    {isReadOnly ? 'Close' : 'Cancel'}
                  </Button>
                  {!isReadOnly && (
                    <Button type="submit" variant="default" className="w-full">
                      {mode === 'create' ? 'Create Workflow' : 'Save Changes'}
                    </Button>
                  )}
                </div>
              </div>

              <div className="lg:col-span-2 border-l border-gray-200 pl-6">
                <div className="flex items-center justify-between mb-6">
                  <h3 className="text-lg font-semibold text-brand-text">Workflow Builder</h3>
                  {!isReadOnly && (
                    <div className="flex space-x-2">
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => openNodeConfig('trigger', triggerNode || null)}
                      >
                        <Zap className="w-4 h-4 mr-2" />
                        {triggerNode ? 'Edit Trigger' : 'Add Trigger'}
                      </Button>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        onClick={() => openNodeConfig('action')}
                        disabled={!triggerNode}
                      >
                        <Plus className="w-4 h-4 mr-2" />
                        Add Action
                      </Button>
                    </div>
                  )}
                </div>

                <div className="bg-gray-50 rounded-lg p-6 min-h-[500px]">
                  {workflowNodes.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full py-20">
                      <div className="w-16 h-16 rounded-full bg-gray-200 flex items-center justify-center mb-4">
                        <Zap className="w-8 h-8 text-gray-400" />
                      </div>
                      <h4 className="text-lg font-medium text-gray-700 mb-2">No workflow nodes yet</h4>
                      <p className="text-sm text-gray-500 text-center max-w-sm mb-4">
                        Start by adding a trigger to define when this workflow should run
                      </p>
                      {!isReadOnly && (
                        <Button
                          type="button"
                          variant="default"
                          onClick={() => openNodeConfig('trigger')}
                        >
                          <Plus className="w-4 h-4 mr-2" />
                          Add Trigger
                        </Button>
                      )}
                    </div>
                  ) : (
                    <div className="space-y-0">
                      {triggerNode && (
                        <WorkflowNodeComponent
                          node={triggerNode}
                          onEdit={openNodeConfig.bind(null, 'trigger')}
                          onDelete={handleDeleteNode}
                          isFirst
                          isLast={actionNodes.length === 0}
                          isReadOnly={isReadOnly}
                        />
                      )}
                      {actionNodes.map((node, index) => (
                        <WorkflowNodeComponent
                          key={node.id}
                          node={node}
                          onEdit={openNodeConfig.bind(null, 'action')}
                          onDelete={handleDeleteNode}
                          isLast={index === actionNodes.length - 1}
                          isReadOnly={isReadOnly}
                        />
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </form>
        </div>
      </div>

      <NodeConfigModal
        isOpen={nodeConfigOpen}
        onClose={() => {
          setNodeConfigOpen(false)
          setEditingNode(null)
        }}
        onSave={handleSaveNode}
        node={editingNode}
        nodeType={nodeTypeToAdd}
        triggerNode={triggerNode}
      />
    </>
  )
}
