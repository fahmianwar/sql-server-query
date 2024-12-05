SELECT
d.name
,p.command
,p.status
,p.session_id
,p.blocking_session_id
,
case
when p2.session_id is not null and (p.blocking_session_id = 0 or p.session_id IS NULL) then '1' else '0' end as head_blocker
,     [statement_text] = Substring(t.TEXT, (p.statement_start_offset / 2) + 1,  
                                            ( ( CASE p.statement_end_offset WHEN - 1 THEN Datalength(t.TEXT) 
                                            ELSE p.statement_end_offset  
                                            END - p.statement_start_offset ) / 2 ) + 1) 
,[command_text] =Coalesce(Quotename(Db_name(t.dbid)) + N'.' + Quotename(Object_schema_name(t.objectid, t.dbid)) + N'.' + Quotename(Object_name(t.objectid, t.dbid)), '')  
,p.start_time
,p.total_elapsed_time/1000 as elapsed_time_secs,p.wait_time/1000 as wait_time
,p.last_wait_type
,dr.host_name
,dr.program_name
,dr.login_name
,m.granted_memory_kb
,m.grant_time
,p.plan_handle
,ph.query_plan
,p.sql_handle
FROM sys.dm_exec_requests p
--left join sys.dm_os_waiting_tasks w on w.session_id = p.session_id
inner join sys.databases d on d.database_id = p.database_id
outer apply sys.dm_exec_sql_text(p.sql_handle) t
outer apply sys.dm_exec_query_plan(p.plan_handle) as ph
inner join sys.dm_exec_sessions dr on dr.session_id = p.session_id
left join sys.dm_exec_query_memory_grants m on m.session_id = p.session_id
left join sys.dm_exec_requests p2 ON (p.session_id = p2.blocking_session_id)
where text is not null
--and p.session_id in (select spid from sysprocesses where blocked<>0)
order by  p.start_time;
