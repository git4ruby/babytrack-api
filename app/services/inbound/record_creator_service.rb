module Inbound
  class RecordCreatorService
    def initialize(user, baby, parsed_actions)
      @user = user
      @baby = baby
      @actions = parsed_actions
      @results = []
    end

    def create_all
      @actions.each do |action|
        result = case action["action"]
        when "feeding" then create_feeding(action)
        when "diaper" then create_diaper(action)
        when "milestone" then create_milestone(action)
        when "weight" then create_weight(action)
        when "milk_storage" then create_milk_storage(action)
        when "unknown" then { success: false, message: action["message"] }
        else { success: false, message: "Unknown action: #{action['action']}" }
        end
        @results << result
      end
      @results
    end

    private

    def parse_time(time_str)
      return Time.current unless time_str.present?
      Time.zone.parse(time_str)
    rescue
      begin
        Time.zone.parse("#{Date.current} #{time_str}")
      rescue
        Time.current
      end
    end

    def parse_date(date_str)
      return Date.current unless date_str.present?
      Date.parse(date_str)
    rescue
      Date.current
    end

    def create_feeding(data)
      started = parse_time(data["started_at"])

      # Dedup: check if same baby + started_at + feed_type already exists
      existing = @baby.feedings.unscoped.where(
        baby: @baby,
        started_at: (started - 2.minutes)..(started + 2.minutes),
        feed_type: data["feed_type"]
      )
      if data["volume_ml"] && data["feed_type"] != "breastfeed"
        existing = existing.where(volume_ml: data["volume_ml"])
      end
      if existing.exists?
        detail = case data["feed_type"]
        when "bottle" then "Bottle #{data['volume_ml']}ml"
        when "breastfeed" then "Breastfeed #{data['breast_side']}"
        when "pump" then "Pump #{data['volume_ml']}ml"
        end
        return { success: true, type: "feeding", message: "#{detail} (already exists, skipped)", skipped: true }
      end

      attrs = {
        baby: @baby,
        user: @user,
        feed_type: data["feed_type"],
        started_at: started
      }

      case data["feed_type"]
      when "bottle"
        attrs[:volume_ml] = data["volume_ml"]
        attrs[:milk_type] = data["milk_type"] || "breast_milk"
        attrs[:formula_brand] = data["formula_brand"]
      when "breastfeed"
        attrs[:breast_side] = data["breast_side"] || "both"
        attrs[:ended_at] = parse_time(data["ended_at"]) if data["ended_at"].present?
      when "pump"
        attrs[:volume_ml] = data["volume_ml"]
        attrs[:milk_type] = "breast_milk"
      end

      attrs[:notes] = data["notes"]
      feeding = Feeding.create!(attrs)

      detail = case data["feed_type"]
      when "bottle" then "Bottle #{data['volume_ml']}ml #{data['milk_type']&.humanize}"
      when "breastfeed" then "Breastfeed #{data['breast_side']} side"
      when "pump" then "Pump #{data['volume_ml']}ml"
      end

      { success: true, type: "feeding", message: detail, record: feeding }
    rescue => e
      { success: false, type: "feeding", message: "Failed: #{e.message}" }
    end

    def create_diaper(data)
      has_time = data["changed_at"].present?
      changed = has_time ? parse_time(data["changed_at"]) : nil
      # For count-based diapers, use date field to set created_at context
      diaper_date = data["date"].present? ? Date.parse(data["date"]) : nil

      # Dedup: only when explicit time is given
      if has_time && @baby.diaper_changes.where(
        changed_at: (changed - 2.minutes)..(changed + 2.minutes),
        diaper_type: data["diaper_type"]
      ).exists?
        return { success: true, type: "diaper", message: "Diaper #{data['diaper_type']} (already exists, skipped)", skipped: true }
      end

      # If no explicit time but has date, set to noon of that date for correct day grouping
      effective_changed_at = changed || (diaper_date ? Time.zone.parse(diaper_date.to_s + " 12:00:00") : nil)

      change = DiaperChange.create!(
        baby: @baby,
        user: @user,
        changed_at: effective_changed_at,
        diaper_type: data["diaper_type"] || "wet",
        stool_color: data["stool_color"],
        consistency: data["consistency"],
        has_rash: data["has_rash"] || false,
        notes: data["notes"]
      )

      type_label = { "wet" => "Wet (pee)", "soiled" => "Soiled (poop)", "both" => "Wet + Soiled", "dry" => "Dry" }
      { success: true, type: "diaper", message: "Diaper #{type_label[data['diaper_type']] || data['diaper_type']}", record: change }
    rescue => e
      { success: false, type: "diaper", message: "Failed: #{e.message}" }
    end

    def create_milestone(data)
      # Dedup: same title + date
      if @baby.milestones.where(title: data["title"], achieved_on: parse_date(data["achieved_on"])).exists?
        return { success: true, type: "milestone", message: "Milestone: #{data['title']} (already exists, skipped)", skipped: true }
      end

      milestone = Milestone.create!(
        baby: @baby,
        user: @user,
        title: data["title"],
        description: data["description"],
        category: data["category"],
        achieved_on: parse_date(data["achieved_on"]),
        notes: data["notes"]
      )
      { success: true, type: "milestone", message: "Milestone: #{data['title']}", record: milestone }
    rescue => e
      { success: false, type: "milestone", message: "Failed: #{e.message}" }
    end

    def create_weight(data)
      # Dedup: same weight on same day
      if @baby.weight_logs.where(recorded_at: Date.current, weight_grams: data["weight_grams"]).exists?
        return { success: true, type: "weight", message: "Weight #{data['weight_grams']}g (already exists, skipped)", skipped: true }
      end

      log = WeightLog.create!(
        baby: @baby,
        user: @user,
        recorded_at: Date.current,
        weight_grams: data["weight_grams"],
        height_cm: data["height_cm"],
        head_circumference_cm: data["head_circumference_cm"],
        measured_by: data["measured_by"],
        notes: data["notes"]
      )
      { success: true, type: "weight", message: "Weight #{data['weight_grams']}g", record: log }
    rescue => e
      { success: false, type: "weight", message: "Failed: #{e.message}" }
    end

    def create_milk_storage(data)
      stored = data["stored_at"].present? ? parse_time(data["stored_at"]) : Time.current
      stash = MilkStash.create!(
        baby: @baby,
        user: @user,
        volume_ml: data["volume_ml"],
        remaining_ml: data["volume_ml"],
        storage_type: data["storage_type"] || "fridge",
        stored_at: stored,
        label: data["label"] || "#{stored.in_time_zone('America/New_York').strftime('%b %d %I:%M %p')} pump",
        notes: data["notes"]
      )
      { success: true, type: "milk_storage", message: "Stored #{data['volume_ml']}ml in #{data['storage_type']}", record: stash }
    rescue => e
      { success: false, type: "milk_storage", message: "Failed: #{e.message}" }
    end
  end
end
