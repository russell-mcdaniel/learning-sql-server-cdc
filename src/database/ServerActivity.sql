-- ================================================================================
-- SERVER REQUESTS, PROCEDURE PERFORMANCE DATA, QUERY PERFORMANCE DATA
-- ================================================================================
use master;
GO

--with xmlnamespaces
--	(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
select
	s.session_id																		as session_id,
	db_name(r.database_id)																as database_name,
	s.host_name																			as host_name,
	s.program_name																		as program_name,
	r.start_time																		as start_time,
	r.status																			as status,
--	r.blocking_session_id																as blocking_session_id,
	r.wait_type																			as wait_type,
	r.wait_time																			as wait_time,
	r.total_elapsed_time																as total_elapsed_time,
	r.cpu_time																			as cpu_time,
	r.writes																			as writes,
	r.reads																				as reads,
	r.logical_reads																		as logical_reads,
--	cast(qmg.query_cost as decimal(12,6))												as query_cost,
--	qmg.requested_memory_kb																as req_kb,
--	qmg.granted_memory_kb																as grant_kb,
--	qmg.used_memory_kb																	as used_kb,
--	qmg.max_used_memory_kb																as max_kb,
	substring(t.text, r.statement_start_offset / 2 + 1, datalength(t.text))				as query_text,
--	p.query_plan.value(N'(/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/ParameterList/ColumnReference[@Column="@UserAccountKey"]/@ParameterCompiledValue)[1]', N'nvarchar(100)')
--																						as es_user_key,
	p.query_plan																		as query_plan
--	st.transaction_id																	as transaction_id,
--	at.transaction_begin_time															as transaction_begin_time,
--	dt.database_transaction_log_record_count											as tx_log_record_count
--	r.percent_complete																	as percent_complete
from
	sys.dm_exec_sessions s
inner join
	sys.dm_exec_requests r
on
	r.session_id = s.session_id
--left outer join
--	sys.dm_exec_query_memory_grants qmg on qmg.session_id = s.session_id and qmg.request_id = r.request_id
--left outer join
--	sys.dm_tran_session_transactions st on st.session_id = s.session_id
--left outer join
--	sys.dm_tran_active_transactions at on at.transaction_id = st.transaction_id
--left outer join
--	sys.dm_tran_database_transactions dt on dt.transaction_id = st.transaction_id and dt.database_id = s.database_id
outer apply
	sys.dm_exec_sql_text(r.sql_handle) t
outer apply
	sys.dm_exec_query_plan(r.plan_handle) p
where
	s.session_id > 50;
GO

select
	s.last_execution_time																as ExTimeLast,
	s.execution_count																	as ExCount,
	cast(round(s.total_elapsed_time / 1000.0, 0) as bigint)								as TimeTotal,
	cast(round(s.total_elapsed_time / 1000.0 / s.execution_count, 1) as decimal(9,1))	as TimeAvg,
	cast(round(s.last_elapsed_time / 1000.0, 0) as bigint)								as TimeLast,
	cast(round(s.max_elapsed_time / 1000.0, 0) as bigint)								as TimeMax,
	cast(round(s.total_worker_time / 1000.0, 0) as bigint)								as WorkTotal,
	cast(round(s.total_worker_time / 1000.0 / s.execution_count, 1) as decimal(9,1))	as WorkAvg,
	cast(round(s.last_worker_time / 1000.0, 0) as bigint)								as WorkLast,
	cast(round(s.max_worker_time / 1000.0, 0) as bigint)								as WorkMax,
	s.total_logical_reads																as Reads,
	cast(round(1.0 * s.total_logical_reads / s.execution_count, 0) as bigint)			as ReadsAvg,
	s.last_logical_reads																as ReadsLast,
	s.max_logical_reads																	as ReadsMax,
	s.total_physical_reads																as ReadsP,
	cast(round(1.0 * s.total_physical_reads / s.execution_count, 0) as bigint)			as ReadsAvgP,
	s.last_physical_reads																as ReadsLastP,
	s.max_physical_reads																as ReadsMaxP,
	s.total_logical_writes																as Writes,
	cast(round(1.0 * s.total_logical_writes / s.execution_count, 0) as bigint)			as WritesAvg,
	s.last_logical_writes																as WritesLast,
	s.max_logical_writes																as WritesMax,
	case s.database_id
		when 32767 then object_name(s.object_id)
		else object_name(s.object_id, s.database_id)
	end																					as ProcedureName,
	case s.database_id
		when 32767 then object_schema_name(s.object_id)
		else object_schema_name(s.object_id, s.database_id)
	end																					as SchemaName,
	case s.database_id
		when 32767 then N'resource'
		else db_name(s.database_id)
	end																					as DatabaseName
--	'dbcc freeproccache(0x' + convert(varchar(100), s.plan_handle, 2) + ');'			as ToClear
--	p.query_plan																		as QueryPlan
from
	(
		-- Stored procedures can have more than one plan, so aggregate by object and
		-- provide the totals. The plan handle returned is arbitrary.
		select
			s.database_id																as database_id,
			s.object_id																	as object_id,
			max(s.last_execution_time)													as last_execution_time,
			sum(s.execution_count)														as execution_count,
			sum(s.total_elapsed_time)													as total_elapsed_time,
			max(s.last_elapsed_time)													as last_elapsed_time,
			max(s.max_elapsed_time)														as max_elapsed_time,
			sum(s.total_worker_time)													as total_worker_time,
			max(s.last_worker_time)														as last_worker_time,
			max(s.max_worker_time)														as max_worker_time,
			sum(s.total_logical_reads)													as total_logical_reads,
			max(s.last_logical_reads)													as last_logical_reads,
			max(s.max_logical_reads)													as max_logical_reads,
			sum(s.total_physical_reads)													as total_physical_reads,
			max(s.last_physical_reads)													as last_physical_reads,
			max(s.max_physical_reads)													as max_physical_reads,
			sum(s.total_logical_writes)													as total_logical_writes,
			max(s.last_logical_writes)													as last_logical_writes,
			max(s.max_logical_writes)													as max_logical_writes,
			max(s.plan_handle)															as plan_handle
		from
			sys.dm_exec_procedure_stats s
		group by
			s.database_id,
			s.object_id
	) s
--outer apply
--	sys.dm_exec_query_plan(s.plan_handle) p
order by
--	TimeAvg desc;
	ExTimeLast desc;
GO

-- The same query can exist in multiple batches and the same query can have multiple plans
-- depending on the execution context (parameters, system conditions). To handle this,
-- query stats are summarized with an arbitrary SQL handle and plan handle chosen for the
-- self-join in order to fetch the query text and query plan. Further duplicates can occur
-- when the same query appears multiple times in the same batch which generate the same
-- query plan (different statement offsets). This situation is not handled by this query
-- because it is relatively infrequent.
--with xmlnamespaces
--	(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
select
	s.last_execution_time																as ExTimeLast,
	s.execution_count																	as ExCount,
	cast(round(s.total_elapsed_time / 1000.0, 0) as bigint)								as TimeTotal,
	cast(round(s.total_elapsed_time / 1000.0 / s.execution_count, 1) as decimal(9,1))	as TimeAvg,
	cast(round(s.last_elapsed_time / 1000.0, 0) as bigint)								as TimeLast,
	cast(round(s.max_elapsed_time / 1000.0, 0) as bigint)								as TimeMax,
	cast(round(s.total_worker_time / 1000.0, 0) as bigint)								as WorkTotal,
	cast(round(s.total_worker_time / 1000.0 / s.execution_count, 1) as decimal(9,1))	as WorkAvg,
	cast(round(s.last_worker_time / 1000.0, 0) as bigint)								as WorkLast,
	cast(round(s.max_worker_time / 1000.0, 0) as bigint)								as WorkMax,
	s.total_logical_reads																as Reads,
	cast(round(1.0 * s.total_logical_reads / s.execution_count, 0) as bigint)			as ReadsAvg,
	s.last_logical_reads																as ReadsLast,
	s.max_logical_reads																	as ReadsMax,
	s.total_physical_reads																as ReadsP,
	cast(round(1.0 * s.total_physical_reads / s.execution_count, 0) as bigint)			as ReadsAvgP,
	s.last_physical_reads																as ReadsLastP,
	s.max_physical_reads																as ReadsMaxP,
	s.total_logical_writes																as Writes,
	cast(round(1.0 * s.total_logical_writes / s.execution_count, 0) as bigint)			as WritesAvg,
	s.last_logical_writes																as WritesLast,
	s.max_logical_writes																as WritesMax,
--	s.total_grant_kb																	as GrantKB,
--	cast(round(1.0 * s.total_grant_kb / s.execution_count, 0) as bigint)				as GrantAvg,
--	s.last_grant_kb																		as GrantLast,
--	s.max_grant_kb																		as GrantMax,
--	s.total_used_grant_kb																as UsedKB,
--	cast(round(1.0 * s.total_used_grant_kb / s.execution_count, 0) as bigint)			as UsedAvg,
--	s.last_used_grant_kb																as UsedLast,
--	s.max_used_grant_kb																	as UsedMax,
--	s.sql_handle																		as SqlHandle,
	substring(st.text, ss.statement_start_offset / 2 + 1, datalength(st.text))			as QueryText,
	s.query_hash																		as QueryHash,
	s.query_hash_ulong																	as QueryHashUlong,
	s.plan_handle																		as PlanHandle
--	p.query_plan																		as QueryPlan
from
	(
		select
			s.query_hash																as query_hash,
			-- This is included for compatbility with the query hash values from Extended Events.
			case
				when cast(s.query_hash as bigint) < 0 then cast(s.query_hash as bigint) + 18446744073709551616
				else cast(s.query_hash as bigint)
			end																			as query_hash_ulong,
			max(s.sql_handle)															as sql_handle,
			max(s.plan_handle)															as plan_handle,
			max(s.last_execution_time)													as last_execution_time,
			sum(s.execution_count)														as execution_count,
			sum(s.total_elapsed_time)													as total_elapsed_time,
			max(s.last_elapsed_time)													as last_elapsed_time,
			max(s.max_elapsed_time)														as max_elapsed_time,
			sum(s.total_worker_time)													as total_worker_time,
			max(s.last_worker_time)														as last_worker_time,
			max(s.max_worker_time)														as max_worker_time,
			sum(s.total_logical_reads)													as total_logical_reads,
			max(s.last_logical_reads)													as last_logical_reads,
			max(s.max_logical_reads)													as max_logical_reads,
			sum(s.total_physical_reads)													as total_physical_reads,
			max(s.last_physical_reads)													as last_physical_reads,
			max(s.max_physical_reads)													as max_physical_reads,
			sum(s.total_logical_writes)													as total_logical_writes,
			max(s.last_logical_writes)													as last_logical_writes,
			max(s.max_logical_writes)													as max_logical_writes,
			sum(s.total_grant_kb)														as total_grant_kb,				-- SQL Server 2012 SP3+
			max(s.last_grant_kb)														as last_grant_kb,				-- SQL Server 2012 SP3+
			max(s.max_grant_kb)															as max_grant_kb,				-- SQL Server 2012 SP3+
			sum(s.total_used_grant_kb)													as total_used_grant_kb,			-- SQL Server 2012 SP3+
			max(s.last_used_grant_kb)													as last_used_grant_kb,			-- SQL Server 2012 SP3+
			max(s.max_used_grant_kb)													as max_used_grant_kb			-- SQL Server 2012 SP3+
		from
			sys.dm_exec_query_stats s
		group by
			s.query_hash
	) s
inner join
	sys.dm_exec_query_stats ss
on
	ss.query_hash = s.query_hash
and
	ss.sql_handle = s.sql_handle
and
	ss.plan_handle = s.plan_handle
cross apply
	sys.dm_exec_sql_text(s.sql_handle) st
-- Getting the query plan is extremely slow; only include this for very small lists.
--cross apply
--	sys.dm_exec_query_plan(s.plan_handle) p
where
	st.text not like N'%dm[_]exec%'
--and
--	st.text like N'%changetable%'
--and
--	s.query_hash_ulong in (246803098035406606, 15699471961201696508, 780656479982006596)
order by
--	TimeAvg desc;
	ExTimeLast desc;
GO

/*
-- Get a specific query plan.
select * from sys.dm_exec_query_plan(0x060005003F6AA004E0D95EF31A00000001000000000000000000000000000000000000000000000000000000);
GO

select
	ts.*
from
	sys.dm_exec_trigger_stats ts
GO

select
	ws.*
from
	sys.dm_os_wait_stats ws
GO

select
	wt.*
from
	sys.dm_os_waiting_tasks wt
GO

select
	db_name(fs.database_id)										as database_name,
	mf.name														as file_name,
	mf.physical_name											as physical_name,
	fs.*
from
	sys.dm_io_virtual_file_stats(null, null) fs
inner join
	sys.master_files mf
on
	mf.database_id = fs.database_id
and
	mf.file_id = fs.file_id
order by
	db_name(fs.database_id);
GO

-- Query Cost of Parallelized Queries
with xmlnamespaces
	(default 'http://schemas.microsoft.com/sqlserver/2004/07/showplan')
select
	query_plan													as CompleteQueryPlan,
	n.value('(@StatementText)[1]', 'varchar(4000)')				as StatementText,
	n.value('(@StatementOptmLevel)[1]', 'varchar(25)')			as StatementOptimizationLevel,
	n.value('(@StatementSubTreeCost)[1]', 'varchar(128)')		as StatementSubTreeCost,
	n.query('.')												as ParallelSubTreeXml,
	ecp.usecounts												as UseCounts,
	ecp.size_in_bytes											as SizeInBytes
from
	sys.dm_exec_cached_plans ecp
cross apply
	sys.dm_exec_query_plan(plan_handle) eqp
cross apply
	query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') qn(n)
where
	n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1;
GO
*/
