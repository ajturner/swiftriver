class InitialSchema < ActiveRecord::Migration
  def self.up
    create_table "alert_viewings", :force => true do |t|
      t.column "user_id", :integer
      t.column "reviewer_alert_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    add_index "alert_viewings", ["user_id"], :name => "index_alert_viewings_on_user_id"
    add_index "alert_viewings", ["reviewer_alert_id"], :name => "index_alert_viewings_on_reviewer_alert_id"

    create_table "filters", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "name", :string, :limit => 80
      t.column "aliases", :string
      t.column "title", :string, :limit => 80
      t.column "center_location_id", :integer
      t.column "radius", :integer
      t.column "conditions", :text
      t.column "zoom_level", :integer
      t.column "state", :string, :limit => 2
      t.column "country_code", :string, :limit => 2
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "invalid_locations", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "text", :string, :limit => 80
      t.column "unknown", :boolean
    end

    add_index "invalid_locations", ["text"], :name => "index_invalid_locations_on_text", :unique => true

    create_table "location_aliases", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "text", :string, :limit => 80
      t.column "location_id", :integer
    end

    add_index "location_aliases", ["text"], :name => "index_location_aliases_on_text", :unique => true
    add_index "location_aliases", ["location_id"], :name => "index_location_aliases_on_location_id"

    create_table "locations", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "address", :string
      t.column "country_code", :string, :limit => 10
      t.column "administrative_area", :string, :limit => 80
      t.column "sub_administrative_area", :string, :limit => 80
      t.column "locality", :string, :limit => 80
      t.column "thoroughfare", :string, :limit => 80
      t.column "postal_code", :string, :limit => 25
      t.column "point", :point, :null => false
      t.column "geo_source_id", :integer
      t.column "filter_list", :string
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    add_index "locations", ["point"], :name => "index_locations_on_point", :spatial=> true 

    create_table "report_filters", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "report_id", :integer
      t.column "filter_id", :integer
    end

    add_index "report_filters", ["report_id"], :name => "index_report_filters_on_report_id"
    add_index "report_filters", ["filter_id"], :name => "index_report_filters_on_filter_id"

    create_table "report_tags", :force => true do |t|
      t.column "report_id", :integer
      t.column "tag_id", :integer
    end

    add_index "report_tags", ["report_id"], :name => "index_report_tags_on_report_id"
    add_index "report_tags", ["tag_id"], :name => "index_report_tags_on_tag_id"

    create_table "reporters", :force => true do |t|
      t.column "type", :string, :limit => 30
      t.column "uniqueid", :string, :limit => 80
      t.column "name", :string, :limit => 80
      t.column "screen_name", :string, :limit => 80
      t.column "profile_image_url", :string, :limit => 200
      t.column "followers_count", :integer
      t.column "profile_location", :string, :limit => 80
      t.column "location_id", :integer
      t.column "home_location_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    add_index "reporters", ["uniqueid", "type"], :name => "index_reports_on_uniqueid_and_type", :unique => true

    create_table "reports", :force => true do |t|
      t.column "type", :string, :limit => 30
      t.column "source", :string, :limit => 30
      t.column "uniqueid", :string, :limit => 30
      t.column "title", :string
      t.column "body", :string, :limit => 65536
      t.column "score", :integer
      t.column "source_url", :string
      t.column "link_url", :string
      t.column "location_accuracy", :integer
      t.column "reporter_id", :integer
      t.column "location_id", :integer
      t.column "parent_report_id", :integer
      t.column "reviewer_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "assigned_at", :datetime
      t.column "reviewed_at", :datetime
      t.column "dismissed_at", :datetime
      t.column "is_chatter", :boolean, :default => false
    end

    add_index "reports", ["created_at"], :name => "index_reports_on_created_at"
    add_index "reports", ["reviewer_id"], :name => "index_reports_on_reviewer_id"
    add_index "reports", ["type"], :name => "index_reports_on_type"

    create_table "reviewer_alerts", :force => true do |t|
      t.column "text", :string
      t.column "user_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end

    create_table "statistics", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "name", :string
      t.column "created_at", :datetime
      t.column "sort", :integer, :default => 0
      t.column "string_value", :string
      t.column "integer_value", :integer
      t.column "decimal_value", :integer, :limit => 10
    end

    create_table "tags", :force => true do |t|
      t.column "pattern", :string, :limit => 30
      t.column "description", :string, :limit => 80
      t.column "score", :integer
    end

    create_table "users", :options=>'ENGINE=MyISAM', :force => true do |t|
      t.column "first_name", :string, :limit => 80
      t.column "last_name", :string, :limit => 80
      t.column "url", :string, :limit => 120
      t.column "api_key", :string, :limit => 40
      t.column "email", :string, :limit => 80
      t.column "verified", :boolean
      t.column "authorized", :boolean
      t.column "day_query_limit", :integer
      t.column "day_update_limit", :integer
      t.column "day_query_count", :integer, :default => 0
      t.column "day_update_count", :integer, :default => 0
      t.column "query_count", :integer, :default => 0
      t.column "update_count", :integer, :default => 0
      t.column "last_query_at", :datetime
      t.column "last_update_at", :datetime
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
      t.column "type", :string, :limit => 30
      t.column "crypted_password", :string, :limit => 40
      t.column "salt", :string, :limit => 40
      t.column "remember_token", :string, :limit => 40
      t.column "remember_token_expires_at", :datetime
      t.column "activation_code", :string, :limit => 40
      t.column "activated_at", :datetime
      t.column "is_admin", :boolean, :default => false
      t.column "is_terminated", :boolean, :default => false
      t.column "reports_count", :integer, :default => 0
    end

    add_index "users", ["api_key"], :name => "index_users_on_api_key", :unique => true
    add_index "users", ["email"], :name => "index_users_on_email", :unique => true
    add_index "users", ["type"], :name => "index_users_on_type"
    add_index "users", ["reports_count"], :name => "index_users_on_reports_count"
  end
end