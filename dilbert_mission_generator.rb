#!/usr/bin/env ruby
#
#  File: dilbert_mission_generator.rb
#  Created by Peter Marreck on 2006-11-09.
#  Copyright (c) 2006. All rights reserved.
#  Converted/hacked from a perl script I found online at:
#  http://www.stonehenge.com/merlyn/LinuxMag/col04.html

class Array
 def pick_any
   self[rand(self.length)]
 end
end

class DilbertMissionGenerator

 def missions(n=1, sep=" ")
   (1..n).inject(""){|total,x| total+"#{mission}#{sep}"}
 end

 def mission
   ["#{our_job_is_to} #{do_goals}.",
   "#{our_job_is_to} #{do_goals} #{because}."].pick_any
 end

 def our_job_is_to
   ["#{["It is our", "It's our"].pick_any} #{job} to",
   "Our #{job} #{["is to", "is to continue to"].pick_any}",
   "The customer can count on us to",
   "#{["We continually", "We"].pick_any} #{["strive", "envision",
"exist"].pick_any} to",
   "We have committed to",
   "We"].pick_any
 end

 def job
   ["business", "challenge", "goal", "job", "mission", "responsibility"].pick_any
 end

 def do_goals
   rand(3)!=2 ? goal : "#{goal} #{in_order_to} #{do_goals}" # note use of recursion!
 end

 def in_order_to
   ["as well as to",
   "in order that we may",
   "in order to",
   "so that we may endeavor to",
   "so that we may",
   "such that we may continue to",
   "to allow us to",
   "while continuing to",
   "and"].pick_any
 end

 def because
   ["because that is what the customer expects",
   "for 100% customer satisfaction",
   "in order to solve business problems",
   "to exceed customer expectations",
   "to meet our customer's needs",
   "to set us apart from the competition",
   "to stay competitive in tomorrow's world",
   "while promoting personal employee growth"].pick_any
 end

 def goal
   "#{adverbly} #{verb} #{adjective} #{noun}"
 end

 def adverbly
   ["quickly", "proactively", "efficiently", "assertively",
   "interactively", "professionally", "authoritatively",
   "conveniently", "completely", "continually", "dramatically",
   "enthusiastically", "collaboratively", "synergistically",
   "seamlessly", "competently", "globally"].pick_any
 end

 def verb
   ["maintain", "supply", "provide access to", "disseminate",
   "network", "create", "engineer", "integrate", "leverage other's",
   "leverage existing", "coordinate", "administrate", "initiate",
   "facilitate", "promote", "restore", "fashion", "revolutionize",
   "build", "construct", "enhance", "simplify", "pursue", "utilize", "foster",
   "customize", "negotiate"].pick_any
 end

 def adjective
   ["professional", "timely", "effective", "unique", "cost-effective",
   "virtual", "scalable", "economically sound",
   "inexpensive", "value-added", "business", "quality", "diverse",
   "high-quality", "competitive", "excellent", "innovative",
   "corporate", "high standards in", "world-class", "error-free",
   "performance-based", "multimedia-based", "market-driven", "lightweight",
   "cutting-edge", "high-payoff", "low-risk high-yield", "XML-driven",
   "long-term high-impact", "prospective", "progressive", "ethical",
   "enterprise-wide", "principle-centered", "mission-critical", "open-source",
   "parallel", "interdependent", "emerging", "service-oriented", "AdSense-supported",
   "seven-habits-conforming", "resource-leveling", "paradigm-shifting", "community-driven"].pick_any
 end

 def noun
   ["content", "paradigms", "data", "opportunities", "datamarts", "architectures", "social networking",
   "information", "services", "materials", "technology", "benefits", "folksonomies", "podcasts",
   "solutions", "infrastructures", "products", "deliverables", "web services", "mash-ups", "tag clouds",
   "catalysts for change", "resources", "methods of empowerment", "ajax technologies", "intelligence",
   "sources", "leadership skills", "meta-services", "intellectual capital"].pick_any
 end
end

dmg = DilbertMissionGenerator.new
puts dmg.missions(10,"\n\n")
