import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Play, Star, Users, Clock, Award, CheckCircle, ArrowRight, Zap, Target, TrendingUp, Shield, BookOpen, Video, Download, MessageCircle, Phone, Mail, Globe, Smartphone, Bot, Sparkles, Rocket, Crown, Gift, Timer, AlertCircle, ChevronDown, ChevronRight, User, Calendar, DollarSign, Layers, Share2, LineChart as ChartLine } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

const CircuitBackground = () => {
  return (
    <div className="absolute inset-0 overflow-hidden pointer-events-none">
      {/* Circuit Lines */}
      <svg className="absolute inset-0 w-full h-full opacity-30" viewBox="0 0 1200 800">
        <defs>
          <linearGradient id="circuitGlow" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stopColor="#00F0FF" stopOpacity="0" />
            <stop offset="50%" stopColor="#00F0FF" stopOpacity="0.6" />
            <stop offset="100%" stopColor="#00F0FF" stopOpacity="0" />
          </linearGradient>
        </defs>
        
        {/* Horizontal Lines */}
        <line x1="0" y1="100" x2="400" y2="100" stroke="url(#circuitGlow)" strokeWidth="2" />
        <line x1="600" y1="200" x2="1200" y2="200" stroke="url(#circuitGlow)" strokeWidth="2" />
        <line x1="0" y1="400" x2="500" y2="400" stroke="url(#circuitGlow)" strokeWidth="2" />
        <line x1="700" y1="600" x2="1200" y2="600" stroke="url(#circuitGlow)" strokeWidth="2" />
        
        {/* Vertical Lines */}
        <line x1="200" y1="0" x2="200" y2="300" stroke="url(#circuitGlow)" strokeWidth="2" />
        <line x1="800" y1="100" x2="800" y2="500" stroke="url(#circuitGlow)" strokeWidth="2" />
        <line x1="1000" y1="200" x2="1000" y2="800" stroke="url(#circuitGlow)" strokeWidth="2" />
        
        {/* Circuit Nodes */}
        <circle cx="200" cy="100" r="4" fill="#00F0FF" className="animate-pulse" />
        <circle cx="400" cy="100" r="4" fill="#FFD600" className="animate-pulse" />
        <circle cx="600" cy="200" r="4" fill="#B800FF" className="animate-pulse" />
        <circle cx="800" cy="200" r="4" fill="#00F0FF" className="animate-pulse" />
        <circle cx="500" cy="400" r="4" fill="#FFD600" className="animate-pulse" />
        <circle cx="800" cy="500" r="4" fill="#B800FF" className="animate-pulse" />
        <circle cx="1000" cy="600" r="4" fill="#00F0FF" className="animate-pulse" />
      </svg>
      
      {/* Floating Particles */}
      <div className="absolute inset-0">
        {Array.from({ length: 20 }).map((_, i) => (
          <div
            key={i}
            className="absolute w-1 h-1 bg-cyan-400 rounded-full animate-pulse"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 3}s`,
              animationDuration: `${2 + Math.random() * 2}s`
            }}
          />
        ))}
      </div>
    </div>
  )
}

const NeonCard = ({ children, className = "", glowColor = "#00F0FF" }: { 
  children: React.ReactNode, 
  className?: string,
  glowColor?: string 
}) => {
  return (
    <div 
      className={`relative bg-gradient-to-b from-[#0A0F1E]/70 to-[#0A0F1E]/35 backdrop-blur-sm rounded-2xl border p-6 transition-all duration-300 hover:scale-105 ${className}`}
      style={{
        borderColor: `${glowColor}60`,
        boxShadow: `0 10px 30px rgba(0,0,0,.45), 0 0 18px ${glowColor}40`
      }}
    >
      {children}
    </div>
  )
}

const GlowButton = ({ 
  children, 
  variant = "primary", 
  className = "",
  onClick,
  href
}: { 
  children: React.ReactNode,
  variant?: "primary" | "secondary",
  className?: string,
  onClick?: () => void,
  href?: string
}) => {
  const isPrimary = variant === "primary"
  const baseClasses = "inline-flex items-center gap-2 px-6 py-3 rounded-lg font-semibold transition-all duration-300 hover:-translate-y-1"
  
  const style = isPrimary ? {
    background: "#FFD600",
    color: "#000000",
    boxShadow: "0 0 16px #FFD600, 0 0 36px rgba(255,214,0,.35)"
  } : {
    border: "2px solid #00F0FF",
    color: "#00F0FF",
    background: "transparent",
    boxShadow: "0 0 16px rgba(0,240,255,.35) inset"
  }

  const Component = href ? 'a' : 'button'
  
  return (
    <Component
      className={`${baseClasses} ${className}`}
      style={style}
      onClick={onClick}
      href={href}
      target={href ? "_blank" : undefined}
      onMouseEnter={(e) => {
        if (isPrimary) {
          e.currentTarget.style.boxShadow = "0 0 20px #FFD600, 0 0 48px rgba(255,214,0,.6)"
        } else {
          e.currentTarget.style.boxShadow = "0 0 20px rgba(0,240,255,.5) inset"
        }
      }}
      onMouseLeave={(e) => {
        if (isPrimary) {
          e.currentTarget.style.boxShadow = "0 0 16px #FFD600, 0 0 36px rgba(255,214,0,.35)"
        } else {
          e.currentTarget.style.boxShadow = "0 0 16px rgba(0,240,255,.35) inset"
        }
      }}
    >
      {children}
    </Component>
  )
}

export function AIAutomationMasteryLanding() {
  const [email, setEmail] = useState('')
  const [timeLeft, setTimeLeft] = useState({ hours: 23, minutes: 45, seconds: 30 })

  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft(prev => {
        if (prev.seconds > 0) {
          return { ...prev, seconds: prev.seconds - 1 }
        } else if (prev.minutes > 0) {
          return { ...prev, minutes: prev.minutes - 1, seconds: 59 }
        } else if (prev.hours > 0) {
          return { hours: prev.hours - 1, minutes: 59, seconds: 59 }
        }
        return prev
      })
    }, 1000)

    return () => clearInterval(timer)
  }, [])

  const features = [
    {
      title: "AI Agents",
      description: "Deploy result-driven agents for lead capture, triage, and follow-up.",
      icon: Bot,
      accent: "#00F0FF"
    },
    {
      title: "WhatsApp Business Automation",
      description: "Utility templates, interactive menus, voice bots & broadcast funnels.",
      icon: MessageCircle,
      accent: "#00F0FF"
    },
    {
      title: "Sales Automation",
      description: "Lead scoring, pipelines, auto-estimates/invoices, and smart nudges.",
      icon: ChartLine,
      accent: "#FFD600"
    },
    {
      title: "Social Media Automation",
      description: "AI content + scheduling + posting with consistent brand voice.",
      icon: Share2,
      accent: "#B800FF"
    },
    {
      title: "Team & Task Automation",
      description: "Attendance, tasks, reminders, and review loops — fully automated.",
      icon: CheckCircle,
      accent: "#00F0FF"
    },
    {
      title: "All-in-One SAAS",
      description: "Central dashboard with CRM, forms, payments, and analytics.",
      icon: Layers,
      accent: "#4A00FF"
    }
  ]

  const bonuses = [
    { label: "10 AI Employees", value: "₹1,80,000", accent: "#00F0FF" },
    { label: "50+ n8n AI Workflows", value: "₹75,000", accent: "#B800FF" },
    { label: "150+ Automation Workflows", value: "₹1,50,000", accent: "#4A00FF" },
    { label: "20+ WhatsApp Voice AI Bots", value: "₹2,25,000", accent: "#00F0FF" },
    { label: "3 Months Access to GHL All-in-One SaaS", value: "₹25,500", accent: "#FFD600" },
    { label: "Exclusive Automation Saathi Membership", value: "₹1,20,000", accent: "#FFD600" }
  ]

  const totalBonusValue = bonuses.reduce((sum, bonus) => {
    return sum + parseInt(bonus.value.replace(/[₹,]/g, ''))
  }, 0)

  return (
    <div className="min-h-screen" style={{ backgroundColor: "#0A0F1E" }}>
      {/* Global Background */}
      <div 
        className="fixed inset-0 pointer-events-none"
        style={{
          background: `
            radial-gradient(1200px 600px at 20% -10%, rgba(0,240,255,.15), transparent 60%), 
            radial-gradient(1000px 500px at 100% 0%, rgba(184,0,255,.15), transparent 60%)
          `
        }}
      />
      
      <CircuitBackground />

      {/* Hero Section */}
      <section className="relative py-20 md:py-28 overflow-hidden">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <div className="text-center">
            {/* Eyebrow */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="tracking-[0.25em] text-sm md:text-base"
              style={{ color: "#00F0FF" }}
            >
              LIVE MASTERCLASS
            </motion.div>

            {/* Main Heading */}
            <motion.h1
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 0.2 }}
              className="mt-3 text-4xl md:text-6xl font-extrabold text-white"
              style={{ 
                textShadow: "0 0 16px #00F0FF",
                fontFamily: "Poppins, Inter, ui-sans-serif, system-ui"
              }}
            >
              Build Lead Gen AI in Under 30 Minutes ⚡
            </motion.h1>

            {/* Subheading */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="mt-5 max-w-2xl mx-auto text-lg md:text-xl text-white/80"
            >
              Launch AI Agents, automate WhatsApp, and plug into your sales engine — all with a neon-fast workflow.
            </motion.p>

            {/* CTAs */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.6 }}
              className="mt-8 flex flex-col sm:flex-row gap-4 justify-center items-center"
            >
              <GlowButton variant="primary">
                <Rocket className="w-5 h-5" />
                Reserve Your Seat
              </GlowButton>
              <GlowButton variant="secondary">
                <Play className="w-5 h-5" />
                Watch 90-sec Demo
              </GlowButton>
            </motion.div>

            {/* Countdown Timer */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.8 }}
              className="mt-8 flex items-center justify-center space-x-2"
              style={{ color: "#FFD600" }}
            >
              <Timer className="w-4 h-4" />
              <span className="text-sm font-medium">
                Offer expires in: {timeLeft.hours}h {timeLeft.minutes}m {timeLeft.seconds}s
              </span>
            </motion.div>

            {/* Hero Visual */}
            <motion.div
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8, delay: 1 }}
              className="mt-12 md:mt-16 w-full md:w-[72%] mx-auto"
            >
              <NeonCard 
                className="p-8"
                glowColor="#00F0FF"
              >
                <div className="text-center">
                  <div className="text-4xl font-bold mb-2" style={{ color: "#00F0FF" }}>AI</div>
                  <div className="text-lg text-white/80 mb-6">Neural Workflows</div>
                  
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    {[
                      { icon: Users, accent: "#B800FF", label: "Lead Gen" },
                      { icon: Zap, accent: "#FFD600", label: "Automation" },
                      { icon: MessageCircle, accent: "#00F0FF", label: "WhatsApp" },
                      { icon: ChartLine, accent: "#4A00FF", label: "Analytics" }
                    ].map((item, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, scale: 0.8 }}
                        animate={{ opacity: 1, scale: 1 }}
                        transition={{ duration: 0.5, delay: 1.2 + index * 0.1 }}
                        className="p-4 rounded-xl bg-white/5 border border-white/20"
                      >
                        <item.icon 
                          className="w-8 h-8 mx-auto mb-2" 
                          style={{ 
                            color: item.accent,
                            filter: `drop-shadow(0 0 8px ${item.accent})`
                          }} 
                        />
                        <div className="text-xs text-white/70">{item.label}</div>
                      </motion.div>
                    ))}
                  </div>
                </div>
              </NeonCard>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-16 md:py-24">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white">
              What You'll Build Inside
            </h2>
            <p className="mt-3 text-white/70">
              Each module is plug-and-play with neon-glow UI and production-ready flows.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
              >
                <NeonCard glowColor={feature.accent}>
                  <div className="text-center">
                    <div 
                      className="w-16 h-16 mx-auto mb-4 rounded-2xl flex items-center justify-center"
                      style={{
                        background: `linear-gradient(135deg, ${feature.accent}20, ${feature.accent}10)`,
                        border: `1px solid ${feature.accent}40`
                      }}
                    >
                      <feature.icon 
                        className="w-8 h-8" 
                        style={{ 
                          color: feature.accent,
                          filter: `drop-shadow(0 0 8px ${feature.accent})`
                        }} 
                      />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-3">{feature.title}</h3>
                    <p className="text-white/70 leading-relaxed">{feature.description}</p>
                  </div>
                </NeonCard>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Bonuses Section */}
      <section className="py-16 md:py-24 bg-gradient-to-r from-green-900/20 to-blue-900/20">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white">
              Exclusive Bonuses
            </h2>
            <p className="mt-3 text-white/70">
              Enroll now and unlock high-value assets to accelerate your automation journey.
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
            {bonuses.map((bonus, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
              >
                <NeonCard glowColor={bonus.accent}>
                  <div className="flex items-center justify-between mb-4">
                    <div 
                      className="w-12 h-12 rounded-xl flex items-center justify-center"
                      style={{
                        background: `linear-gradient(135deg, ${bonus.accent}30, ${bonus.accent}10)`,
                        border: `1px solid ${bonus.accent}50`
                      }}
                    >
                      <Gift 
                        className="w-6 h-6" 
                        style={{ 
                          color: bonus.accent,
                          filter: `drop-shadow(0 0 6px ${bonus.accent})`
                        }} 
                      />
                    </div>
                    <Badge 
                      className="font-bold"
                      style={{
                        background: `${bonus.accent}20`,
                        color: bonus.accent,
                        border: `1px solid ${bonus.accent}30`
                      }}
                    >
                      Worth {bonus.value}
                    </Badge>
                  </div>
                  
                  <h3 className="text-lg font-semibold text-white mb-3">{bonus.label}</h3>
                  <p className="text-white/70 text-sm leading-relaxed">
                    Premium automation assets and tools to accelerate your business growth.
                  </p>
                </NeonCard>
              </motion.div>
            ))}
          </div>

          {/* Total Value */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.8 }}
            className="text-center"
          >
            <div 
              className="inline-block bg-gradient-to-r from-yellow-500/20 to-orange-500/20 border border-yellow-500/30 rounded-2xl p-8"
            >
              <h3 className="text-2xl md:text-3xl font-extrabold mb-2">
                <span className="text-white">Total Bonus Value: </span>
                <span 
                  style={{ 
                    color: "#00F0FF",
                    textShadow: "0 0 14px rgba(0,240,255,.7)"
                  }}
                >
                  ₹{totalBonusValue.toLocaleString('en-IN')}
                </span>
              </h3>
              <p className="text-yellow-400 font-semibold">Yours FREE with course enrollment!</p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Social Proof */}
      <section className="py-16 md:py-24">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Join 500+ Entrepreneurs Who Transformed Their Business
            </h2>
            <p className="text-white/70 text-lg">
              See real results from real students who implemented our AI automation strategies
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              {
                name: "Rajesh Kumar",
                role: "Digital Marketing Agency Owner",
                image: "RK",
                rating: 5,
                text: "This course transformed my business! I automated 80% of my client onboarding process and increased revenue by 300%.",
                results: "300% Revenue Increase"
              },
              {
                name: "Priya Sharma", 
                role: "E-commerce Business Owner",
                image: "PS",
                rating: 5,
                text: "I went from manually handling customer queries to having a fully automated system. Customer satisfaction increased to 95%.",
                results: "95% Customer Satisfaction"
              },
              {
                name: "Amit Singh",
                role: "Consultant & Coach",
                image: "AS", 
                rating: 5,
                text: "The AI automation strategies helped me scale from 1-on-1 coaching to serving 500+ clients simultaneously. 10x income growth!",
                results: "10x Income Growth"
              }
            ].map((testimonial, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.2 }}
              >
                <NeonCard glowColor="#00F0FF">
                  <div className="flex items-center mb-4">
                    <Avatar className="w-12 h-12 mr-4">
                      <AvatarFallback 
                        className="text-white font-bold"
                        style={{ background: "linear-gradient(135deg, #00F0FF, #B800FF)" }}
                      >
                        {testimonial.image}
                      </AvatarFallback>
                    </Avatar>
                    <div>
                      <h4 className="font-semibold text-white">{testimonial.name}</h4>
                      <p className="text-sm text-white/70">{testimonial.role}</p>
                    </div>
                  </div>
                  
                  <div className="flex mb-3">
                    {Array.from({ length: 5 }, (_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${i < testimonial.rating ? 'text-yellow-400 fill-current' : 'text-gray-600'}`}
                      />
                    ))}
                  </div>
                  
                  <p className="text-white/80 mb-4 leading-relaxed">"{testimonial.text}"</p>
                  
                  <div 
                    className="rounded-lg p-3 border"
                    style={{
                      background: "linear-gradient(135deg, rgba(0,240,255,.1), rgba(0,240,255,.05))",
                      borderColor: "#00F0FF40"
                    }}
                  >
                    <p className="font-semibold text-sm" style={{ color: "#00F0FF" }}>
                      {testimonial.results}
                    </p>
                  </div>
                </NeonCard>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-14 md:py-20">
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center"
          >
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Join the AI Automation Masterclass
            </h2>
            <p className="text-white/70 mb-8">
              Seats are limited. Secure your spot and get instant access to the bonus stack.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <GlowButton variant="primary">
                <Crown className="w-5 h-5" />
                Enroll Now
              </GlowButton>
              <GlowButton variant="secondary" href="https://wa.me/919876543210">
                <MessageCircle className="w-5 h-5" />
                Talk to an Expert on WhatsApp
              </GlowButton>
            </div>

            {/* Guarantee */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.4 }}
              className="mt-12"
            >
              <NeonCard glowColor="#FFD600" className="max-w-md mx-auto">
                <div className="text-center">
                  <Shield className="w-12 h-12 mx-auto mb-4" style={{ color: "#FFD600" }} />
                  <h3 className="text-lg font-bold text-white mb-2">30-Day Money-Back Guarantee</h3>
                  <p className="text-white/70 text-sm">
                    Risk-free investment. If you don't see results, get 100% refund.
                  </p>
                </div>
              </NeonCard>
            </motion.div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer 
        className="py-12 border-t"
        style={{ 
          borderColor: "rgba(0,240,255,.18)",
          background: "linear-gradient(180deg, rgba(10,15,30,.9), rgba(10,15,30,.7))"
        }}
      >
        <div className="max-w-7xl mx-auto px-6 md:px-10">
          <div className="flex flex-col md:flex-row justify-between items-center">
            <div className="text-white/90 mb-4 md:mb-0">
              © Automation Saathi
            </div>
            <div className="flex items-center space-x-6">
              <a href="#" className="text-white/70 hover:text-white transition-colors text-sm">
                Privacy Policy
              </a>
              <a href="#" className="text-white/70 hover:text-white transition-colors text-sm">
                Terms
              </a>
              <div className="text-white/90 text-sm">
                Made with ♥ and AI
              </div>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}