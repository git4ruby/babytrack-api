return if Rails.env.test?

# Default user
user = User.find_or_create_by!(email: "mohit@babytrack.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.name = "Mohit Chandana"
  u.role = "parent"
  u.email_verified = true
  u.terms_accepted_at = Time.current
end
puts "Created user: #{user.email}"

# Second user (shared caregiver)
wife = User.find_or_create_by!(email: "likitha@babytrack.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.name = "Likitha Bandreddy"
  u.role = "parent"
  u.email_verified = true
  u.terms_accepted_at = Time.current
end
puts "Created user: #{wife.email}"

# Baby Ojas
baby = Baby.find_or_create_by!(name: "Ojas Chandana", user: user) do |b|
  b.date_of_birth = Date.new(2026, 3, 9)
  b.gender = "male"
  b.birth_weight_grams = 3200
end
puts "Created baby: #{baby.name} (DOB: #{baby.date_of_birth})"

# Share baby with wife
BabyShare.find_or_create_by!(baby: baby, invite_email: wife.email) do |s|
  s.user = wife
  s.role = "caregiver"
  s.status = "accepted"
  s.accepted_at = Time.current
end
puts "Shared baby with #{wife.name}"

# Standard US vaccination schedule
vaccinations = [
  { vaccine_name: "Hepatitis B — Dose 1", recommended_age_days: 0, description: "Given at birth" },
  { vaccine_name: "Hepatitis B — Dose 2", recommended_age_days: 60, description: "2 months" },
  { vaccine_name: "DTaP — Dose 1", recommended_age_days: 60, description: "Diphtheria, Tetanus, Pertussis" },
  { vaccine_name: "Hib — Dose 1", recommended_age_days: 60, description: "Haemophilus influenzae type b" },
  { vaccine_name: "IPV — Dose 1", recommended_age_days: 60, description: "Polio" },
  { vaccine_name: "PCV15 — Dose 1", recommended_age_days: 60, description: "Pneumococcal" },
  { vaccine_name: "RV — Dose 1", recommended_age_days: 60, description: "Rotavirus (oral)" },
  { vaccine_name: "DTaP — Dose 2", recommended_age_days: 120, description: "4 months" },
  { vaccine_name: "Hib — Dose 2", recommended_age_days: 120, description: "4 months" },
  { vaccine_name: "IPV — Dose 2", recommended_age_days: 120, description: "4 months" },
  { vaccine_name: "PCV15 — Dose 2", recommended_age_days: 120, description: "4 months" },
  { vaccine_name: "RV — Dose 2", recommended_age_days: 120, description: "4 months" },
  { vaccine_name: "Hepatitis B — Dose 3", recommended_age_days: 180, description: "6 months" },
  { vaccine_name: "DTaP — Dose 3", recommended_age_days: 180, description: "6 months" },
  { vaccine_name: "Hib — Dose 3", recommended_age_days: 180, description: "6 months (if needed based on brand)" },
  { vaccine_name: "PCV15 — Dose 3", recommended_age_days: 180, description: "6 months" },
  { vaccine_name: "RV — Dose 3", recommended_age_days: 180, description: "6 months (if needed based on brand)" },
  { vaccine_name: "IPV — Dose 3", recommended_age_days: 180, description: "6-18 months" },
  { vaccine_name: "Influenza — Annual", recommended_age_days: 180, description: "Annual after 6 months" },
  { vaccine_name: "MMR — Dose 1", recommended_age_days: 365, description: "12 months" },
  { vaccine_name: "Varicella — Dose 1", recommended_age_days: 365, description: "12 months" },
  { vaccine_name: "Hepatitis A — Dose 1", recommended_age_days: 365, description: "12 months" },
  { vaccine_name: "PCV15 — Dose 4", recommended_age_days: 395, description: "12-15 months" },
  { vaccine_name: "Hib — Booster", recommended_age_days: 395, description: "12-15 months" },
  { vaccine_name: "DTaP — Dose 4", recommended_age_days: 480, description: "15-18 months" },
  { vaccine_name: "Hepatitis A — Dose 2", recommended_age_days: 548, description: "18 months (6 months after dose 1)" }
]

vaccinations.each do |vax|
  v = Vaccination.find_or_create_by!(baby: baby, vaccine_name: vax[:vaccine_name]) do |rec|
    rec.recommended_age_days = vax[:recommended_age_days]
    rec.description = vax[:description]
    rec.status = "pending"
  end
  # Mark HepB Dose 1 as administered at birth
  if vax[:vaccine_name] == "Hepatitis B — Dose 1" && v.pending?
    v.update!(status: "administered", administered_at: baby.date_of_birth, administered_by: "Hospital")
  end
end
puts "Created #{vaccinations.size} vaccination records"

# --- Helper ---
tz = ActiveSupport::TimeZone["America/New_York"]

# --- Feedings (past 28 days, ~8-10 per day) ---
feeding_count = 0
28.downto(0) do |days_ago|
  date = Date.current - days_ago
  feeds_today = rand(8..10)
  hour = 6 # start around 6 AM

  feeds_today.times do |i|
    gap = rand(120..210) # 2-3.5 hours between feeds
    hour_offset = (i * gap) / 60
    minute = (i * gap) % 60
    feed_hour = (6 + hour_offset) % 24
    started = tz.parse("#{date} #{feed_hour}:#{minute.to_s.rjust(2, '0')}")

    logged_by = [ user, wife ].sample

    if rand < 0.55 # 55% bottle
      volume = [ 60, 70, 80, 90, 100, 110, 120 ].sample
      Feeding.find_or_create_by!(baby: baby, started_at: started, feed_type: "bottle") do |f|
        f.user = logged_by
        f.volume_ml = volume
        f.milk_type = rand < 0.8 ? "breast_milk" : "formula"
        f.notes = [ nil, nil, nil, "Took full bottle", "Fussy at first", "Fell asleep mid-feed" ].sample
      end
    else # 45% breastfeed
      side = %w[left right].sample
      duration = rand(8..25)
      Feeding.find_or_create_by!(baby: baby, started_at: started, feed_type: "breastfeed") do |f|
        f.user = logged_by
        f.breast_side = side
        f.duration_minutes = duration
      end
    end
    feeding_count += 1
  end
end
puts "Created #{feeding_count} feedings"

# --- Diapers (past 28 days, ~6-8 per day) ---
diaper_count = 0
28.downto(0) do |days_ago|
  date = Date.current - days_ago
  changes_today = rand(6..8)

  changes_today.times do |i|
    hour = 6 + (i * (18.0 / changes_today)).round
    hour = hour % 24
    changed = tz.parse("#{date} #{hour}:#{rand(0..59).to_s.rjust(2, '0')}")
    dtype = %w[wet wet wet soiled both wet soiled].sample

    DiaperChange.find_or_create_by!(baby: baby, changed_at: changed) do |d|
      d.user = [ user, wife ].sample
      d.diaper_type = dtype
      d.stool_color = dtype != "wet" ? %w[yellow green brown yellow yellow].sample : nil
      d.consistency = dtype != "wet" ? %w[normal seedy normal loose normal].sample : nil
      d.has_rash = rand < 0.05
      d.notes = [ nil, nil, nil, nil, "Big blowout", "Tiny bit" ].sample
    end
    diaper_count += 1
  end
end
puts "Created #{diaper_count} diaper changes"

# --- Sleep Logs (past 28 days, ~4-5 per day) ---
sleep_count = 0
28.downto(0) do |days_ago|
  date = Date.current - days_ago

  # Night sleep (previous night, ~7-9 hours)
  night_start = tz.parse("#{date - 1} #{rand(19..21)}:#{rand(0..59).to_s.rjust(2, '0')}")
  night_end = night_start + rand(420..540).minutes
  SleepLog.find_or_create_by!(baby: baby, started_at: night_start, sleep_type: "night") do |s|
    s.user = user
    s.ended_at = night_end
    s.duration_minutes = ((night_end - night_start) / 60).round
    s.location = %w[crib bassinet].sample
  end
  sleep_count += 1

  # 2-3 naps
  nap_count = rand(2..3)
  nap_count.times do |i|
    nap_hour = [ 9, 13, 16 ][i] || 14
    nap_start = tz.parse("#{date} #{nap_hour}:#{rand(0..30).to_s.rjust(2, '0')}")
    nap_duration = rand(30..90)
    SleepLog.find_or_create_by!(baby: baby, started_at: nap_start, sleep_type: "nap") do |s|
      s.user = [ user, wife ].sample
      s.ended_at = nap_start + nap_duration.minutes
      s.duration_minutes = nap_duration
      s.location = %w[crib stroller arms bassinet].sample
    end
    sleep_count += 1
  end
end
puts "Created #{sleep_count} sleep logs"

# --- Weight Logs (weekly, showing growth) ---
weights = [
  { days_ago: 28, grams: 3200, height: 49.0, head: 34.5 },
  { days_ago: 21, grams: 3450, height: 49.5, head: 35.0 },
  { days_ago: 14, grams: 3700, height: 50.5, head: 35.3 },
  { days_ago: 7, grams: 3900, height: 51.0, head: 35.8 },
  { days_ago: 0, grams: 4100, height: 52.0, head: 36.0 }
]

weights.each do |w|
  date = Date.current - w[:days_ago]
  recorded = tz.parse("#{date} 10:00")
  WeightLog.find_or_create_by!(baby: baby, recorded_at: recorded) do |wl|
    wl.user = user
    wl.weight_grams = w[:grams]
    wl.height_cm = w[:height]
    wl.head_circumference_cm = w[:head]
    wl.measured_by = "Pediatrician"
  end
end
puts "Created #{weights.size} weight logs"

# --- Milestones ---
milestones = [
  { title: "First smile", achieved_on: Date.current - 20, category: "social", description: "Smiled at mom during feeding" },
  { title: "Lifts head during tummy time", achieved_on: Date.current - 14, category: "motor", description: "Held head up for about 10 seconds" },
  { title: "Follows objects with eyes", achieved_on: Date.current - 10, category: "cognitive", description: "Tracked a rattle moving left to right" },
  { title: "Cooing sounds", achieved_on: Date.current - 7, category: "language", description: "Started making 'ooh' and 'aah' sounds" },
  { title: "Grasps finger", achieved_on: Date.current - 3, category: "motor", description: "Grabbed dad's finger tightly" }
]

milestones.each do |m|
  Milestone.find_or_create_by!(baby: baby, title: m[:title]) do |rec|
    rec.user = user
    rec.achieved_on = m[:achieved_on]
    rec.category = m[:category]
    rec.description = m[:description]
  end
end
puts "Created #{milestones.size} milestones"

# --- Appointments ---
appointments = [
  { title: "1-Week Checkup", scheduled_at: tz.parse("#{Date.current - 21} 10:00"), provider_name: "Dr. Patel", location: "Pediatrics Clinic", status: "completed", appointment_type: "well_visit" },
  { title: "2-Week Checkup", scheduled_at: tz.parse("#{Date.current - 14} 14:00"), provider_name: "Dr. Patel", location: "Pediatrics Clinic", status: "completed", appointment_type: "well_visit" },
  { title: "1-Month Checkup", scheduled_at: tz.parse("#{Date.current + 2} 10:30"), provider_name: "Dr. Patel", location: "Pediatrics Clinic", status: "upcoming", appointment_type: "well_visit" },
  { title: "Lactation Consultant", scheduled_at: tz.parse("#{Date.current + 5} 15:00"), provider_name: "Sarah Johnson, IBCLC", location: "Breastfeeding Center", status: "upcoming", appointment_type: "specialist" }
]

appointments.each do |a|
  Appointment.find_or_create_by!(baby: baby, title: a[:title]) do |rec|
    rec.user = user
    rec.scheduled_at = a[:scheduled_at]
    rec.provider_name = a[:provider_name]
    rec.location = a[:location]
    rec.status = a[:status]
    rec.appointment_type = a[:appointment_type]
  end
end
puts "Created #{appointments.size} appointments"

# --- Milk Storage ---
stashes = [
  { volume_ml: 120, storage_type: "fridge", stored_at: tz.parse("#{Date.current} 08:00"), label: "Morning pump" },
  { volume_ml: 90, storage_type: "fridge", stored_at: tz.parse("#{Date.current - 1} 14:00"), label: "Afternoon pump" },
  { volume_ml: 150, storage_type: "freezer", stored_at: tz.parse("#{Date.current - 3} 09:00"), label: "Extra from Mon" },
  { volume_ml: 100, storage_type: "freezer", stored_at: tz.parse("#{Date.current - 5} 20:00"), label: "Evening pump" },
  { volume_ml: 80, storage_type: "room_temp", stored_at: tz.parse("#{Date.current} 12:00"), label: "Just pumped" }
]

stashes.each do |s|
  MilkStash.find_or_create_by!(baby: baby, label: s[:label]) do |ms|
    ms.user = user
    ms.volume_ml = s[:volume_ml]
    ms.storage_type = s[:storage_type]
    ms.stored_at = s[:stored_at]
    ms.source_type = "pumped"
    ms.status = "available"
    ms.expires_at = ms.stored_at + MilkStash::EXPIRATION_HOURS.fetch(s[:storage_type], 96).hours
  end
end
puts "Created #{stashes.size} milk stashes"

# --- Diary Entries ---
diary_entries = [
  { content: "Ojas had his first bath at home today. He cried at first but then seemed to enjoy the warm water. His little fists were clenched the whole time!", entry_date: Date.current - 25, mood: "sweet" },
  { content: "He discovered his hands today! Kept staring at them and trying to put them in his mouth. So adorable.", entry_date: Date.current - 18, mood: "funny" },
  { content: "Slept 5 hours straight for the first time. Both parents celebrating!", entry_date: Date.current - 12, mood: "happy" },
  { content: "Fussy day — couldn't figure out what was wrong. Turns out he just wanted to be held all day. Carrier saved us.", entry_date: Date.current - 8, mood: "neutral" },
  { content: "Tried tummy time on the play mat with the mirror. He was fascinated by his own reflection!", entry_date: Date.current - 5, mood: "proud" },
  { content: "Made eye contact with grandma on video call and smiled. She was over the moon.", entry_date: Date.current - 2, mood: "happy" },
  { content: "His umbilical cord stump finally fell off. One less thing to worry about during bath time.", entry_date: Date.current - 1, mood: "neutral" }
]

diary_entries.each do |d|
  DiaryEntry.find_or_create_by!(baby: baby, content: d[:content]) do |de|
    de.user = user
    de.entry_date = d[:entry_date]
    de.mood = d[:mood]
  end
end
puts "Created #{diary_entries.size} diary entries"

puts "\n✅ Seed complete! Login with mohit@babytrack.local / password123"
