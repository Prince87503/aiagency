import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Settings, Users, Shield, Database, Search, Save, X, Eye, CreditCard as Edit, Trash2, Plus, MoreVertical } from 'lucide-react'
import { PageHeader } from '@/components/Common/PageHeader'
import { KPICard } from '@/components/Common/KPICard'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu'
import { supabase } from '@/lib/supabase'

const availableTools = [
  { id: 'ghl-dashboard', name: 'GHL Dashboard', icon: '🏢', description: 'GoHighLevel CRM and automation platform' },
  { id: 'lms-portal', name: 'LMS Portal', icon: '📚', description: 'Learning Management System access' },
  { id: 'canva', name: 'Canva', icon: '🎨', description: 'Design and graphics creation tool' },
  { id: 'gmap-extractor', name: 'GMAP Extractor', icon: '🗺️', description: 'Google Maps data extraction tool' },
  { id: 'whatsapp-api', name: 'WhatsApp Business API', icon: '💬', description: 'WhatsApp automation and messaging' },
  { id: 'ai-content', name: 'AI Content Generator', icon: '🤖', description: 'AI-powered content creation' },
  { id: 'automation-builder', name: 'n8n Automation Builder', icon: '⚡', description: 'n8n workflow automation platform' }
]

export function ToolsAccess() {
  const [searchTerm, setSearchTerm] = useState('')
  const [members, setMembers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [showAssignModal, setShowAssignModal] = useState(false)
  const [showViewModal, setShowViewModal] = useState(false)
  const [selectedMember, setSelectedMember] = useState<any>(null)
  const [toolsFormData, setToolsFormData] = useState({
    selectedMember: '',
    selectedTools: [] as string[]
  })

  useEffect(() => {
    fetchMembersWithToolsAccess()
  }, [])

  const fetchMembersWithToolsAccess = async () => {
    try {
      setLoading(true)
      const { data: enrolledMembers, error: membersError } = await supabase
        .from('enrolled_members')
        .select('*')
        .order('created_at', { ascending: false })

      if (membersError) throw membersError

      const { data: toolsAccess, error: toolsError } = await supabase
        .from('member_tools_access')
        .select('*')

      if (toolsError) throw toolsError

      const membersWithTools = enrolledMembers.map((member: any) => {
        const memberTools = toolsAccess?.find((ta: any) => ta.enrolled_member_id === member.id)
        return {
          id: member.id,
          memberId: member.member_id,
          name: member.full_name,
          email: member.email,
          phone: member.phone,
          plan: member.plan_type || 'Basic',
          status: member.status || 'Active',
          joinedOn: member.created_at,
          toolsAccess: memberTools?.tools_access || [],
          toolsAccessId: memberTools?.id || null
        }
      })

      setMembers(membersWithTools)
    } catch (error) {
      console.error('Failed to fetch members and tools access:', error)
      alert('Failed to load members data. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const filteredMembers = members.filter(member =>
    member.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    member.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
    member.memberId.toLowerCase().includes(searchTerm.toLowerCase())
  )

  // Calculate KPIs
  const totalMembers = members.length
  const membersWithAccess = members.filter(m => m.toolsAccess.length > 0).length
  const totalToolsAssigned = members.reduce((sum, m) => sum + m.toolsAccess.length, 0)
  const avgToolsPerMember = Math.round(totalToolsAssigned / totalMembers)

  const handleAssignTools = async () => {
    try {
      const selectedMemberData = members.find(m => m.id === toolsFormData.selectedMember)
      if (!selectedMemberData) return

      if (selectedMemberData.toolsAccessId) {
        const { error } = await supabase
          .from('member_tools_access')
          .update({
            tools_access: toolsFormData.selectedTools
          })
          .eq('id', selectedMemberData.toolsAccessId)

        if (error) throw error
      } else {
        const { error } = await supabase
          .from('member_tools_access')
          .insert({
            enrolled_member_id: selectedMemberData.id,
            tools_access: toolsFormData.selectedTools
          })

        if (error) throw error
      }

      await fetchMembersWithToolsAccess()
      setShowAssignModal(false)
      resetToolsForm()
      alert('Tools access updated successfully!')
    } catch (error) {
      console.error('Failed to assign tools:', error)
      alert('Failed to assign tools. Please try again.')
    }
  }

  const handleViewMember = (member: any) => {
    setSelectedMember(member)
    setShowViewModal(true)
  }

  const handleEditAccess = (member: any) => {
    setToolsFormData({
      selectedMember: member.id,
      selectedTools: member.toolsAccess
    })
    setShowAssignModal(true)
  }

  const resetToolsForm = () => {
    setToolsFormData({
      selectedMember: '',
      selectedTools: []
    })
  }

  const toggleTool = (toolName: string) => {
    setToolsFormData(prev => ({
      ...prev,
      selectedTools: prev.selectedTools.includes(toolName)
        ? prev.selectedTools.filter(t => t !== toolName)
        : [...prev.selectedTools, toolName]
    }))
  }

  const getToolsOverview = () => {
    return availableTools.map(tool => {
      const membersWithTool = members.filter(m => m.toolsAccess.includes(tool.name)).length
      return {
        ...tool,
        assignedMembers: membersWithTool,
        percentage: Math.round((membersWithTool / totalMembers) * 100)
      }
    })
  }

  return (
    <div className="ppt-slide p-6">
      <PageHeader 
        title="Tools Access Management"
        subtitle="Manage member access to various tools and platforms"
        actions={[
          {
            label: 'Assign Tools Access',
            onClick: () => setShowAssignModal(true),
            variant: 'default',
            icon: Plus
          },
          {
            label: 'Bulk Management',
            onClick: () => {},
            variant: 'outline',
            icon: Settings
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
            title="Total Members"
            value={totalMembers}
            change={12}
            colorScheme="blue"
            icon={Users}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Members with Access"
            value={membersWithAccess}
            change={8}
            colorScheme="green"
            icon={Shield}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Total Tools Assigned"
            value={totalToolsAssigned}
            change={15}
            colorScheme="purple"
            icon={Settings}
          />
        </motion.div>
        <motion.div variants={{ hidden: { opacity: 0, y: 20 }, visible: { opacity: 1, y: 0 } }}>
          <KPICard
            title="Avg Tools per Member"
            value={avgToolsPerMember}
            change={5}
            colorScheme="green"
            icon={Database}
          />
        </motion.div>
      </motion.div>

      {/* Search */}
      <motion.div 
        className="mb-6"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Search members by name, email, or ID..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
      </motion.div>

      {/* Members Tools Access Table */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="mb-8"
      >
        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle>Member Tools Access</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
                <p className="mt-4 text-gray-600">Loading members...</p>
              </div>
            ) : filteredMembers.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                <Users className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                <p>No members found</p>
              </div>
            ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-200">
                    <th className="text-left py-3 px-4 font-semibold text-brand-text">Member</th>
                    <th className="text-left py-3 px-4 font-semibold text-brand-text">Plan</th>
                    <th className="text-left py-3 px-4 font-semibold text-brand-text">Tools Access</th>
                    <th className="text-left py-3 px-4 font-semibold text-brand-text">Status</th>
                    <th className="text-left py-3 px-4 font-semibold text-brand-text">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredMembers.map((member, index) => (
                    <motion.tr
                      key={member.memberId}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.1 * index }}
                      className="border-b border-gray-100 hover:bg-gray-50"
                    >
                      <td className="py-3 px-4">
                        <div className="flex items-center space-x-3">
                          <Avatar className="h-10 w-10">
                            <AvatarFallback className="bg-brand-primary text-white font-medium">
                              {member.name.split(' ').map((n: string) => n[0]).join('')}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-medium">{member.name}</div>
                            <div className="text-sm text-gray-500">{member.email}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge variant="outline">{member.plan}</Badge>
                      </td>
                      <td className="py-3 px-4">
                        <div className="flex flex-wrap gap-1">
                          {member.toolsAccess.length > 0 ? (
                            member.toolsAccess.slice(0, 3).map((tool) => (
                              <Badge key={tool} variant="secondary" className="text-xs">
                                {tool}
                              </Badge>
                            ))
                          ) : (
                            <span className="text-sm text-gray-500">No access</span>
                          )}
                          {member.toolsAccess.length > 3 && (
                            <Badge variant="outline" className="text-xs">
                              +{member.toolsAccess.length - 3} more
                            </Badge>
                          )}
                        </div>
                      </td>
                      <td className="py-3 px-4">
                        <Badge className={member.status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'}>
                          {member.status}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button size="sm" variant="ghost">
                              <MoreVertical className="w-4 h-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => handleViewMember(member)}>
                              <Eye className="w-4 h-4 mr-2" />
                              View Access
                            </DropdownMenuItem>
                            <DropdownMenuItem onClick={() => handleEditAccess(member)}>
                              <Edit className="w-4 h-4 mr-2" />
                              Edit Access
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </div>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* Tools Overview */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="mb-8"
      >
        <Card className="shadow-xl">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Settings className="w-5 h-5 text-brand-primary" />
              <span>Tools Access Overview</span>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {getToolsOverview().map((tool, index) => (
                <motion.div
                  key={tool.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.1 * index }}
                  className="p-4 border border-gray-200 rounded-lg hover:shadow-lg transition-shadow"
                >
                  <div className="flex items-center space-x-3 mb-3">
                    <div className="text-2xl">{tool.icon}</div>
                    <div>
                      <h3 className="font-semibold text-brand-text">{tool.name}</h3>
                      <p className="text-sm text-gray-500">{tool.description}</p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">{tool.assignedMembers} members</span>
                    <Badge variant="outline">{tool.percentage}%</Badge>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2 mt-2">
                    <motion.div 
                      className="h-2 rounded-full bg-gradient-to-r from-brand-primary to-brand-accent"
                      initial={{ width: 0 }}
                      animate={{ width: `${tool.percentage}%` }}
                      transition={{ delay: 0.6 + index * 0.1, duration: 0.5 }}
                    />
                  </div>
                </motion.div>
              ))}
            </div>
          </CardContent>
        </Card>
      </motion.div>

      {/* Assign Tools Modal */}
      {showAssignModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-brand-text">Assign Tools Access</h2>
              <Button variant="ghost" size="sm" onClick={() => { setShowAssignModal(false); resetToolsForm(); }}>
                <X className="w-4 h-4" />
              </Button>
            </div>
            
            <div className="space-y-6">
              {/* Member Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Select Member *</label>
                <Select value={toolsFormData.selectedMember} onValueChange={(value) => setToolsFormData(prev => ({ ...prev, selectedMember: value }))}>
                  <SelectTrigger>
                    <SelectValue placeholder="Search and select a member..." />
                  </SelectTrigger>
                  <SelectContent>
                    {members.map((member) => (
                      <SelectItem key={member.id} value={member.id}>
                        <div className="flex items-center space-x-3">
                          <Avatar className="h-6 w-6">
                            <AvatarFallback className="bg-brand-primary text-white text-xs">
                              {member.name.split(' ').map((n: string) => n[0]).join('')}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <div className="font-medium">{member.name}</div>
                            <div className="text-xs text-gray-500">{member.email}</div>
                          </div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Current Access Preview */}
              {toolsFormData.selectedMember && (
                <div className="p-4 bg-gray-50 rounded-lg">
                  <h4 className="font-medium text-gray-700 mb-2">Current Access:</h4>
                  <div className="flex flex-wrap gap-2">
                    {members.find(m => m.id === toolsFormData.selectedMember)?.toolsAccess.map((tool: string) => (
                      <Badge key={tool} variant="secondary" className="text-xs">
                        {tool}
                      </Badge>
                    )) || <span className="text-sm text-gray-500">No tools assigned</span>}
                  </div>
                </div>
              )}

              {/* Tools Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Select Tools Access *</label>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-80 overflow-y-auto border border-gray-200 rounded-lg p-4">
                  {availableTools.map((tool) => (
                    <label key={tool.id} className="flex items-start space-x-3 cursor-pointer p-3 rounded-lg hover:bg-gray-50 transition-colors">
                      <input
                        type="checkbox"
                        checked={toolsFormData.selectedTools.includes(tool.name)}
                        onChange={() => toggleTool(tool.name)}
                        className="mt-1 rounded border-gray-300 text-brand-primary focus:ring-brand-primary"
                      />
                      <div className="flex-1">
                        <div className="flex items-center space-x-2 mb-1">
                          <span className="text-lg">{tool.icon}</span>
                          <span className="font-medium text-gray-900">{tool.name}</span>
                        </div>
                        <p className="text-sm text-gray-600">{tool.description}</p>
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            </div>
            
            <div className="flex items-center space-x-3 mt-6">
              <Button 
                onClick={handleAssignTools} 
                disabled={!toolsFormData.selectedMember || toolsFormData.selectedTools.length === 0}
              >
                <Save className="w-4 h-4 mr-2" />
                Assign Tools Access
              </Button>
              <Button variant="outline" onClick={() => { setShowAssignModal(false); resetToolsForm(); }}>
                Cancel
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* View Member Tools Modal */}
      {showViewModal && selectedMember && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-brand-text">Member Tools Access</h2>
              <Button variant="ghost" size="sm" onClick={() => setShowViewModal(false)}>
                <X className="w-4 h-4" />
              </Button>
            </div>
            
            <div className="space-y-6">
              {/* Member Info */}
              <div className="flex items-center space-x-4 p-4 bg-gray-50 rounded-lg">
                <Avatar className="h-16 w-16">
                  <AvatarFallback className="bg-brand-primary text-white text-xl font-bold">
                    {selectedMember.name.split(' ').map((n: string) => n[0]).join('')}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="text-xl font-bold text-brand-text">{selectedMember.name}</h3>
                  <p className="text-gray-600">{selectedMember.email}</p>
                  <div className="flex items-center space-x-2 mt-1">
                    <Badge variant="outline">{selectedMember.plan}</Badge>
                    <Badge className="bg-green-100 text-green-800">{selectedMember.status}</Badge>
                  </div>
                </div>
              </div>

              {/* Tools Access */}
              <div>
                <h4 className="text-lg font-semibold text-brand-text mb-4">Assigned Tools ({selectedMember.toolsAccess.length})</h4>
                {selectedMember.toolsAccess.length > 0 ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {selectedMember.toolsAccess.map((toolName: string) => {
                      const tool = availableTools.find(t => t.name === toolName)
                      return (
                        <div key={toolName} className="flex items-center space-x-3 p-3 border border-gray-200 rounded-lg">
                          <div className="text-2xl">{tool?.icon || '🔧'}</div>
                          <div>
                            <div className="font-medium text-gray-900">{toolName}</div>
                            <div className="text-sm text-gray-500">{tool?.description || 'Tool access'}</div>
                          </div>
                        </div>
                      )
                    })}
                  </div>
                ) : (
                  <div className="text-center py-8 text-gray-500">
                    <Settings className="w-12 h-12 mx-auto mb-4 text-gray-300" />
                    <p>No tools assigned to this member</p>
                  </div>
                )}
              </div>
            </div>
            
            <div className="flex items-center space-x-3 mt-6">
              <Button onClick={() => { setShowViewModal(false); handleEditAccess(selectedMember); }}>
                <Edit className="w-4 h-4 mr-2" />
                Edit Access
              </Button>
              <Button variant="outline" onClick={() => setShowViewModal(false)}>
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}