-- Author: Vignesh
-- Compatibility: PostgreSQL
-- This will provide the wal file statistics to understand and analyze how long its been modified by system.
SELECT
	CASE WHEN pg_is_in_recovery()::BOOL is True THEN 'Secondary' ELSE 'Primary' END as node_status,
	inet_client_addr()::inet as node_ip, --- use inet_server_addr() if you are not using containerized postgres
	name as walfilename,
	pg_size_pretty(walsize) as walsize,
    CASE
        WHEN age_diff >= 86400 THEN ROUND(age_diff / 86400)::int || ' days'
        WHEN age_diff >= 3600 THEN ROUND(age_diff / 3600)::int || ' hours'
        WHEN age_diff >= 60 THEN ROUND(age_diff / 60)::int || ' minutes'
        ELSE age_diff::int || ' seconds'
    END AS wal_modified_since
FROM
    (
      SELECT name, 
		  size as walsize,
		  EXTRACT(EPOCH FROM now() - modification) AS age_diff FROM pg_ls_waldir() 
		  where name ~ '^.{24}$' OR name ~ '^.{24}\.partial$' --filter only wal files that are reliable.
		  ORDER BY modification DESC -- show the recent modified walfile at the first.
      LIMIT 10  -- disable or comment this if you do not want to limit records that are returned.
    ) 
AS age_data;
