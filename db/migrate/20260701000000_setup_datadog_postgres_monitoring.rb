# Provision the database objects that Datadog Database Monitoring (Postgres)
# needs: the pg_stat_statements extension and a datadog schema holding the
# explain_statement helper. Running this in the release-phase db:migrate keeps
# the monitoring setup in code and recreates it automatically after a database
# swap, so no manual pg:psql step is required.
#
# On Heroku production plans the DATABASE_URL credential already carries
# pg_monitor, so no extra role or grant is needed here. The statements are
# idempotent and guarded so they never break non-Postgres or unprivileged
# (development/CI) databases.
class SetupDatadogPostgresMonitoring < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    return unless postgres?

    begin
      execute 'CREATE EXTENSION IF NOT EXISTS pg_stat_statements'
    rescue => e
      warn "[datadog] skipping pg_stat_statements extension: #{e.message}"
    end

    execute 'CREATE SCHEMA IF NOT EXISTS datadog'
    execute <<~SQL
      CREATE OR REPLACE FUNCTION datadog.explain_statement(
        l_query text,
        OUT explain json
      )
      RETURNS SETOF json AS
      $$
      DECLARE
        curs REFCURSOR;
        plan json;
      BEGIN
        SET TRANSACTION READ ONLY;
        OPEN curs FOR EXECUTE pg_catalog.concat('EXPLAIN (FORMAT JSON) ', l_query);
        FETCH curs INTO plan;
        CLOSE curs;
        RETURN QUERY SELECT plan;
      END;
      $$
      LANGUAGE 'plpgsql'
      RETURNS NULL ON NULL INPUT
      SECURITY DEFINER;
    SQL
  end

  def down
    return unless postgres?

    execute 'DROP SCHEMA IF EXISTS datadog CASCADE'
  end

  private

  def postgres?
    connection.adapter_name =~ /postgres/i
  end
end
