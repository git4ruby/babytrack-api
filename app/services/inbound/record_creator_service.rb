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
      Time.zone.parse("#{Date.current} #{time_str}")
    rescue
      Time.current
    end

    def create_feeding(data)
      attrs = {
        baby: @baby,
        user: @user,
        feed_type: data["feed_type"],
        started_at: parse_time(data["started_at"]),
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
      change = DiaperChange.create!(
        baby: @baby,
        user: @user,
        changed_at: parse_time(data["changed_at"]),
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
      milestone = Milestone.create!(
        baby: @baby,
        user: @user,
        title: data["title"],
        description: data["description"],
        category: data["category"],
        achieved_on: data["achieved_on"] || Date.current,
        notes: data["notes"]
      )
      { success: true, type: "milestone", message: "Milestone: #{data['title']}", record: milestone }
    rescue => e
      { success: false, type: "milestone", message: "Failed: #{e.message}" }
    end

    def create_weight(data)
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
      stash = MilkStash.create!(
        baby: @baby,
        user: @user,
        volume_ml: data["volume_ml"],
        remaining_ml: data["volume_ml"],
        storage_type: data["storage_type"] || "fridge",
        stored_at: Time.current,
        label: data["label"] || "#{Time.current.strftime('%b %d %I:%M %p')} pump",
        notes: data["notes"]
      )
      { success: true, type: "milk_storage", message: "Stored #{data['volume_ml']}ml in #{data['storage_type']}", record: stash }
    rescue => e
      { success: false, type: "milk_storage", message: "Failed: #{e.message}" }
    end
  end
end
