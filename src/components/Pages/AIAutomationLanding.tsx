import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Play, Star, Users, Clock, Award, CheckCircle, ArrowRight, 
  Zap, Target, TrendingUp, Shield, BookOpen, Video, 
  Download, MessageCircle, Phone, Mail, Globe, Smartphone,
  Bot, Sparkles, Rocket, Crown, Gift, Timer, AlertCircle,
  ChevronDown, ChevronRight, User, Calendar, DollarSign
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Input } from '@/components/ui/input'
import { Avatar, AvatarFallback } from '@/components/ui/avatar'

const testimonials = [
  {
    name: "Rajesh Kumar",
    role: "Digital Marketing Agency Owner",
    image: "RK",
    rating: 5,
    text: "This course transformed my business! I automated 80% of my client onboarding process and increased revenue by 300%. The WhatsApp automation alone saves me 20 hours per week.",
    results: "300% Revenue Increase"
  },
  {
    name: "Priya Sharma", 
    role: "E-commerce Business Owner",
    image: "PS",
    rating: 5,
    text: "I went from manually handling customer queries to having a fully automated system. My customer satisfaction increased to 95% while reducing response time from hours to seconds.",
    results: "95% Customer Satisfaction"
  },
  {
    name: "Amit Singh",
    role: "Consultant & Coach",
    image: "AS", 
    rating: 5,
    text: "The AI automation strategies taught here helped me scale from 1-on-1 coaching to serving 500+ clients simultaneously. My income increased 10x in just 6 months!",
    results: "10x Income Growth"
  }
]

const courseModules = [
  {
    title: "AI Fundamentals & Strategy",
    duration: "2 hours",
    lessons: 8,
    description: "Master the foundations of AI automation and create your winning strategy",
    topics: ["AI Automation Mindset", "Business Process Mapping", "ROI Calculation", "Tool Selection Framework"]
  },
  {
    title: "WhatsApp Business Automation",
    duration: "3 hours", 
    lessons: 12,
    description: "Build powerful WhatsApp bots that handle customer service, sales, and support",
    topics: ["WhatsApp API Setup", "Chatbot Development", "Lead Qualification", "Payment Integration"]
  },
  {
    title: "Email Marketing Automation",
    duration: "2.5 hours",
    lessons: 10,
    description: "Create email sequences that convert leads into paying customers automatically",
    topics: ["Email Sequences", "Behavioral Triggers", "Personalization", "A/B Testing"]
  },
  {
    title: "CRM & Sales Automation",
    duration: "3 hours",
    lessons: 14,
    description: "Automate your entire sales process from lead capture to deal closure",
    topics: ["CRM Integration", "Lead Scoring", "Pipeline Automation", "Follow-up Sequences"]
  },
  {
    title: "Social Media Automation",
    duration: "2 hours",
    lessons: 9,
    description: "Scale your social media presence with AI-powered content and engagement",
    topics: ["Content Scheduling", "Engagement Automation", "Analytics Tracking", "Growth Hacking"]
  },
  {
    title: "Advanced AI Workflows",
    duration: "4 hours",
    lessons: 16,
    description: "Build complex multi-step automations that run your business on autopilot",
    topics: ["Workflow Design", "API Integrations", "Custom Automations", "Scaling Strategies"]
  }
]

const bonuses = [
  {
    title: "WhatsApp Automation Templates",
    value: "₹15,000",
    description: "50+ Ready-to-use WhatsApp automation templates for different industries",
    icon: MessageCircle
  },
  {
    title: "AI Tools Masterclass",
    value: "₹10,000", 
    description: "Complete guide to 25+ AI tools that will 10x your productivity",
    icon: Bot
  },
  {
    title: "1-on-1 Strategy Session",
    value: "₹25,000",
    description: "Personal 60-minute session to create your custom automation strategy",
    icon: Target
  },
  {
    title: "Private Community Access",
    value: "₹8,000",
    description: "Lifetime access to our exclusive community of automation experts",
    icon: Users
  },
  {
    title: "Monthly Live Q&A Sessions",
    value: "₹12,000",
    description: "12 months of live sessions with industry experts and course updates",
    icon: Video
  }
]

