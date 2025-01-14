require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "dexter"

$url = ENV["DEXTER_URL"] || "postgres:///dexter_test"
$conn = PG::Connection.new($url)
$conn.exec <<-SQL
SET client_min_messages = warning;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS hypopg;
DROP TABLE IF EXISTS posts CASCADE;
CREATE TABLE posts (
  id int,
  blog_id int,
  user_id int,
  json json,
  jsonb jsonb,
  hstore hstore
);
INSERT INTO posts (SELECT n AS id, n % 1000 AS blog_id, n % 10 AS user_id FROM generate_series(1, 100000) n);
CREATE VIEW posts_view AS SELECT id AS view_id FROM posts;
CREATE MATERIALIZED VIEW posts_materialized AS SELECT * FROM posts;
ANALYZE posts;

DROP SCHEMA IF EXISTS "Bar" CASCADE;
CREATE SCHEMA "Bar";
CREATE TABLE "Bar"."Foo"("Id" int);
INSERT INTO "Bar"."Foo" SELECT * FROM generate_series(1, 100000);
ANALYZE "Bar"."Foo";
SQL

class Minitest::Test
  def assert_index(statement, index, options = nil)
    assert_dexter_output "Index found: #{index}", ["-s", statement] + options.to_s.split(" ")
  end

  def assert_no_index(statement, options = nil)
    assert_dexter_output "No new indexes found", ["-s", statement] + options.to_s.split(" ")
  end

  def dexter_run(options)
    dexter = Dexter::Client.new([$url] + options + ["--log-level", "debug2", "--log-sql"])
    ex = nil
    stdout, _ = capture_io do
      begin
        dexter.perform
      rescue => e
        ex = e
      end
    end
    puts stdout if ENV["VERBOSE"]
    raise ex if ex
    stdout
  end

  def assert_dexter_output(expected, options)
    assert_match expected, dexter_run(options)
  end

  def assert_dexter_error(expected, options)
    error = assert_raises do
      dexter_run(options)
    end
    assert_match expected, error.message
  end

  def server_version
    execute("SHOW server_version_num").first["server_version_num"].to_i / 10000
  end

  def execute(statement)
    $conn.exec(statement)
  end
end
