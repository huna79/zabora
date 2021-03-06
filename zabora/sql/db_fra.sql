SET      pagesize 0
SET      heading OFF
SET      feedback OFF
SET      verify OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
SELECT
    CASE
        WHEN cant = 0  THEN 0
        ELSE (
            SELECT
                DECODE(nvl(space_used,0),0,0,((space_used - space_reclaimable) / space_limit) * 100)
            FROM
                v$recovery_file_dest
        )
    END
FROM
    (
        SELECT
            COUNT(*) cant
        FROM
            v$recovery_file_dest
    );
QUIT;
