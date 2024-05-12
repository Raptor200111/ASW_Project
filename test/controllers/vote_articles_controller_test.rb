require "test_helper"

class VoteArticlesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get vote_articles_index_url
    assert_response :success
  end

  test "should get show" do
    get vote_articles_show_url
    assert_response :success
  end

  test "should get new" do
    get vote_articles_new_url
    assert_response :success
  end

  test "should get edit" do
    get vote_articles_edit_url
    assert_response :success
  end
end
