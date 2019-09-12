SET      pagesize 0
SET      heading OFF
SET      feedback OFF
SET      verify OFF
SET      linesize 32767
WHENEVER SQLERROR EXIT SQL.SQLCODE
WITH oneday AS
    (
        SELECT
            /*+ materialize */ *
        FROM
            v$diag_alert_ext
        WHERE
            ORIGINATING_TIMESTAMP>systimestamp-1
    )
SELECT
    TO_CHAR(ORIGINATING_TIMESTAMP,'YYYY-MM-DD HH24:MI:SS')
        || ' '
        || message_text
FROM
    oneday
WHERE
    adr_home LIKE '%/&1'
    AND ORIGINATING_TIMESTAMP > systimestamp-60/1440
    AND message_text LIKE '%ORA-%'
    AND message_text NOT LIKE '%result of ORA-609%'
    AND message_text NOT LIKE '%result of ORA-28%'
    AND message_text NOT LIKE '%(ORA-3136)%'
    AND message_text NOT LIKE '%ORA-01013:%';
QUIT;
