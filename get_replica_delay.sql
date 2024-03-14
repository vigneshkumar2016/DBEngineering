-- Author: Vignesh
-- Compatibility: PostgreSQL
-- This will retuen result based on the replica delay.
SELECT
CASE WHEN (select pg_is_in_recovery()) = 't' THEN
    CASE WHEN status::text <> 'streaming' AND status::text = 'catchup' THEN
            'streaming catching up - yes'
    ELSE
        CASE WHEN pg_last_wal_receive_lsn()::pg_lsn <> pg_last_wal_replay_lsn()::pg_lsn THEN
            'wal recieve lsn and replay lsn does not match - no'
        ELSE
            CASE WHEN ROUND(EXTRACT(epoch FROM now()::timestamp) - EXTRACT(epoch FROM latest_end_time::timestamp))::int >15 THEN -- adjust your threshold here accordingly ( adjust the (15)s accordingly )
                CASE WHEN regexp_replace((select version()::varchar(15)), '[^0-9]+', '', 'g')::varchar(2)::int = 12 THEN
                    'replica with 15 secs delay'
                ELSE
                    CASE WHEN latest_end_lsn::pg_lsn = written_lsn::pg_lsn THEN
                        'replica with delay gt 15 secs'
                    ELSE
                        'no replica with delay greater than 15s'
                    END
                END
            ELSE
                'replica with less than 15s delay'
            END
        END
    END
END as replica_state
from pg_stat_wal_receiver;
