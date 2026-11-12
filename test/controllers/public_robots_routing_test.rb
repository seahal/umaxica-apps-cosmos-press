# typed: false
# frozen_string_literal: true

require "test_helper"

class PublicRobotsRoutingTest < ActionDispatch::IntegrationTest
  test "retained publishing surfaces define no Rails robots or sitemap helpers" do
    %i(
      docs_app_robot_path docs_com_robot_path docs_org_robot_path
      help_app_robot_path help_com_robot_path help_org_robot_path
      info_app_robot_path info_com_robot_path info_org_robot_path
      news_app_robot_path news_com_robot_path news_org_robot_path
      docs_app_sitemap_path docs_com_sitemap_path docs_org_sitemap_path
      help_app_sitemap_path help_com_sitemap_path help_org_sitemap_path
      info_app_sitemap_path info_com_sitemap_path info_org_sitemap_path
      news_app_sitemap_path news_com_sitemap_path news_org_sitemap_path
    ).each do |helper|
      assert_not_respond_to self, helper
    end
  end
end
