-- $Id$
-- written by Helmut K. C. Tessarek, 30.05.2007

-- To create the SQL procedure:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -f bphr.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "call bphr"
--    db2 "call bphr_all"
--    
-- Procedures:
--    bphr	shows the bufferpool hit ratio of the actual database	
--    bphr_all	shows the bufferpool hit ratio of all active databases within the instance

DROP PROCEDURE bphr@
DROP PROCEDURE bphr_all@

CREATE PROCEDURE bphr
()
SPECIFIC tessus_bphr
LANGUAGE SQL
DYNAMIC RESULT SETS 1
BEGIN
  DECLARE res CURSOR WITH RETURN FOR
WITH bp_snap (snapshot_timestamp, database, bufferpool, bp_hr, data_hr, idx_hr, page_clean_ratio )
AS
(
    SELECT 
	snapshot_timestamp,
	substr(db_name,1,16),
	substr(bp_name,1,32),
	CASE 
	  WHEN ((pool_data_p_reads > 0 or pool_index_p_reads > 0) and (pool_data_l_reads > 0 or pool_index_l_reads > 0))
	  THEN
	      decimal( ((1- (double(pool_data_p_reads + pool_index_p_reads)/double(pool_data_l_reads + pool_index_l_reads+1)) ) * 100.0),3,1 )
	  ELSE
	      NULL
	END CASE,
	cast(
		(cast(
			pool_data_l_reads  - pool_data_p_reads 
		as double)*100.0)/(pool_data_l_reads+1) 
	as decimal(3,1)),
	cast(
		(cast(
			pool_index_l_reads - pool_index_p_reads 
		as double)*100.0)/(pool_index_l_reads+1) 
	as decimal(3,1)),
	cast(
		(cast(
			pool_async_data_writes + pool_async_index_writes 
		as double)*100.0)/(pool_data_writes+pool_index_writes+1) 
	as decimal(3,1))
    FROM table(snapshot_bp('',-1)) as BP
    ORDER BY 2,3
)
SELECT snapshot_timestamp, database, bufferpool, bp_hr, data_hr, idx_hr FROM bp_snap;

  OPEN res;
END@

CREATE PROCEDURE bphr_all
()
SPECIFIC tessus_bphr_all
LANGUAGE SQL
DYNAMIC RESULT SETS 1
BEGIN
  DECLARE res CURSOR WITH RETURN FOR
WITH bp_snap (snapshot_timestamp, database, bufferpool, bp_hr, data_hr, idx_hr, page_clean_ratio )
AS
(
    SELECT 
	snapshot_timestamp,
	substr(db_name,1,16),
	substr(bp_name,1,32),
	CASE 
	  WHEN ((pool_data_p_reads > 0 or pool_index_p_reads > 0) and (pool_data_l_reads > 0 or pool_index_l_reads > 0))
	  THEN
	      decimal( ((1- (double(pool_data_p_reads + pool_index_p_reads)/double(pool_data_l_reads + pool_index_l_reads+1)) ) * 100.0),3,1 )
	  ELSE
	      NULL
	END CASE,
	cast(
		(cast(
			pool_data_l_reads  - pool_data_p_reads 
		as double)*100.0)/(pool_data_l_reads+1) 
	as decimal(3,1)),
	cast(
		(cast(
			pool_index_l_reads - pool_index_p_reads 
		as double)*100.0)/(pool_index_l_reads+1) 
	as decimal(3,1)),
	cast(
		(cast(
			pool_async_data_writes + pool_async_index_writes 
		as double)*100.0)/(pool_data_writes+pool_index_writes+1) 
	as decimal(3,1))
    FROM table(snapshot_bp(cast(null as varchar(128)),-1)) as BP
    ORDER BY 2,3
)
SELECT snapshot_timestamp, database, bufferpool, bp_hr, data_hr, idx_hr FROM bp_snap;

  OPEN res;
END@
