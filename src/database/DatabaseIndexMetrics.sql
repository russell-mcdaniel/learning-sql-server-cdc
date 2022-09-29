-- ================================================================================
-- INDEX METRICS
-- ================================================================================
use MedicationTracker;
GO

select
	object_schema_name(i.object_id)											as schema_name,
	object_name(i.object_id)												as table_name,
	i.name																	as index_name,
	c.name																	as column_name_first,
	i.index_id																as index_id,
	ips.index_level															as index_level,
	ips.index_type_desc														as index_type_desc,
	ips.alloc_unit_type_desc												as alloc_unit_type_desc,
	i.fill_factor															as fill_factor,
	cast(ps.used_page_count * 8.0 / 1024.0 as decimal(12,1))				as used_mb,
	cast(ps.reserved_page_count * 8.0 / 1024.0 as decimal(12,1))			as res_mb,
	cast(ips.page_count * 8.0 / 1024.0 as decimal(12,1))					as size_mb,
	ps.row_count															as row_count,
	ips.page_count															as page_count,
	cast(ips.avg_page_space_used_in_percent as decimal(6,2))				as avg_pg_spc_used,			-- Only populated in SAMPLED or DETAILED mode.
	ips.record_count														as record_count,			-- Only populated in SAMPLED or DETAILED mode.
	ips.avg_record_size_in_bytes											as avg_record_size,			-- Only populated in SAMPLED or DETAILED mode.
	ips.fragment_count														as frag_count,
	cast(ips.avg_fragmentation_in_percent as decimal(6,2))					as avg_frag
--	ius.user_scans + ius.user_seeks + ius.user_lookups + ius.user_updates	as user_ops,
--	ius.user_scans + ius.user_seeks + ius.user_lookups						as user_reads,
--	ius.user_updates														as user_writes,
--	ius.user_scans															as user_scans,
--	ius.user_seeks															as user_seeks,
--	ius.user_lookups														as user_lookups,
--	ius.user_updates														as user_updates,
--	case
--		when coalesce(ius.user_scans + ius.user_seeks + ius.user_lookups, 0) = 0 and ius.user_updates > 0 then 1
--		else 0
--	end																		as unused
--	ius.last_user_scan														as last_user_scan,
--	ius.last_user_seek														as last_user_seek,
--	ius.last_user_lookup													as last_user_lookup,
--	ius.last_user_update													as last_user_update
--	ios.leaf_insert_count													as leaf_insert_count,
--	ios.leaf_update_count													as leaf_update_count,
--	ios.leaf_delete_count													as leaf_delete_count,
--	ios.leaf_ghost_count													as leaf_ghost_count,
--	ios.leaf_allocation_count												as leaf_allocation_count,
--	ios.leaf_page_merge_count												as leaf_page_merge_count
--	'alter index ' + i.name + ' on ' + object_schema_name(i.object_id) + '.' + object_name(i.object_id) + ' reorganize;'
--																			as reorganize_sql,
--	'alter index ' + i.name + ' on ' + object_schema_name(i.object_id) + '.' + object_name(i.object_id) + ' rebuild with (sort_in_tempdb = on);'
--																			as rebuild_sql
from
	sys.indexes i
inner join
	sys.index_columns ic on ic.object_id = i.object_id and ic.index_id = i.index_id and ic.key_ordinal = 1
inner join
	sys.columns c on c.object_id = ic.object_id and c.column_id = ic.column_id
cross apply
--	sys.dm_db_index_physical_stats(db_id(), i.object_id, i.index_id, default, default) ips
--	sys.dm_db_index_physical_stats(db_id(), i.object_id, i.index_id, default, 'SAMPLED') ips
	sys.dm_db_index_physical_stats(db_id(), i.object_id, i.index_id, default, 'DETAILED') ips
--cross apply
--	sys.dm_db_index_operational_stats(db_id(), i.object_id, i.index_id, default) ios
--left outer join
--	sys.dm_db_index_usage_stats ius on ius.database_id = db_id() and ius.object_id = i.object_id and ius.index_id = i.index_id
inner join
	sys.dm_db_partition_stats ps on ps.object_id = i.object_id and ps.index_id = i.index_id
--where
--	i.object_id in
--		(
--			object_id(N'Ext.MessageSubscription'),
--			object_id(N'Ext.NotificationSubscription'),
--			object_id(N'Ext.OutboundMessage'),
--			object_id(N'Ext.PublishedMessage'),
--			object_id(N'Ext.ReceivedMessage')
--		)
--and
--	i.name in (N'pk_PharmacyOrder, N'ix_PharmacyOrderSnapshot_9')
--and
--	ips.page_count > 49
--and
--	ips.avg_fragmentation_in_percent > 4.99
order by
--	ips.avg_fragmentation_in_percent desc,
--	ius.user_scans + ius.user_seeks + ius.user_lookups + ius.user_updates desc,
--	ips.page_count desc,
	object_schema_name(i.object_id),
	object_name(i.object_id),
	i.index_id;
GO

/*
-- Get index column details.
select
	object_schema_name(i.object_id)									as schema_name,
	object_name(i.object_id)										as table_name,
	i.name															as index_name,
	c.name															as column_name,
	ic.key_ordinal													as key_ordinal,
	ic.is_included_column											as is_included
from
	sys.indexes i (nolock)
inner join
	sys.index_columns ic (nolock) on ic.object_id = i.object_id and ic.index_id = i.index_id
inner join
	sys.columns c (nolock) on c.object_id = ic.object_id and c.column_id = ic.column_id
order by
	object_schema_name(i.object_id),
	object_name(i.object_id),
	i.name,
	ic.is_included_column,
	ic.key_ordinal;
GO
*/
