SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_batch_delete] @batch_id varchar(20)
  AS 

BEGIN

if @batch_id = '%'
begin
	--**************************************************************************
	--* Clear out the resource tables completely
	--**************************************************************************
	DELETE resource_avail
	DELETE resource_demand
	DELETE resource_demand_group
	DELETE resource_depends
	DELETE resource_batch
end
else
begin
	--**************************************************************************
	--* Clear the resource tables of any records with this specific batch id
	--**************************************************************************
	DELETE	resource_avail
	WHERE	batch_id = @batch_id
	
	DELETE	resource_demand
	WHERE	batch_id = @batch_id
	
	DELETE	resource_demand_group
	WHERE	batch_id = @batch_id
	
	DELETE	resource_depends
	WHERE	batch_id = @batch_id
	
	--**************************************************************************
	--* Delete resource_batch last because of the foreign_key constraint on batch_id
	--**************************************************************************
	DELETE	resource_batch
	WHERE	batch_id = @batch_id	
end -- if @batch_id = '%'

END

GO
GRANT EXECUTE ON  [dbo].[fs_sch_batch_delete] TO [public]
GO
