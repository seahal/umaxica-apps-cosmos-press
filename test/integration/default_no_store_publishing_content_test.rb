# typed: false
# frozen_string_literal: true

require "test_helper"

# Info, Docs, News, and Help entry APIs opt into public caching from the action, so they keep
# `public`, `max-age`, validators, and `304` revalidation without `no-store`.
class DefaultNoStorePublishingContentTest < ActionDispatch::IntegrationTest
  test "Info app BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("info.app.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Info com BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("info.com.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Info org BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("info.org.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Docs app BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("docs.app.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Docs com BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("docs.com.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Docs org BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("docs.org.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "News app BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("news.app.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "News com BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("news.com.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "News org BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("news.org.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Help app BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("help.app.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Help com BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("help.com.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end

  test "Help org BareController entries index keeps its explicit public cache opt-in and revalidates" do
    host!("help.org.localhost")

    get("/api/v0/entries", params: { locale: "ja" })

    assert_response :success
    cache_control = response.headers.fetch("Cache-Control").split(", ")

    assert_includes cache_control, "public"
    assert_includes cache_control, "max-age=60"
    assert_not_includes cache_control, "no-store"
    etag = response.headers.fetch("ETag")

    get("/api/v0/entries", params: { locale: "ja" }, headers: { "If-None-Match" => etag })

    assert_response :not_modified
    assert_empty response.body
  end
end
