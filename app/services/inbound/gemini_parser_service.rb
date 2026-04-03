require "net/http"
require "json"

module Inbound
  class GeminiParserService
    MODELS = %w[gemini-2.5-flash gemini-2.5-flash-lite].freeze
    BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"

    SYSTEM_PROMPT = <<~PROMPT
      You are a baby tracking assistant. Parse the user's message into a structured JSON action.

      Return ONLY valid JSON with no markdown formatting, no code fences, no explanation.

      CRITICAL DATE/TIME RULES:
      - ALL time fields MUST be full ISO datetime: "YYYY-MM-DDTHH:MM:SS"
      - If the message contains date headers like "03/26" or "March 26", use that date for all entries below it until the next date header
      - If no date is specified, use the current date provided in the prompt
      - The year is provided in the prompt as current date context
      - "12:05 AM" on "03/27" = "2026-03-27T00:05:00"
      - "3:40 PM" on "03/26" = "2026-03-26T15:40:00"

      Supported actions:
      1. feeding - bottle, breastfeed, or pump
      2. diaper - wet, soiled, both, or dry
      3. milestone - a developmental milestone
      4. weight - weight measurement
      5. milk_storage - store expressed milk
      6. sleep - baby sleep/nap tracking
      7. diary - a diary/journal entry about the baby

      UNSUPPORTED ACTIONS — return unknown for these:
      - Editing, updating, or modifying existing records (e.g. "edit", "update", "change", "modify")
      - Deleting or removing records (e.g. "delete", "remove")
      - Using/consuming from milk storage (e.g. "use 95ml from fridge", "consume storage")
      - Discarding or transferring milk stashes (e.g. "discard expired", "move to fridge")
      - Creating or managing appointments
      - Marking vaccinations as administered
      - Any request that refers to an existing record by date, number, or description
      For these, return: {"action":"unknown","message":"This action is not supported via text. Please use the app to: [describe what they're trying to do]. Supported commands: bottle 90ml, breastfeed left 20min, diaper wet, pump 120ml, weight 3.5kg, milestone first smile"}

      Parse rules:
      - If ml/volume is mentioned with no breastfeed context → bottle feeding (breast_milk unless "formula" mentioned)
      - Time ranges like "2:30-2:50 PM" or duration with "left/right/both" → breastfeed
      - "pumped", "pump", "expressed" → pump (if volume given) or milk_storage (if "stored", "fridge", "freezer" mentioned)
      - "diaper", "pee", "wet", "poop", "soiled", "dirty" → diaper change
      - Diaper counts like "Wet - 3" or "Poop - 3" or "Both - 1" → create MULTIPLE diaper entries, one per count. "Wet - 3" = three separate diaper entries with diaper_type "wet". No time needed (changed_at = null).
      - "Diapers" as a section header means the following lines are diaper entries
      - "milestone", "first time", "first smile", "rolled over" etc → milestone
      - "weight", "weighed", "kg", "lbs", "grams" → weight
      - "stored", "fridge", "freezer", "room temp" → milk_storage
      - "30 (expressed milk) & 65 (formula)" → two bottle feedings: one breast_milk 30ml, one formula 65ml, same started_at
      - "30 ml + 65 formula" → same as above, two separate bottle entries
      - "slept", "nap", "sleep", "woke up" → sleep log
      - "nap 2:00-3:30" or "slept 9pm-6am" → sleep with start/end times
      - "nap 45min" → sleep with duration only
      - "diary", "journal", "dear diary", "note about", "today was", personal reflections about the baby → diary entry
      - Mood detection: "happy", "funny", "sweet", "proud", "sad", or "neutral" based on tone

      JSON response formats (ALL times must be full YYYY-MM-DDTHH:MM:SS):

      Feeding (bottle):
      {"action":"feeding","feed_type":"bottle","volume_ml":90,"milk_type":"breast_milk","formula_brand":null,"started_at":"2026-03-26T13:25:00","notes":null}

      Feeding (breastfeed):
      {"action":"feeding","feed_type":"breastfeed","breast_side":"left","started_at":"2026-03-26T17:10:00","ended_at":"2026-03-26T17:25:00","notes":null}

      Feeding (pump):
      {"action":"feeding","feed_type":"pump","volume_ml":120,"started_at":"2026-03-26T15:00:00","notes":null}

      Diaper:
      {"action":"diaper","diaper_type":"wet","stool_color":null,"consistency":null,"has_rash":false,"changed_at":"2026-03-26T14:00:00","date":"2026-03-26","notes":null}
      For diaper counts without time (e.g. "Wet - 3"), set changed_at to null but ALWAYS set "date" to the date from the message header (e.g. "4/1" = "2026-04-01"). If no date header, use current date.

      Milestone:
      {"action":"milestone","title":"First smile","description":null,"category":"social","achieved_on":"2026-03-26","notes":null}

      Weight:
      {"action":"weight","weight_grams":3500,"height_cm":null,"head_circumference_cm":null,"measured_by":null,"notes":null}

      Milk storage:
      {"action":"milk_storage","volume_ml":120,"storage_type":"fridge","stored_at":"2026-04-01T23:30:00","label":null,"notes":null}
      IMPORTANT: Always include stored_at with full datetime from the message. Use the date header context.

      Sleep:
      {"action":"sleep","sleep_type":"nap","started_at":"2026-04-01T14:00:00","ended_at":"2026-04-01T15:30:00","location":null,"notes":null}
      sleep_type: "nap" for daytime, "night" for overnight sleep. location: crib, bassinet, stroller, car, arms, other.

      Diary:
      {"action":"diary","content":"Today baby laughed for the first time when daddy made funny faces!","mood":"funny","entry_date":"2026-04-01"}
      mood must be one of: happy, funny, sweet, proud, sad, neutral. Infer mood from the tone of the message.

      If the message contains multiple entries, return a JSON array of ALL actions.
      If you cannot parse the message, return: {"action":"unknown","message":"Could not understand. Try: bottle 90ml, diaper wet, nap 2-3pm, pump 120ml"}
    PROMPT

    def initialize(message_text, timezone: "America/New_York")
      @message = message_text
      @timezone = timezone
    end

    def parse
      response = call_gemini
      parse_response(response)
    rescue => e
      Rails.logger.error("Gemini parse error: #{e.message}")
      [ { "action" => "unknown", "message" => "Failed to parse: #{e.message}" } ]
    end

    private

    def call_gemini
      api_key = ENV.fetch("GEMINI_API_KEY")

      body = {
        system_instruction: { parts: [ { text: SYSTEM_PROMPT } ] },
        contents: [ { parts: [ { text: "Current date: #{Date.current}. Year: #{Date.current.year}. Timezone: #{@timezone}. Parse this message:\n\n#{@message}" } ] } ],
        generationConfig: { temperature: 0.1, responseMimeType: "application/json" }
      }

      # Try each model with retry
      MODELS.each do |model|
        uri = URI("#{BASE_URL}/#{model}:generateContent?key=#{api_key}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = body.to_json

        2.times do |attempt|
          response = http.request(request)
          data = JSON.parse(response.body)

          if response.code.to_i == 200 && !data["error"]
            Rails.logger.info("Gemini: used model #{model}")
            return data
          end

          Rails.logger.warn("Gemini #{model} attempt #{attempt + 1}: #{response.code} — #{data.dig("error", "message")&.truncate(100)}")
          sleep(1) if attempt == 0 && response.code.to_i >= 500
        end
      end

      # All models failed
      { "candidates" => [] }
    end

    def parse_response(response)
      parts = response.dig("candidates", 0, "content", "parts") || []
      text = nil
      parts.reverse_each do |part|
        next if part["thought"] == true
        if part["text"].present?
          text = part["text"]
          break
        end
      end

      return [ { "action" => "unknown", "message" => "Empty AI response" } ] unless text

      text = text.gsub(/```json\s*/i, "").gsub(/```\s*/, "").strip

      parsed = JSON.parse(text)
      parsed.is_a?(Array) ? parsed : [ parsed ]
    rescue JSON::ParserError => e
      Rails.logger.error("Gemini JSON parse error: #{e.message} — raw: #{text&.truncate(300)}")
      [ { "action" => "unknown", "message" => "Could not parse AI response" } ]
    end
  end
end
