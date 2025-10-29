import React, { useState, useEffect } from 'react'
import { Plus, Edit, Trash2, Eye, Search } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { supabase } from '@/lib/supabase'
import { ReferralModal } from './ReferralModal'

interface Lead {
  id: string
  lead_id: string
  name: string
  email: string
  phone: string
  source: string
  interest: string
  status: string
  owner: string
  company?: string
  notes?: string
  created_at: string
  updated_at: string
}

interface ReferralsTableProps {
  affiliateId: string
  affiliateName: string
}

export function ReferralsTable({ affiliateId, affiliateName }: ReferralsTableProps) {
  const [leads, setLeads] = useState<Lead[]>([])
  const [filteredLeads, setFilteredLeads] = useState<Lead[]>([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingLead, setEditingLead] = useState<Lead | null>(null)
  const [viewingLead, setViewingLead] = useState<Lead | null>(null)

  useEffect(() => {
    fetchLeads()
  }, [affiliateId])

  useEffect(() => {
    filterLeads()
  }, [searchTerm, leads])

  const fetchLeads = async () => {
    try {
      setLoading(true)
      const { data, error } = await supabase
        .from('leads')
        .select('*')
        .eq('affiliate_id', affiliateId)
        .order('created_at', { ascending: false })

      if (error) throw error
      setLeads(data || [])
    } catch (err) {
      console.error('Error fetching leads:', err)
    } finally {
      setLoading(false)
    }
  }

  const filterLeads = () => {
    if (!searchTerm) {
      setFilteredLeads(leads)
      return
    }

    const filtered = leads.filter(lead =>
      lead.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      lead.phone?.includes(searchTerm) ||
      lead.lead_id.toLowerCase().includes(searchTerm.toLowerCase())
    )
    setFilteredLeads(filtered)
  }

  const handleDelete = async (leadId: string) => {
    if (!confirm('Are you sure you want to delete this referral?')) return

    try {
      const { error } = await supabase
        .from('leads')
        .delete()
        .eq('id', leadId)
        .eq('affiliate_id', affiliateId)

      if (error) throw error

      fetchLeads()
    } catch (err) {
      console.error('Error deleting lead:', err)
      alert('Failed to delete referral')
    }
  }

  const handleEdit = (lead: Lead) => {
    setEditingLead(lead)
    setIsModalOpen(true)
  }

  const handleView = (lead: Lead) => {
    setViewingLead(lead)
  }

  const handleAddNew = () => {
    setEditingLead(null)
    setIsModalOpen(true)
  }

  const handleModalClose = () => {
    setIsModalOpen(false)
    setEditingLead(null)
    fetchLeads()
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      'New': 'bg-blue-100 text-blue-800',
      'Contacted': 'bg-yellow-100 text-yellow-800',
      'Demo Booked': 'bg-green-100 text-green-800',
      'Won': 'bg-emerald-100 text-emerald-800',
      'Lost': 'bg-red-100 text-red-800',
      'No Show': 'bg-gray-100 text-gray-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  const getInterestColor = (interest: string) => {
    const colors: Record<string, string> = {
      'Hot': 'bg-red-100 text-red-800',
      'Warm': 'bg-orange-100 text-orange-800',
      'Cold': 'bg-blue-100 text-blue-800'
    }
    return colors[interest] || 'bg-gray-100 text-gray-800'
  }

  if (viewingLead) {
    return (
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-900">Referral Details</h2>
          <Button variant="outline" onClick={() => setViewingLead(null)}>
            Back to List
          </Button>
        </div>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              <span>{viewingLead.name}</span>
              <div className="flex space-x-2">
                <Badge className={getStatusColor(viewingLead.status)}>
                  {viewingLead.status}
                </Badge>
                <Badge className={getInterestColor(viewingLead.interest)}>
                  {viewingLead.interest}
                </Badge>
              </div>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <div className="text-sm text-gray-600 mb-1">Lead ID</div>
                <div className="font-medium">{viewingLead.lead_id}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Email</div>
                <div className="font-medium">{viewingLead.email}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Phone</div>
                <div className="font-medium">{viewingLead.phone || 'N/A'}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Company</div>
                <div className="font-medium">{viewingLead.company || 'N/A'}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Source</div>
                <div className="font-medium">{viewingLead.source}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Owner</div>
                <div className="font-medium">{viewingLead.owner}</div>
              </div>
              <div className="md:col-span-2">
                <div className="text-sm text-gray-600 mb-1">Notes</div>
                <div className="font-medium">{viewingLead.notes || 'No notes'}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Created</div>
                <div className="font-medium">{new Date(viewingLead.created_at).toLocaleDateString()}</div>
              </div>
              <div>
                <div className="text-sm text-gray-600 mb-1">Last Updated</div>
                <div className="font-medium">{new Date(viewingLead.updated_at).toLocaleDateString()}</div>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
            <CardTitle>My Referrals ({filteredLeads.length})</CardTitle>
            <div className="flex flex-col sm:flex-row space-y-2 sm:space-y-0 sm:space-x-2">
              <div className="relative flex-1 sm:w-64">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <Input
                  placeholder="Search referrals..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10"
                />
              </div>
              <Button
                onClick={handleAddNew}
                className="bg-gradient-to-r from-blue-600 to-green-600 hover:from-blue-700 hover:to-green-700"
              >
                <Plus className="w-4 h-4 mr-2" />
                Add Referral
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-12 text-gray-500">Loading referrals...</div>
          ) : filteredLeads.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              {searchTerm ? 'No referrals found matching your search' : 'No referrals yet. Add your first referral!'}
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Lead ID</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Name</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Email</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Phone</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Status</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Interest</th>
                    <th className="text-left py-3 px-4 font-medium text-gray-600">Created</th>
                    <th className="text-right py-3 px-4 font-medium text-gray-600">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredLeads.map((lead) => (
                    <tr key={lead.id} className="border-b hover:bg-gray-50">
                      <td className="py-3 px-4 font-medium">{lead.lead_id}</td>
                      <td className="py-3 px-4">{lead.name}</td>
                      <td className="py-3 px-4">{lead.email}</td>
                      <td className="py-3 px-4">{lead.phone || 'N/A'}</td>
                      <td className="py-3 px-4">
                        <Badge className={getStatusColor(lead.status)}>
                          {lead.status}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">
                        <Badge className={getInterestColor(lead.interest)}>
                          {lead.interest}
                        </Badge>
                      </td>
                      <td className="py-3 px-4">{new Date(lead.created_at).toLocaleDateString()}</td>
                      <td className="py-3 px-4">
                        <div className="flex justify-end space-x-2">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleView(lead)}
                          >
                            <Eye className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleEdit(lead)}
                          >
                            <Edit className="w-4 h-4" />
                          </Button>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleDelete(lead.id)}
                            className="text-red-600 hover:text-red-700"
                          >
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {isModalOpen && (
        <ReferralModal
          isOpen={isModalOpen}
          onClose={handleModalClose}
          affiliateId={affiliateId}
          affiliateName={affiliateName}
          lead={editingLead}
        />
      )}
    </div>
  )
}
