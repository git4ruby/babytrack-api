return if Rails.env.test?

# Default user
user = User.find_or_create_by!(email: "mohit@babytrack.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.name = "Mohit Chandana"
  u.role = "parent"
end
puts "Created user: #{user.email}"

# Baby Ojas
baby = Baby.find_or_create_by!(name: "Ojas Chandana") do |b|
  b.date_of_birth = Date.new(2026, 3, 9)
  b.gender = "male"
end
puts "Created baby: #{baby.name} (DOB: #{baby.date_of_birth})"

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
  Vaccination.find_or_create_by!(baby: baby, vaccine_name: vax[:vaccine_name]) do |v|
    v.recommended_age_days = vax[:recommended_age_days]
    v.description = vax[:description]
    v.status = "pending"
  end
end
puts "Created #{vaccinations.size} vaccination records"
