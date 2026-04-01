# Historical feeding data import — March 11-24, 2026
# Source: iPhone Notes maintained by Mohit Chandana
#
# Rules:
#   - Time + ml (no label)          → bottle, breast_milk
#   - Time + ml (formula/similac)   → bottle, formula
#   - Time range (Left/Right)       → breastfeed with side
#   - Time range (no side)          → breastfeed, side = "both"
#   - Pumped (time) - Xml           → pump
#   - Xml + Yml                     → combo feed (two bottles, same session_group)
#   - Xml (formula) + Yml           → combo: formula + breast_milk

baby = Baby.find_by!(name: "Ojas Chandana")
user = User.first

YEAR = 2026
created = 0
skipped = 0

def t(month, day, time_str)
  time_str = time_str.strip.upcase
  hour, rest = time_str.split(":")
  min_part = rest.gsub(/[^0-9]/, "")
  ampm = time_str.include?("PM") ? "PM" : "AM"
  Time.zone.parse("2026-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')} #{hour}:#{min_part} #{ampm}")
end

def log_bottle(baby, user, started_at, volume_ml, milk_type: "breast_milk", formula_brand: nil, session_group: nil, notes: nil)
  f = Feeding.find_or_initialize_by(baby: baby, started_at: started_at, feed_type: "bottle")
  return :skipped if f.persisted?
  f.assign_attributes(
    user: user,
    volume_ml: volume_ml,
    milk_type: milk_type,
    formula_brand: formula_brand,
    session_group: session_group,
    notes: notes
  )
  f.save!
  :created
end

def log_breast(baby, user, started_at, ended_at, side: "both", notes: nil)
  f = Feeding.find_or_initialize_by(baby: baby, started_at: started_at, feed_type: "breastfeed")
  return :skipped if f.persisted?
  f.assign_attributes(
    user: user,
    ended_at: ended_at,
    breast_side: side,
    notes: notes
  )
  f.save!
  :created
end

def log_pump(baby, user, started_at, volume_ml, notes: nil)
  f = Feeding.find_or_initialize_by(baby: baby, started_at: started_at, feed_type: "pump")
  return :skipped if f.persisted?
  f.assign_attributes(
    user: user,
    volume_ml: volume_ml,
    notes: notes
  )
  f.save!
  :created
end

def track(result)
  result == :created ? 1 : 0
end

Time.zone = "America/New_York"

# ==================== MARCH 11 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 11, "1:30 PM"), 35))
c += track(log_bottle(baby, user, t(3, 11, "3:00 PM"), 10))
c += track(log_breast(baby, user, t(3, 11, "5:52 PM"), t(3, 11, "5:52 PM") + 27.minutes, side: "both", notes: "27 min session"))
c += track(log_bottle(baby, user, t(3, 11, "7:15 PM"), 20))
c += track(log_breast(baby, user, t(3, 11, "9:45 PM"), t(3, 11, "10:15 PM"), side: "both", notes: "30 min session"))
# 9:45 PM session also had 30ml noted but per dr advice, not logging ml for breastfeed
c += track(log_bottle(baby, user, t(3, 11, "11:00 PM"), 15))
puts "March 11: #{c} feedings imported"
created += c

# ==================== MARCH 12 ====================
c = 0
c += track(log_breast(baby, user, t(3, 12, "12:13 AM"), t(3, 12, "12:28 AM"), side: "both", notes: "15 min"))
c += track(log_bottle(baby, user, t(3, 12, "1:00 AM"), 20))
c += track(log_bottle(baby, user, t(3, 12, "2:30 AM"), 40))
c += track(log_bottle(baby, user, t(3, 12, "5:30 AM"), 45))
c += track(log_bottle(baby, user, t(3, 12, "6:15 AM"), 15))
c += track(log_bottle(baby, user, t(3, 12, "8:15 AM"), 45))
c += track(log_breast(baby, user, t(3, 12, "10:10 AM"), t(3, 12, "10:45 AM"), side: "both"))
c += track(log_breast(baby, user, t(3, 12, "12:10 PM"), t(3, 12, "12:40 PM"), side: "both"))
c += track(log_breast(baby, user, t(3, 12, "3:10 PM"), t(3, 12, "3:40 PM"), side: "both"))
c += track(log_breast(baby, user, t(3, 12, "6:00 PM"), t(3, 12, "6:20 PM"), side: "both"))
c += track(log_breast(baby, user, t(3, 12, "10:24 PM"), t(3, 12, "10:44 PM"), side: "both"))
c += track(log_breast(baby, user, t(3, 12, "10:47 PM"), t(3, 12, "10:52 PM"), side: "both", notes: "second breast"))
c += track(log_bottle(baby, user, t(3, 12, "11:30 PM"), 22))
puts "March 12: #{c} feedings imported"
created += c

