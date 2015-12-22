SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_womdispatch] @range varchar(8000) = '0=0' as
begin
declare @row_id int, @sched_process_id int

select @range = replace(@range,'sched_operation.work_datetime','datediff(day,"01/01/1900",sched_operation.work_datetime) + 693596 ')
select @range = replace(@range,'sched_operation.done_datetime','datediff(day,"01/01/1900",sched_operation.done_datetime) + 693596 ')
select @range = replace(@range,'"','''')

CREATE table   #rpt_womdispatch   (              
            sched_name varchar(16) NULL,  
            location varchar(10) NULL,  
            resource_id int NULL,  
            resource_code varchar(30) NULL,  
            resource_name varchar(255) NULL,  
            sched_process_id int NULL,  
            prod_no int NULL,  
            prod_ext int NULL,  
            source_flag char(1) NULL,  
            part_no varchar(30) NULL,  
            uom_qty decimal(20,8) NULL,  
            uom char(2) NULL,  
            sched_operation_id int NULL,  
            operation_step int NULL,  
            work_datetime datetime NULL,  
            done_datetime datetime NULL,  
            operation_status char(1) NULL
             ) 

create table #rpt_womdispatchdet (
	sched_process_id INT NULL,
	so_sched_order_id int NULL,
	so_location varchar(10) NULL,
	so_done_datetime datetime NULL,
	so_part_no varchar(30) NULL,
	im_description varchar(255) NULL,
	so_uom_qty decimal(20,8) NULL,
	so_uom char(2) NULL,
	so_order_priority_id int NULL,
	so_source_flag char(1) NULL,
	so_order_no int NULL,
	so_order_ext int NULL,
	so_order_line int NULL,
	so_order_line_kit int NULL,
	co_cust_code varchar(20) NULL,
        co_cust_name varchar(100) NULL
)

exec('insert #rpt_womdispatch(
            sched_name ,
            location ,
            resource_id ,
            resource_code,
            resource_name ,
            sched_process_id ,
            prod_no ,
            prod_ext ,
            source_flag ,
            part_no ,
            uom_qty ,
            uom ,
            sched_operation_id ,
            operation_step ,
            work_datetime ,
            done_datetime ,
            operation_status
)
             SELECT  distinct
            sched_model.sched_name,  
            resource.location,   
            resource.resource_id,  
            resource.resource_code,  
            resource.resource_name,  
            sched_process.sched_process_id,  
            sched_process.prod_no,  
            sched_process.prod_ext,  
            sched_process.source_flag,  
            sched_process_product.part_no,  
            sched_process_product.uom_qty * sched_process.process_unit uom_qty,  
            sched_process_product.uom,  
            sched_operation.sched_operation_id,  
            sched_operation.operation_step,  
            sched_operation.work_datetime,  
            sched_operation.done_datetime,  
            sched_operation.operation_status 
            
             FROM  sched_model
             join sched_resource (nolock) on ( sched_resource.sched_id = sched_model.sched_id )   
             join resource (nolock) on ( sched_resource.resource_id = resource.resource_id ) 
             join sched_operation_resource (nolock) on ( sched_operation_resource.sched_resource_id = sched_resource.sched_resource_id )  
	     join sched_operation (nolock) on ( sched_operation.sched_operation_id = sched_operation_resource.sched_operation_id ) 
             join sched_process (nolock) on ( sched_process.sched_process_id = sched_operation.sched_process_id )
             left outer join sched_process_product (nolock) on ( sched_process_product.sched_process_id = sched_process.sched_process_id ) and
		( sched_process_product.usage_flag = ''P'' )
	     join locations l (nolock) on l.location = resource.location 
	     join region_vw r (nolock) on l.organization_id = r.org_id 
             WHERE  ( datediff(mi, sched_operation.work_datetime, sched_operation.done_datetime ) > 0 ) and ' + @range + '
	    order by sched_name')

DECLARE	@rowcount		INT,
	@sched_id		INT,
	@hierarchy_level	INT,
	@sched_item_id		int
CREATE TABLE #item
	(
	sched_item_id	INT,
	hierarchy_level	INT
	)

CREATE TABLE #order
	(
	sched_order_id	INT
	)

select @sched_process_id = isnull((select min(sched_process_id) from #rpt_womdispatch where isnull(sched_process_id,-1) > -1),NULL)
while @sched_process_id is not null
begin
------------------------------------------

SELECT	@rowcount=0,
	@hierarchy_level=1

truncate table #item
truncate table #order

	SELECT	@sched_id=SP.sched_id
	FROM	dbo.sched_process SP  (nolock)
	WHERE	SP.sched_process_id = @sched_process_id

	INSERT	#item(sched_item_id,hierarchy_level)
	SELECT	SI.sched_item_id,@hierarchy_level
	FROM	dbo.sched_item SI  (nolock)
	WHERE	SI.sched_id = @sched_id
	AND	SI.source_flag = 'M'
	AND	SI.sched_process_id = @sched_process_id

	-- Capture intial row count
	SELECT	@rowcount=@@rowcount

-- While we continue to get more subprocesses, keep adding
WHILE @rowcount > 0
	BEGIN
	-- Assume no more will be added
	SELECT	@rowcount = 0

	-- Grab an item to process
	SELECT	@sched_item_id=MIN(I.sched_item_id)
	FROM	#item I
	WHERE	I.hierarchy_level = @hierarchy_level

	WHILE @sched_item_id IS NOT NULL
		BEGIN
		-- Insert children of items
		INSERT	#item
			(
			sched_item_id,
			hierarchy_level
			)
		SELECT	DISTINCT
			SI.sched_item_id,
			@hierarchy_level+1
		FROM	dbo.sched_operation_item SOI  (nolock),
			dbo.sched_operation SO  (nolock),
			dbo.sched_item SI  (nolock)
		WHERE	SOI.sched_item_id = @sched_item_id
		AND	SO.sched_operation_id = SOI.sched_operation_id
		AND	SI.sched_id = @sched_id
		AND	SI.source_flag = 'M'
		AND	SI.sched_process_id = SO.sched_process_id
		AND	SI.sched_process_id IS NOT NULL
		AND NOT EXISTS (SELECT	*
				FROM	#item I2
				WHERE	I2.sched_item_id = SI.sched_item_id)

		-- Capture the number of rows added
		SELECT	@rowcount = @rowcount + @@rowcount

		-- Get next item to process
		SELECT	@sched_item_id=MIN(I.sched_item_id)
		FROM	#item I
		WHERE	I.hierarchy_level = @hierarchy_level
		AND	I.sched_item_id > @sched_item_id
		END

	-- Move to next level in the hierarchy
	SELECT	@hierarchy_level=@hierarchy_level+1
	END

	INSERT	#order(sched_order_id)
	SELECT	DISTINCT SOI.sched_order_id
	FROM	#item I,
		dbo.sched_order_item SOI (nolock)
	WHERE	SOI.sched_item_id = I.sched_item_id

  insert #rpt_womdispatchdet (
        sched_process_id,
	so_sched_order_id ,
	so_location ,
	so_done_datetime,
	so_part_no ,
	im_description,
	so_uom_qty ,
	so_uom ,
	so_order_priority_id ,
	so_source_flag ,
	so_order_no ,
	so_order_ext ,
	so_order_line ,
	so_order_line_kit ,
	co_cust_code ,
        co_cust_name )

	SELECT	@sched_process_id,
		SO.sched_order_id,
		SO.location,
		SO.done_datetime,
		SO.part_no,
		IM.description,
		SO.uom_qty,
		SO.uom,
		SO.order_priority_id,
		SO.source_flag,
		SO.order_no,
		SO.order_ext,
		SO.order_line,
		SO.order_line_kit,
		CO.cust_code,
		(SELECT C.customer_name FROM dbo.adm_cust_all C WHERE C.customer_code = CO.cust_code) customer_name
	FROM	#order O,
		dbo.sched_order SO (nolock),
		dbo.inv_master IM (nolock),
		dbo.orders_all CO (nolock)
	WHERE	SO.sched_order_id = O.sched_order_id
	AND	SO.source_flag IN ('C','J')
	AND	IM.part_no = SO.part_no
	AND	CO.order_no = SO.order_no
	AND	CO.ext = SO.order_ext
	UNION
	SELECT	@sched_process_id,
		SO.sched_order_id,
		SO.location,
		SO.done_datetime,
		SO.part_no,
		IM.description,
		SO.uom_qty,
		SO.uom,
		SO.order_priority_id,
		SO.source_flag,
		SO.order_no,
		SO.order_ext,
		SO.order_line,
		NULL,
		NULL,
		NULL
	FROM	#order O,
		dbo.sched_order SO (nolock),
		dbo.inv_master IM (nolock)
	WHERE	SO.sched_order_id = O.sched_order_id
	AND	SO.source_flag IN ('F','A','M','N')					-- mls 11/12/01 SCR 27837
	AND	IM.part_no = SO.part_no


select @sched_process_id = isnull((select min(sched_process_id) from #rpt_womdispatch where isnull(sched_process_id,-1) > @sched_process_id),NULL)
end

select w.*,
	so_sched_order_id ,
	so_location ,
	so_done_datetime,
	so_part_no ,
	im_description,
	so_uom_qty ,
	so_uom ,
	so_order_priority_id ,
	so_source_flag ,
	so_order_no ,
	so_order_ext ,
	so_order_line ,
	so_order_line_kit ,
	co_cust_code ,
        co_cust_name 
 from #rpt_womdispatch w
left outer join #rpt_womdispatchdet d on w.sched_process_id = d.sched_process_id
end

GO
GRANT EXECUTE ON  [dbo].[adm_rpt_womdispatch] TO [public]
GO
