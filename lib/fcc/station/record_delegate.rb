require 'active_support/inflector'

module FCC
  module Station
    class RecordDelegate
      def initialize(result)
        @result = result
      end

      def method_missing(m, *args, &block)
        return find_result(@result, m) unless @result.is_a?(Array)
        return find_result(@result.first, m) if @result.size == 1

        filtered_results = @result.filter { |result|
          result[:status] == 'LIC' # Licensed only, no construction permits
        }

        filtered_results = filtered_results.collect { |res|
          find_result(res, m)
        }.uniq

        filtered_results.size == 1 ? filtered_results.first : filtered_results
      end

      def to_json
        return {}.tap do |record|
          [Station::Result::EXTENDED_ATTRIBUTES | Station::Result::BASIC_ATTRIBUTES].flatten.each do |attr|
            record[attr.to_sym] = send(attr.to_sym)
          end

          %i[contact owner community].each do |attr|
            result = send(attr.to_sym)
            next unless result

            record[attr] ||= if result.is_a?(Struct)
                               result.to_h.compact
                             elsif result.is_a?(Array) && result.compact.size > 0
                               result
                             elsif result.present?
                               result.to_s
                             end
          end
        end
      end

      def has_data?
        @result
      end

      def id
        super || send(:fcc_id)
      end

      def frequency
        super&.to_f
      end

      def rf_channel
        super || send(:channel)
      end

      def operating_hours
        super&.downcase
      end

      def owner
        @owner ||= begin
          contact = Contact.new(
            name: party_name || licensed_to,
            address: party_address_1, 
            address2: party_address_2, 
            city: (party_city || city), 
            state: (party_state || state), 
            zip_code: party_zip_1,
            country: country,
            phone: party_phone
          )

          contact if contact.to_h.compact.any?
        end
      end

      def community
        @community ||= begin
          community = Community.new(city: community_city || city, state: community_state || state, country: country)
          community if community.to_h.compact.any?
        end
      end

      def contact
        contact = main_studio_contact

        return unless contact
        @contact ||= begin
          contact = Contact.new(name: contact['contactName'], title: contact['contactTitle'], address: contact['contactAddress1'], address2: contact['contactAddress2'], city: contact['contactCity'], state: contact['contactState'], zip_code: contact['contactZip'], phone: contact['contactPhone'], fax: contact['contactFax'], email: contact['contactEmail'], website: contact['contactWebsite'])
          contact if contact.to_h.compact.any?
        end
      end

      def inspect
        "<RecordDelegate:[#{band}] #{frequency} #{call_sign} — #{community&.city} #{community&.state} />"
      end

      private

      def find_key(result, name)
        result&.keys&.detect { |d| name.to_s == d.to_s } || result&.keys&.detect { |d| name.to_s == d.to_s.underscore }
      end

      def find_result(result, name)
        matched_key = find_key(result, name)

        if matched_key
          result[matched_key]
        else
          nil
        end
      end
    end
  end
end