# ==================== MARCH 13 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 13, "3:30 AM"), 45))
c += track(log_bottle(baby, user, t(3, 13, "6:00 AM"), 45))
c += track(log_breast(baby, user, t(3, 13, "8:25 AM"), t(3, 13, "8:45 AM"), side: "both"))
c += track(log_bottle(baby, user, t(3, 13, "11:45 AM"), 40))
c += track(log_bottle(baby, user, t(3, 13, "3:15 PM"), 60))
c += track(log_breast(baby, user, t(3, 13, "6:53 PM"), t(3, 13, "6:59 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 13, "7:14 PM"), t(3, 13, "7:35 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 13, "10:08 PM"), t(3, 13, "10:25 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 13, "10:31 PM"), t(3, 13, "10:41 PM"), side: "left"))
puts "March 13: #{c} feedings imported"
created += c

# ==================== MARCH 14 ====================
c = 0
c += track(log_breast(baby, user, t(3, 14, "12:00 AM"), t(3, 14, "12:12 AM"), side: "left"))
c += track(log_breast(baby, user, t(3, 14, "12:20 AM"), t(3, 14, "12:33 AM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 14, "12:35 AM"), 30))
c += track(log_breast(baby, user, t(3, 14, "3:40 AM"), t(3, 14, "3:58 AM"), side: "right"))
c += track(log_breast(baby, user, t(3, 14, "4:21 AM"), t(3, 14, "4:41 AM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 14, "4:41 AM"), 5))
c += track(log_bottle(baby, user, t(3, 14, "7:35 AM"), 60, milk_type: "formula"))
c += track(log_breast(baby, user, t(3, 14, "10:55 AM"), t(3, 14, "11:15 AM"), side: "left"))
c += track(log_breast(baby, user, t(3, 14, "11:25 AM"), t(3, 14, "11:45 AM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 14, "2:45 PM"), 10))
c += track(log_breast(baby, user, t(3, 14, "2:50 PM"), t(3, 14, "3:10 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 14, "3:18 PM"), t(3, 14, "3:30 PM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 14, "6:15 PM"), 60, milk_type: "formula"))
c += track(log_bottle(baby, user, t(3, 14, "8:15 PM"), 70))
c += track(log_breast(baby, user, t(3, 14, "10:50 PM"), t(3, 14, "11:10 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 14, "11:27 PM"), t(3, 14, "11:47 PM"), side: "right"))
puts "March 14: #{c} feedings imported"
created += c

# ==================== MARCH 15 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 15, "2:30 AM"), 70))
c += track(log_bottle(baby, user, t(3, 15, "6:30 AM"), 60))
c += track(log_breast(baby, user, t(3, 15, "8:54 AM"), t(3, 15, "9:15 AM"), side: "right"))
c += track(log_breast(baby, user, t(3, 15, "9:24 AM"), t(3, 15, "9:46 AM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 15, "11:05 AM"), 70))
c += track(log_bottle(baby, user, t(3, 15, "1:30 PM"), 70))
c += track(log_breast(baby, user, t(3, 15, "3:55 PM"), t(3, 15, "4:15 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 15, "4:23 PM"), t(3, 15, "4:40 PM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 15, "7:10 PM"), 70))
c += track(log_bottle(baby, user, t(3, 15, "10:15 PM"), 65, milk_type: "formula", formula_brand: "Similac 360 Total Care"))
puts "March 15: #{c} feedings imported"
created += c

# ==================== MARCH 16 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 16, "1:10 AM"), 70))
c += track(log_bottle(baby, user, t(3, 16, "4:10 AM"), 75))
c += track(log_breast(baby, user, t(3, 16, "9:50 AM"), t(3, 16, "10:10 AM"), side: "right"))
c += track(log_breast(baby, user, t(3, 16, "10:30 AM"), t(3, 16, "10:45 AM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 16, "12:40 PM"), 70))
c += track(log_bottle(baby, user, t(3, 16, "3:10 PM"), 70))
c += track(log_breast(baby, user, t(3, 16, "6:10 PM"), t(3, 16, "6:25 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 16, "6:35 PM"), t(3, 16, "6:55 PM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 16, "9:00 PM"), 70))
c += track(log_bottle(baby, user, t(3, 16, "11:15 PM"), 65, milk_type: "formula"))
puts "March 16: #{c} feedings imported"
created += c

# ==================== MARCH 17 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 17, "2:50 AM"), 70))
c += track(log_bottle(baby, user, t(3, 17, "6:30 AM"), 70))
c += track(log_bottle(baby, user, t(3, 17, "8:30 AM"), 70))
c += track(log_bottle(baby, user, t(3, 17, "1:00 PM"), 70))
c += track(log_bottle(baby, user, t(3, 17, "3:25 PM"), 70))
c += track(log_bottle(baby, user, t(3, 17, "6:15 PM"), 60))
c += track(log_bottle(baby, user, t(3, 17, "8:45 PM"), 80))
c += track(log_bottle(baby, user, t(3, 17, "11:00 PM"), 65, milk_type: "formula"))
puts "March 17: #{c} feedings imported"
created += c

# ==================== MARCH 18 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 18, "2:00 AM"), 40))
c += track(log_bottle(baby, user, t(3, 18, "6:00 AM"), 70))
c += track(log_breast(baby, user, t(3, 18, "10:00 AM"), t(3, 18, "10:20 AM"), side: "left"))
c += track(log_breast(baby, user, t(3, 18, "10:25 AM"), t(3, 18, "10:50 AM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 18, "12:35 PM"), 70))
c += track(log_bottle(baby, user, t(3, 18, "2:40 PM"), 70))
c += track(log_pump(baby, user, t(3, 18, "3:40 PM"), 140))
c += track(log_bottle(baby, user, t(3, 18, "5:30 PM"), 70))
c += track(log_bottle(baby, user, t(3, 18, "7:45 PM"), 90))
c += track(log_pump(baby, user, t(3, 18, "8:20 PM"), 130))
puts "March 18: #{c} feedings imported"
created += c

# ==================== MARCH 19 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 19, "1:45 AM"), 80))
c += track(log_bottle(baby, user, t(3, 19, "5:00 AM"), 80))
c += track(log_pump(baby, user, t(3, 19, "5:00 AM") + 1.minute, 80, notes: "Pumped concurrent with bottle"))
c += track(log_bottle(baby, user, t(3, 19, "8:00 AM"), 80))
c += track(log_bottle(baby, user, t(3, 19, "10:25 AM"), 70))
c += track(log_bottle(baby, user, t(3, 19, "12:45 PM"), 70))
c += track(log_bottle(baby, user, t(3, 19, "2:45 PM"), 90))
c += track(log_breast(baby, user, t(3, 19, "5:00 PM"), t(3, 19, "5:20 PM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 19, "7:45 PM"), 70))
c += track(log_pump(baby, user, t(3, 19, "8:00 PM"), 130))
c += track(log_breast(baby, user, t(3, 19, "10:00 PM"), t(3, 19, "10:15 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 19, "10:21 PM"), t(3, 19, "10:41 PM"), side: "left"))
puts "March 19: #{c} feedings imported"
created += c

# ==================== MARCH 20 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 20, "12:15 AM"), 70))
c += track(log_bottle(baby, user, t(3, 20, "3:25 AM"), 80))
c += track(log_bottle(baby, user, t(3, 20, "6:30 AM"), 80))
c += track(log_bottle(baby, user, t(3, 20, "9:30 AM"), 70))
c += track(log_bottle(baby, user, t(3, 20, "11:30 AM"), 70))
c += track(log_bottle(baby, user, t(3, 20, "3:00 PM"), 70))
c += track(log_breast(baby, user, t(3, 20, "4:33 PM"), t(3, 20, "4:53 PM"), side: "left"))
c += track(log_bottle(baby, user, t(3, 20, "5:15 PM"), 30))
c += track(log_bottle(baby, user, t(3, 20, "7:20 PM"), 70))
c += track(log_breast(baby, user, t(3, 20, "10:05 PM"), t(3, 20, "10:25 PM"), side: "right"))
c += track(log_breast(baby, user, t(3, 20, "10:30 PM"), t(3, 20, "10:45 PM"), side: "left"))
puts "March 20: #{c} feedings imported"
created += c

# ==================== MARCH 21 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 21, "1:15 AM"), 80))
# 5:45 AM - 70ml + 40ml (combo, both breast milk)
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 21, "5:45 AM"), 70, session_group: sg))
c += track(log_bottle(baby, user, t(3, 21, "5:45 AM") + 1.second, 40, session_group: sg))
c += track(log_bottle(baby, user, t(3, 21, "9:15 AM"), 70))
# 11:15 AM - 50ml + 50ml (combo, both breast milk)
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 21, "11:15 AM"), 50, session_group: sg))
c += track(log_bottle(baby, user, t(3, 21, "11:15 AM") + 1.second, 50, session_group: sg))
c += track(log_bottle(baby, user, t(3, 21, "1:25 PM"), 90))
c += track(log_breast(baby, user, t(3, 21, "4:15 PM"), t(3, 21, "4:35 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 21, "4:43 PM"), t(3, 21, "5:05 PM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 21, "6:15 PM"), 90))
c += track(log_bottle(baby, user, t(3, 21, "8:45 PM"), 90))
c += track(log_breast(baby, user, t(3, 21, "9:25 PM"), t(3, 21, "9:25 PM") + 2.minutes, side: "left", notes: "2 minutes"))
c += track(log_bottle(baby, user, t(3, 21, "10:50 PM"), 50))
c += track(log_breast(baby, user, t(3, 21, "10:55 PM"), t(3, 21, "11:15 PM"), side: "left"))
puts "March 21: #{c} feedings imported"
created += c

# ==================== MARCH 22 ====================
c = 0
# 2:30 AM - 65ml formula + 30ml breast milk (combo)
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 22, "2:30 AM"), 65, milk_type: "formula", session_group: sg))
c += track(log_bottle(baby, user, t(3, 22, "2:30 AM") + 1.second, 30, session_group: sg))
c += track(log_bottle(baby, user, t(3, 22, "6:10 AM"), 95))
c += track(log_bottle(baby, user, t(3, 22, "9:20 AM"), 90))
c += track(log_bottle(baby, user, t(3, 22, "12:20 PM"), 90))
c += track(log_bottle(baby, user, t(3, 22, "2:30 PM"), 90))
c += track(log_pump(baby, user, t(3, 22, "4:00 PM"), 110))
c += track(log_bottle(baby, user, t(3, 22, "5:10 PM"), 90))
c += track(log_breast(baby, user, t(3, 22, "8:05 PM"), t(3, 22, "8:25 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 22, "8:30 PM"), t(3, 22, "8:45 PM"), side: "right"))
# 10:25 PM - 70ml + 30ml (Formula) — combo: breast milk + formula
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 22, "10:25 PM"), 70, session_group: sg))
c += track(log_bottle(baby, user, t(3, 22, "10:25 PM") + 1.second, 30, milk_type: "formula", session_group: sg))
puts "March 22: #{c} feedings imported"
created += c

# ==================== MARCH 23 ====================
c = 0
# 1:15 AM - 65ml (Formula) + 30ml breast milk
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 23, "1:15 AM"), 65, milk_type: "formula", session_group: sg))
c += track(log_bottle(baby, user, t(3, 23, "1:15 AM") + 1.second, 30, session_group: sg))
c += track(log_bottle(baby, user, t(3, 23, "4:45 AM"), 90))
c += track(log_bottle(baby, user, t(3, 23, "8:00 AM"), 90))
c += track(log_bottle(baby, user, t(3, 23, "10:00 AM"), 90))
# 12:30 PM - 60ml (Formula) + 20ml breast milk
sg = SecureRandom.uuid
c += track(log_bottle(baby, user, t(3, 23, "12:30 PM"), 60, milk_type: "formula", session_group: sg))
c += track(log_bottle(baby, user, t(3, 23, "12:30 PM") + 1.second, 20, session_group: sg))
c += track(log_bottle(baby, user, t(3, 23, "2:45 PM"), 90))
c += track(log_bottle(baby, user, t(3, 23, "5:00 PM"), 80))
c += track(log_breast(baby, user, t(3, 23, "8:10 PM"), t(3, 23, "8:23 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 23, "8:40 PM"), t(3, 23, "8:56 PM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 23, "10:45 PM"), 80))
puts "March 23: #{c} feedings imported"
created += c

# ==================== MARCH 24 ====================
c = 0
c += track(log_bottle(baby, user, t(3, 24, "1:00 AM"), 110))
c += track(log_bottle(baby, user, t(3, 24, "4:45 AM"), 80))
c += track(log_bottle(baby, user, t(3, 24, "7:20 AM"), 90))
c += track(log_bottle(baby, user, t(3, 24, "9:20 AM"), 80))
c += track(log_bottle(baby, user, t(3, 24, "12:35 PM"), 80))
c += track(log_bottle(baby, user, t(3, 24, "3:35 PM"), 80))
c += track(log_bottle(baby, user, t(3, 24, "6:40 PM"), 80))
c += track(log_breast(baby, user, t(3, 24, "9:13 PM"), t(3, 24, "9:35 PM"), side: "left"))
c += track(log_breast(baby, user, t(3, 24, "9:40 PM"), t(3, 24, "10:00 PM"), side: "right"))
c += track(log_bottle(baby, user, t(3, 24, "11:30 PM"), 90))
puts "March 24: #{c} feedings imported"
created += c

puts ""
puts "=" * 50
puts "Import complete: #{created} feedings created"
puts "Total feedings in database: #{baby.feedings.unscoped.count}"
