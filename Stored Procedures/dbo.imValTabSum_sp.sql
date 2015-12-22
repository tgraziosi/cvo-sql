SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE procedure [dbo].[imValTabSum_sp]
(
        @p_local       int = 0
)
as
SET NOCOUNT ON
declare @p_base					nvarchar(500)
declare @p_sql                  nvarchar(1000)
declare @p_section              varchar(40)
declare @p_viewname             varchar(40)
declare @p_viewdesc             varchar(64)
declare @p_process_order        int
declare @p_wrk                  varchar(255)
declare @parmDefinition 		nvarchar(500)
declare @transtype				varchar(64)

create table #t1
(
    record_type         varchar(64),
    company_code        varchar(8),
    batch               int,
    count_type          varchar(64),
    reccount            int,
    process_order       int,
	record_type_order	int)

declare sumRptCursor insensitive cursor for
select  imwbtables_vw.section,
        imwbtables_vw.Name1,
        imwbtables_vw.description,
        imwbtables_vw.process_order
from    imwbtables_vw
        ,sysobjects
where   imwbtables_vw.Name1 = sysobjects.name
and 	imwbtables_vw.isTable = 1
and     imwbtables_vw.[Enable Distribution Reports] = 1

SET @parmDefinition = N'@recordtype varchar(50),@typeorder int'

open sumRptCursor

fetch   next
from    sumRptCursor
into    @p_section,
        @p_viewname,
        @p_viewdesc,
        @p_process_order

while @@fetch_status <> -1
begin

        set @p_base = 'insert into #t1 select ' +
				char(39) + @p_section + char(32) + @p_viewdesc + char(39) +
                ',company_code,batch_no,@recordtype,count(*),' +
                CAST(@p_process_order as NVARCHAR(10)) + ',@typeorder' +
				' from ' + @p_viewname

		-- records with validation errors
        set @p_wrk = ' where (record_status_1 != 0 or record_status_2 != 0) and process_status != 1 group by company_code,batch_no'
		set @transtype = 'With Validation Errors'
		set @p_sql = @p_base + @p_wrk
		exec sp_executesql @p_sql, @parmDefinition, @recordtype = @transtype, @typeorder = 1

		-- records that are valid
		set @p_wrk = ' where (record_status_1 = 0 and record_status_2 = 0) and process_status = 0 group by company_code,batch_no'
		set @transtype = 'Valid / Not Processed'
		set @p_sql = @p_base + @p_wrk
		exec sp_executesql @p_sql, @parmDefinition, @recordtype = @transtype, @typeorder = 2

		-- records the are valid and processed
		set @p_wrk = ' where process_status = 1 group by company_code,batch_no'
		set @transtype = 'Valid / Processed'
		set @p_sql = @p_base + @p_wrk
		exec sp_executesql @p_sql, @parmDefinition, @recordtype = @transtype, @typeorder = 3

		-- total records of all types
		set @p_wrk = ' group by company_code,batch_no'
		set @transtype = 'Total'
		set @p_sql = @p_base + @p_wrk
		exec sp_executesql @p_sql, @parmDefinition, @recordtype = @transtype, @typeorder = 4


        fetch   next
        from    sumRptCursor
        into    @p_section,
        		@p_viewname,
        		@p_viewdesc,
        		@p_process_order
end

close sumRptCursor
deallocate sumRptCursor

if @p_local != 0
begin
	select 	#t1.record_type,
			#t1.company_code,
			#t1.batch,
			#t1.count_type,
			#t1.reccount
	from 	#t1
			,glco
	where 	#t1.company_code = glco.company_code
	order by #t1.process_order,batch,record_type_order
end
else
begin
	select  record_type,
        	company_code,
       		batch,
        	count_type,
        	reccount
	from    #t1
	order by process_order,batch,record_type_order
end


GO
GRANT EXECUTE ON  [dbo].[imValTabSum_sp] TO [public]
GO
