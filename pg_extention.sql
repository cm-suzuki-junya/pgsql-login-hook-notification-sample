CREATE EXTENSION pg_tle;
-- install with aws_common
CREATE EXTENSION aws_lambda CASCADE;

--change 'postgres' to your username
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgtle TO postgres;

SELECT pgtle.install_extension(
  'login_notification',
  '1.0',
  'Notification login success',
$_pgtle_$
  CREATE SCHEMA login_notification;

  CREATE FUNCTION login_notification.hook_function(port pgtle.clientauth_port_subset, status integer)
  RETURNS text AS $$
    DECLARE
      execute_time timestamp;
      context json;
    BEGIN
      execute_time := now();
      
      context := '{"userName": "'|| port.user_name ||'", "timestamp": "'||  to_char(execute_time, 'YYYY-MM-DD HH24:MI:SS') || '"}';
      -- Call lambda function, if login success
      IF status = 0 THEN
        PERFORM aws_lambda.invoke(
            '{{your lambda function arn}}',
            context::json
        );
      SELECT "Login has been notified to administrator";
      END IF;
    END
  $$ LANGUAGE plpgsql;

  --　上記の関数を認証時のフック処理として登録
  SELECT pgtle.register_feature('login_notification.hook_function', 'clientauth');
  REVOKE ALL ON SCHEMA login_notification FROM PUBLIC;
$_pgtle_$,
'{aws_lambda}'
);

CREATE EXTENSION login_notification;


DROP EXTENSION login_notification; SELECT * FROM pgtle.uninstall_extension('login_notification');