class WhoPercentileService
  PERCENTILES = [ 3, 15, 50, 85, 97 ].freeze
  Z_SCORES = { 3 => -1.881, 15 => -1.036, 50 => 0, 85 => 1.036, 97 => 1.881 }.freeze

  def initialize(gender = "male")
    @gender = gender == "female" ? "girls" : "boys"
    @data = load_data
  end

  # Returns percentile curves: { "P3" => [{age_days, weight_g}, ...], "P50" => [...], ... }
  def weight_for_age_curves(max_days = 365)
    curves = {}
    PERCENTILES.each do |p|
      curves["P#{p}"] = @data.map do |age_days, lms|
        next if age_days.to_i > max_days
        weight_kg = compute_percentile(lms, Z_SCORES[p])
        { age_days: age_days.to_i, weight_grams: (weight_kg * 1000).round }
      end.compact
    end
    curves
  end

  # Compute which percentile a given weight falls at for a given age
  def percentile_for(age_days, weight_grams)
    lms = interpolate_lms(age_days)
    return nil unless lms

    weight_kg = weight_grams / 1000.0
    z = compute_z_score(lms, weight_kg)
    z_to_percentile(z)
  end

  private

  def load_data
    file = Rails.root.join("lib/data/who_weight_for_age.json")
    JSON.parse(File.read(file))[@gender]
  end

  def interpolate_lms(age_days)
    keys = @data.keys.map(&:to_i).sort
    return @data[keys.first.to_s] if age_days <= keys.first
    return @data[keys.last.to_s] if age_days >= keys.last

    lower = keys.select { |k| k <= age_days }.last
    upper = keys.select { |k| k >= age_days }.first

    return @data[lower.to_s] if lower == upper

    # Linear interpolation
    ratio = (age_days - lower).to_f / (upper - lower)
    l1 = @data[lower.to_s]
    l2 = @data[upper.to_s]

    {
      "L" => l1["L"] + ratio * (l2["L"] - l1["L"]),
      "M" => l1["M"] + ratio * (l2["M"] - l1["M"]),
      "S" => l1["S"] + ratio * (l2["S"] - l1["S"])
    }
  end

  def compute_percentile(lms, z)
    l = lms["L"]
    m = lms["M"]
    s = lms["S"]

    if l.abs < 0.001
      m * Math.exp(s * z)
    else
      m * (1 + l * s * z) ** (1.0 / l)
    end
  end

  def compute_z_score(lms, weight_kg)
    l = lms["L"]
    m = lms["M"]
    s = lms["S"]

    if l.abs < 0.001
      Math.log(weight_kg / m) / s
    else
      ((weight_kg / m) ** l - 1) / (l * s)
    end
  end

  def z_to_percentile(z)
    # Approximate normal CDF
    (100 * (0.5 * (1 + Math.erf(z / Math.sqrt(2))))).round(1)
  end
end
