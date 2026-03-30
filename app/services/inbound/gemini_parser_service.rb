require "net/http"
require "json"

module Inbound
  class GeminiParserService
    API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    SYSTEM_PROMPT = <<~PROMPT
      You are a baby tracking assistant. Parse the user's message into a structured JSON action.

      Return ONLY valid JSON with no markdown formatting, no code fences, no explanation.

      Supported actions:
      1. feeding - bottle, breastfeed, or pump
      2. diaper - wet, soiled, both, or dry
      3. milestone - a developmental milestone
      4. weight - weight measurement
      5. milk_storage - store expressed milk

      Parse rules:
      - If ml/volume is mentioned with no breastfeed context → bottle feeding (breast_milk unless "formula" mentioned)
      - Time ranges like "2:30-2:50" or duration like "20min" with "left/right/both" or no volume → breastfeed
      - "pumped", "pump", "expressed" → pump (if volume given) or milk_storage (if "stored", "fridge", "freezer" mentioned)
      - "diaper", "pee", "wet", "poop", "soiled", "dirty" → diaper change
      - "milestone", "first time", "first smile", "rolled over" etc → milestone
      - "weight", "weighed", "kg", "lbs", "grams" → weight
      - "stored", "fridge", "freezer", "room temp" → milk_storage
      - Default time is now if not specified

      JSON response formats:

      Feeding (bottle):
      {"action":"feeding","feed_type":"bottle","volume_ml":90,"milk_type":"breast_milk","formula_brand":null,"started_at":"HH:MM","notes":null}

      Feeding (breastfeed):
      {"action":"feeding","feed_type":"breastfeed","breast_side":"left","started_at":"HH:MM","ended_at":"HH:MM","notes":null}

      Feeding (pump):
      {"action":"feeding","feed_type":"pump","volume_ml":120,"started_at":"HH:MM","notes":null}

      Diaper:
      {"action":"diaper","diaper_type":"wet","stool_color":null,"consistency":null,"has_rash":false,"changed_at":"HH:MM","notes":null}

      Milestone:
      {"action":"milestone","title":"First smile","description":null,"category":"social","achieved_on":"YYYY-MM-DD","notes":null}

      Weight:
      {"action":"weight","weight_grams":3500,"height_cm":null,"head_circumference_cm":null,"measured_by":null,"notes":null}

      Milk storage:
      {"action":"milk_storage","volume_ml":120,"storage_type":"fridge","label":null,"notes":null}

      If the message contains multiple entries (e.g. "bottle 90ml then diaper wet"), return a JSON array of actions.
      If you cannot parse the message, return: {"action":"unknown","message":"Could not understand. Try: bottle 90ml, diaper wet, pump 120ml"}
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
      [{ "action" => "unknown", "message" => "Failed to parse: #{e.message}" }]
    end

    private

    def call_gemini
      api_key = ENV.fetch("GEMINI_API_KEY")
      uri = URI("#{API_URL}?key=#{api_key}")

      body = {
        system_instruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{ parts: [{ text: "Current date: #{Date.current}. Timezone: #{@timezone}. Parse this: #{@message}" }] }],
        generationConfig: { temperature: 0.1, responseMimeType: "application/json" }
      }

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)
      JSON.parse(response.body)
    end

    def parse_response(response)
      # Gemini 2.5 may return multiple parts (thinking + response)
      # Find the last non-thought text part
      parts = response.dig("candidates", 0, "content", "parts") || []
      text = nil
      parts.reverse_each do |part|
        next if part["thought"] == true
        if part["text"].present?
          text = part["text"]
          break
        end
      end

      return [{ "action" => "unknown", "message" => "Empty AI response" }] unless text

      # Strip markdown code fences if present
      text = text.gsub(/```json\s*/i, "").gsub(/```\s*/, "").strip

      parsed = JSON.parse(text)
      parsed.is_a?(Array) ? parsed : [parsed]
    rescue JSON::ParserError => e
      Rails.logger.error("Gemini JSON parse error: #{e.message} — raw: #{text&.truncate(300)}")
      [{ "action" => "unknown", "message" => "Could not parse AI response" }]
    end
  end
end