const faqs = [
  {
    question: "Do I need any technical background to take this course?",
    answer: "Not at all! This course is designed for complete beginners. We start from the basics and guide you step-by-step through every process. No coding or technical skills required."
  },
  {
    question: "How long do I have access to the course?",
    answer: "You get lifetime access to all course materials, including future updates. Once you enroll, the content is yours forever."
  },
  {
    question: "What if I don't see results?",
    answer: "We're so confident in our course that we offer a 30-day money-back guarantee. If you don't see measurable improvements in your business automation, we'll refund every penny."
  },
  {
    question: "Can I implement these automations in any business?",
    answer: "Yes! The strategies taught work for any business - whether you're a consultant, agency owner, e-commerce store, or service provider. The principles are universal."
  },
  {
    question: "How much time do I need to dedicate to learning?",
    answer: "The course is designed to be completed in 2-3 weeks with just 1-2 hours of study per day. However, you can go at your own pace since you have lifetime access."
  },
  {
    question: "Do you provide support if I get stuck?",
    answer: "Absolutely! You get access to our private community where you can ask questions, plus monthly live Q&A sessions where we address common challenges."
  }
]

export function AIAutomationLanding() {
  const [selectedModule, setSelectedModule] = useState(0)
  const [openFaq, setOpenFaq] = useState<number | null>(null)
  const [email, setEmail] = useState('')
  const [showPricing, setShowPricing] = useState(false)

  const scrollToSection = (sectionId: string) => {
    document.getElementById(sectionId)?.scrollIntoView({ behavior: 'smooth' })
  }

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`w-4 h-4 ${i < rating ? 'text-yellow-400 fill-current' : 'text-gray-300'}`}
      />
    ))
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        {/* Background Effects */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-600/20 to-purple-600/20" />
          <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl" />
          <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-500/10 rounded-full blur-3xl" />
        </div>

        <div className="relative container mx-auto px-6 py-20">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Left Column - Content */}
            <motion.div
              initial={{ opacity: 0, x: -50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8 }}
              className="text-white"
            >
              {/* Badge */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="inline-flex items-center space-x-2 bg-gradient-to-r from-yellow-400/20 to-orange-400/20 border border-yellow-400/30 rounded-full px-4 py-2 mb-6"
              >
                <Crown className="w-4 h-4 text-yellow-400" />
                <span className="text-sm font-medium text-yellow-400">#1 AI Automation Course in India</span>
              </motion.div>

              {/* Headline */}
              <motion.h1
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 }}
                className="text-5xl lg:text-6xl font-bold mb-6 leading-tight"
              >
                Master <span className="bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">AI Automation</span> & Scale Your Business to <span className="text-green-400">₹1 Crore+</span>
              </motion.h1>

              {/* Subheadline */}
              <motion.p
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.4 }}
                className="text-xl text-gray-300 mb-8 leading-relaxed"
              >
                Learn the exact AI automation strategies that helped 500+ entrepreneurs automate 80% of their business operations and increase revenue by 300% in just 90 days.
              </motion.p>

              {/* Social Proof */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
                className="flex items-center space-x-6 mb-8"
              >
                <div className="flex items-center space-x-2">
                  <div className="flex -space-x-2">
                    {[1,2,3,4,5].map(i => (
                      <Avatar key={i} className="w-8 h-8 border-2 border-white">
                        <AvatarFallback className="bg-gradient-to-r from-blue-500 to-purple-500 text-white text-xs">
                          {String.fromCharCode(65 + i)}
                        </AvatarFallback>
                      </Avatar>
                    ))}
                  </div>
                  <span className="text-sm text-gray-300">500+ Students</span>
                </div>
                <div className="flex items-center space-x-1">
                  {renderStars(5)}
                  <span className="text-sm text-gray-300 ml-2">4.9/5 Rating</span>
                </div>
              </motion.div>

              {/* CTA Buttons */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.6 }}
                className="flex flex-col sm:flex-row gap-4"
              >
                <Button
                  size="lg"
                  className="bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white px-8 py-4 text-lg font-semibold shadow-2xl hover:shadow-green-500/25 transition-all duration-300"
                  onClick={() => setShowPricing(true)}
                >
                  <Rocket className="w-5 h-5 mr-2" />
                  Enroll Now - ₹15,000 Only
                </Button>
                <Button
                  size="lg"
                  variant="outline"
                  className="border-2 border-white/30 text-white hover:bg-white/10 px-8 py-4 text-lg font-semibold"
                  onClick={() => scrollToSection('preview')}
                >
                  <Play className="w-5 h-5 mr-2" />
                  Watch Preview
                </Button>
              </motion.div>

              {/* Urgency */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.7 }}
                className="mt-6 flex items-center space-x-2 text-yellow-400"
              >
                <Timer className="w-4 h-4" />
                <span className="text-sm font-medium">Limited Time: 70% OFF (Regular Price: ₹50,000)</span>
              </motion.div>
            </motion.div>

            {/* Right Column - Video/Image */}
            <motion.div
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.8, delay: 0.3 }}
              className="relative"
            >
              <div className="relative bg-gradient-to-br from-blue-600/20 to-purple-600/20 rounded-2xl p-8 backdrop-blur-sm border border-white/10">
                <div className="aspect-video bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl flex items-center justify-center relative overflow-hidden">
                  <div className="absolute inset-0 bg-gradient-to-br from-blue-500/20 to-purple-500/20" />
                  <Button
                    size="lg"
                    className="bg-white/20 hover:bg-white/30 text-white backdrop-blur-sm border border-white/30 rounded-full w-20 h-20"
                  >
                    <Play className="w-8 h-8 ml-1" />
                  </Button>
                  <div className="absolute bottom-4 left-4 right-4">
                    <div className="bg-black/50 backdrop-blur-sm rounded-lg p-3">
                      <p className="text-white text-sm font-medium">Course Preview: AI Automation Fundamentals</p>
                      <p className="text-gray-300 text-xs">Duration: 15:30</p>
                    </div>
                  </div>
                </div>
                
                {/* Stats Overlay */}
                <div className="absolute -bottom-4 -right-4 bg-gradient-to-r from-green-500 to-green-600 rounded-xl p-4 shadow-2xl">
                  <div className="text-center">
                    <div className="text-2xl font-bold text-white">300%</div>
                    <div className="text-xs text-green-100">Avg Revenue Increase</div>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Social Proof Section */}
      <section className="py-16 bg-white/5 backdrop-blur-sm">
        <div className="container mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-12"
          >
            <h2 className="text-3xl font-bold text-white mb-4">
              Join 500+ Entrepreneurs Who Transformed Their Business
            </h2>
            <p className="text-gray-300 text-lg">
              See real results from real students who implemented our AI automation strategies
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.2 }}
                className="bg-white/10 backdrop-blur-sm rounded-2xl p-6 border border-white/20 hover:bg-white/15 transition-all duration-300"
              >
                <div className="flex items-center mb-4">
                  <Avatar className="w-12 h-12 mr-4">
                    <AvatarFallback className="bg-gradient-to-r from-blue-500 to-purple-500 text-white font-bold">
                      {testimonial.image}
                    </AvatarFallback>
                  </Avatar>
                  <div>
                    <h4 className="font-semibold text-white">{testimonial.name}</h4>
                    <p className="text-sm text-gray-300">{testimonial.role}</p>
                  </div>
                </div>
                
                <div className="flex mb-3">
                  {renderStars(testimonial.rating)}
                </div>
                
                <p className="text-gray-300 mb-4 leading-relaxed">"{testimonial.text}"</p>
                
                <div className="bg-gradient-to-r from-green-500/20 to-green-600/20 border border-green-500/30 rounded-lg p-3">
                  <p className="text-green-400 font-semibold text-sm">{testimonial.results}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Course Curriculum */}
      <section id="curriculum" className="py-20">
        <div className="container mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">
              Complete AI Automation Curriculum
            </h2>
            <p className="text-xl text-gray-300 mb-8">
              16+ hours of premium content • 69 lessons • Lifetime access
            </p>
            
            <div className="flex justify-center space-x-8 text-center">
              <div className="bg-white/10 rounded-xl p-4 backdrop-blur-sm">
                <div className="text-2xl font-bold text-blue-400">16+</div>
                <div className="text-sm text-gray-300">Hours of Content</div>
              </div>
              <div className="bg-white/10 rounded-xl p-4 backdrop-blur-sm">
                <div className="text-2xl font-bold text-purple-400">69</div>
                <div className="text-sm text-gray-300">Video Lessons</div>
              </div>
              <div className="bg-white/10 rounded-xl p-4 backdrop-blur-sm">
                <div className="text-2xl font-bold text-green-400">6</div>
                <div className="text-sm text-gray-300">Core Modules</div>
              </div>
            </div>
          </motion.div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            {/* Module List */}
            <div className="space-y-4">
              {courseModules.map((module, index) => (
                <motion.div
                  key={index}
                  initial={{ opacity: 0, x: -30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                  className={`cursor-pointer transition-all duration-300 ${
                    selectedModule === index
                      ? 'bg-gradient-to-r from-blue-600/30 to-purple-600/30 border-blue-500/50'
                      : 'bg-white/10 hover:bg-white/15 border-white/20'
                  } backdrop-blur-sm rounded-xl p-6 border`}
                  onClick={() => setSelectedModule(index)}
                >
                  <div className="flex items-center justify-between mb-3">
                    <h3 className="text-lg font-semibold text-white">{module.title}</h3>
                    <ChevronRight className={`w-5 h-5 text-gray-400 transition-transform ${
                      selectedModule === index ? 'rotate-90' : ''
                    }`} />
                  </div>
                  
                  <div className="flex items-center space-x-4 text-sm text-gray-300 mb-3">
                    <div className="flex items-center space-x-1">
                      <Clock className="w-4 h-4" />
                      <span>{module.duration}</span>
                    </div>
                    <div className="flex items-center space-x-1">
                      <BookOpen className="w-4 h-4" />
                      <span>{module.lessons} lessons</span>
                    </div>
                  </div>
                  
                  <p className="text-gray-300">{module.description}</p>
                </motion.div>
              ))}
            </div>

            {/* Module Details */}
            <motion.div
              key={selectedModule}
              initial={{ opacity: 0, x: 30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.6 }}
              className="bg-gradient-to-br from-white/10 to-white/5 backdrop-blur-sm rounded-2xl p-8 border border-white/20 sticky top-8"
            >
              <h3 className="text-2xl font-bold text-white mb-4">
                {courseModules[selectedModule].title}
              </h3>
              
              <p className="text-gray-300 mb-6 leading-relaxed">
                {courseModules[selectedModule].description}
              </p>
              
              <h4 className="text-lg font-semibold text-white mb-4">What You'll Learn:</h4>
              <ul className="space-y-3">
                {courseModules[selectedModule].topics.map((topic, index) => (
                  <li key={index} className="flex items-center space-x-3">
                    <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                    <span className="text-gray-300">{topic}</span>
                  </li>
                ))}
              </ul>
              
              <div className="mt-8 p-4 bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-xl border border-blue-500/30">
                <div className="flex items-center space-x-2 mb-2">
                  <Zap className="w-5 h-5 text-yellow-400" />
                  <span className="font-semibold text-white">Practical Implementation</span>
                </div>
                <p className="text-sm text-gray-300">
                  Each module includes hands-on exercises and real-world case studies to ensure you can implement what you learn immediately.
                </p>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Bonuses Section */}
      <section className="py-20 bg-gradient-to-r from-green-900/20 to-blue-900/20">
        <div className="container mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">
              Exclusive Bonuses Worth ₹70,000
            </h2>
            <p className="text-xl text-gray-300">
              Get these premium bonuses absolutely FREE when you enroll today
            </p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {bonuses.map((bonus, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="bg-gradient-to-br from-white/10 to-white/5 backdrop-blur-sm rounded-2xl p-6 border border-white/20 hover:border-green-500/50 transition-all duration-300 group"
              >
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-green-600 rounded-xl flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
                    <bonus.icon className="w-6 h-6 text-white" />
                  </div>
                  <Badge className="bg-green-500/20 text-green-400 border-green-500/30">
                    Worth {bonus.value}
                  </Badge>
                </div>
                
                <h3 className="text-xl font-semibold text-white mb-3">{bonus.title}</h3>
                <p className="text-gray-300 leading-relaxed">{bonus.description}</p>
              </motion.div>
            ))}
          </div>

          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.8 }}
            className="text-center mt-12"
          >
            <div className="bg-gradient-to-r from-yellow-500/20 to-orange-500/20 border border-yellow-500/30 rounded-2xl p-8 inline-block">
              <h3 className="text-2xl font-bold text-white mb-2">Total Bonus Value: ₹70,000</h3>
              <p className="text-yellow-400 font-semibold">Yours FREE with course enrollment!</p>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20">
        <div className="container mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">
              Transform Your Business Today
            </h2>
            <p className="text-xl text-gray-300">
              Limited time offer - Save 70% on the complete AI Automation Mastery course
            </p>
          </motion.div>

          <div className="max-w-4xl mx-auto">
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6 }}
              className="bg-gradient-to-br from-white/10 to-white/5 backdrop-blur-sm rounded-3xl p-8 border-2 border-green-500/50 relative overflow-hidden"
            >
              {/* Popular Badge */}
              <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                <div className="bg-gradient-to-r from-green-500 to-green-600 text-white px-6 py-2 rounded-full text-sm font-semibold">
                  🔥 MOST POPULAR
                </div>
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-center">
                {/* Left - Pricing */}
                <div className="text-center lg:text-left">
                  <h3 className="text-3xl font-bold text-white mb-4">AI Automation Mastery</h3>
                  
                  <div className="mb-6">
                    <div className="flex items-center justify-center lg:justify-start space-x-4 mb-2">
                      <span className="text-5xl font-bold text-green-400">₹15,000</span>
                      <div className="text-left">
                        <div className="text-gray-400 line-through text-xl">₹50,000</div>
                        <div className="text-green-400 font-semibold">70% OFF</div>
                      </div>
                    </div>
                    <p className="text-gray-300">One-time payment • Lifetime access</p>
                  </div>

                  <div className="space-y-3 mb-8">
                    {[
                      "16+ hours of premium video content",
                      "69 step-by-step video lessons", 
                      "6 comprehensive modules",
                      "₹70,000 worth of exclusive bonuses",
                      "Lifetime access to all materials",
                      "Private community access",
                      "Monthly live Q&A sessions",
                      "30-day money-back guarantee"
                    ].map((feature, index) => (
                      <div key={index} className="flex items-center space-x-3">
                        <CheckCircle className="w-5 h-5 text-green-400 flex-shrink-0" />
                        <span className="text-gray-300">{feature}</span>
                      </div>
                    ))}
                  </div>

                  <Button
                    size="lg"
                    className="w-full bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white px-8 py-4 text-xl font-bold shadow-2xl hover:shadow-green-500/25 transition-all duration-300"
                  >
                    <Rocket className="w-6 h-6 mr-3" />
                    Enroll Now - ₹15,000 Only
                  </Button>

                  <div className="mt-4 flex items-center justify-center lg:justify-start space-x-2 text-yellow-400">
                    <Timer className="w-4 h-4" />
                    <span className="text-sm font-medium">Offer expires in 48 hours!</span>
                  </div>
                </div>

                {/* Right - Guarantee */}
                <div className="text-center">
                  <div className="bg-gradient-to-br from-blue-500/20 to-purple-500/20 rounded-2xl p-8 border border-blue-500/30">
                    <Shield className="w-16 h-16 text-blue-400 mx-auto mb-4" />
                    <h4 className="text-2xl font-bold text-white mb-4">30-Day Money-Back Guarantee</h4>
                    <p className="text-gray-300 leading-relaxed mb-6">
                      We're so confident you'll love this course that we offer a full 30-day money-back guarantee. 
                      If you're not completely satisfied, get every penny back - no questions asked.
                    </p>
                    
                    <div className="bg-white/10 rounded-xl p-4">
                      <p className="text-sm text-gray-300">
                        <strong className="text-white">Risk-Free Investment:</strong> Try the complete course for 30 days. 
                        If you don't see measurable improvements in your business automation, we\'ll refund 100% of your money.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* FAQ Section */}
      <section className="py-20 bg-white/5 backdrop-blur-sm">
        <div className="container mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl font-bold text-white mb-4">
              Frequently Asked Questions
            </h2>
            <p className="text-xl text-gray-300">
              Got questions? We've got answers.
            </p>
          </motion.div>

          <div className="max-w-3xl mx-auto space-y-4">
            {faqs.map((faq, index) => (
              <motion.div
                key={index}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
                className="bg-white/10 backdrop-blur-sm rounded-xl border border-white/20 overflow-hidden"
              >
                <button
                  className="w-full text-left p-6 hover:bg-white/5 transition-colors duration-200"
                  onClick={() => setOpenFaq(openFaq === index ? null : index)}
                >
                  <div className="flex items-center justify-between">
                    <h3 className="text-lg font-semibold text-white pr-4">{faq.question}</h3>
                    <ChevronDown className={`w-5 h-5 text-gray-400 transition-transform duration-200 ${
                      openFaq === index ? 'rotate-180' : ''
                    }`} />
                  </div>
                </button>
                
                {openFaq === index && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.3 }}
                    className="px-6 pb-6"
                  >
                    <p className="text-gray-300 leading-relaxed">{faq.answer}</p>
                  </motion.div>
                )}
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Final CTA */}
      <section className="py-20 bg-gradient-to-r from-green-900/30 to-blue-900/30">
        <div className="container mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <h2 className="text-4xl lg:text-5xl font-bold text-white mb-6">
              Ready to Automate Your Success?
            </h2>
            <p className="text-xl text-gray-300 mb-8 max-w-3xl mx-auto">
              Join 500+ entrepreneurs who have already transformed their businesses with AI automation. 
              Don't let your competitors get ahead - start your automation journey today!
            </p>
            
            <div className="flex flex-col sm:flex-row gap-6 justify-center items-center mb-8">
              <Button
                size="lg"
                className="bg-gradient-to-r from-green-500 to-green-600 hover:from-green-600 hover:to-green-700 text-white px-12 py-6 text-xl font-bold shadow-2xl hover:shadow-green-500/25 transition-all duration-300"
              >
                <Rocket className="w-6 h-6 mr-3" />
                Start Your Automation Journey - ₹15,000
              </Button>
              
              <div className="text-center">
                <div className="text-yellow-400 font-semibold mb-1">⏰ Limited Time Offer</div>
                <div className="text-gray-300 text-sm">70% OFF • Expires in 48 hours</div>
              </div>
            </div>

            <div className="flex justify-center space-x-8 text-sm text-gray-300">
              <div className="flex items-center space-x-2">
                <Shield className="w-4 h-4 text-green-400" />
                <span>30-Day Guarantee</span>
              </div>
              <div className="flex items-center space-x-2">
                <Clock className="w-4 h-4 text-blue-400" />
                <span>Lifetime Access</span>
              </div>
              <div className="flex items-center space-x-2">
                <Users className="w-4 h-4 text-purple-400" />
                <span>500+ Students</span>
              </div>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-black/50 backdrop-blur-sm border-t border-white/10">
        <div className="container mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div>
              <h3 className="text-xl font-bold text-white mb-4">AI Automation Coach</h3>
              <p className="text-gray-300 leading-relaxed">
                Empowering entrepreneurs with cutting-edge AI automation strategies to scale their businesses exponentially.
              </p>
            </div>
            
            <div>
              <h4 className="text-lg font-semibold text-white mb-4">Quick Links</h4>
              <ul className="space-y-2 text-gray-300">
                <li><a href="#curriculum" className="hover:text-white transition-colors">Course Curriculum</a></li>
                <li><a href="#pricing" className="hover:text-white transition-colors">Pricing</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Student Reviews</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Success Stories</a></li>
              </ul>
            </div>
            
            <div>
              <h4 className="text-lg font-semibold text-white mb-4">Contact Support</h4>
              <div className="space-y-2 text-gray-300">
                <div className="flex items-center space-x-2">
                  <Mail className="w-4 h-4" />
                  <span>support@aiacoach.com</span>
                </div>
                <div className="flex items-center space-x-2">
                  <Phone className="w-4 h-4" />
                  <span>+91 98765 43210</span>
                </div>
                <div className="flex items-center space-x-2">
                  <MessageCircle className="w-4 h-4" />
                  <span>WhatsApp Support</span>
                </div>
              </div>
            </div>
          </div>
          
          <div className="border-t border-white/10 mt-8 pt-8 text-center text-gray-400">
            <p>&copy; 2024 AI Automation Coach. All rights reserved. | Privacy Policy | Terms of Service</p>
          </div>
        </div>
      </footer>
    </div>
  )
}