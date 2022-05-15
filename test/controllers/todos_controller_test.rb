require "test_helper"

class TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @todo = todos(:one)
  end

  test "should get index" do
    get todos_url, as: :json
    assert_response :success
  end

  test "should create todo" do
    assert_difference("Todo.count") do
      post todos_url, params: { todo: { description: @todo.description, end_date: @todo.end_date, instance_time_span: @todo.instance_time_span, name: @todo.name, project_id: @todo.project_id, repeat: @todo.repeat, repeat_period: @todo.repeat_period, repeat_times: @todo.repeat_times, start_date: @todo.start_date, time_span: @todo.time_span } }, as: :json
    end

    assert_response :created
  end

  test "should show todo" do
    get todo_url(@todo), as: :json
    assert_response :success
  end

  test "should update todo" do
    patch todo_url(@todo), params: { todo: { description: @todo.description, end_date: @todo.end_date, instance_time_span: @todo.instance_time_span, name: @todo.name, project_id: @todo.project_id, repeat: @todo.repeat, repeat_period: @todo.repeat_period, repeat_times: @todo.repeat_times, start_date: @todo.start_date, time_span: @todo.time_span } }, as: :json
    assert_response :success
  end

  test "should destroy todo" do
    assert_difference("Todo.count", -1) do
      delete todo_url(@todo), as: :json
    end

    assert_response :no_content
  end
end
