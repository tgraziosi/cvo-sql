SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_distribution] @batch_id varchar(20)
  as 



declare	@explode_flag	char(1)
declare @xerr			int,
		@count			int

CREATE TABLE #resource_demand (
  batch_id varchar (20) NOT NULL ,
  group_no varchar (20) NULL ,
  part_no varchar (30) NOT NULL ,
  qty decimal(20, 8) NOT NULL ,
  demand_date datetime NOT NULL ,
  ilevel int NOT NULL ,
  location varchar (10) NULL ,
  source char (1) NULL ,
  status char (1) NULL ,
  commit_ed decimal(20, 8) NULL ,
  source_no varchar (20) NULL ,
  parent varchar (30) NULL ,
  pqty decimal(20, 8) NOT NULL ,
  p_used decimal(20, 8) NOT NULL ,
  type char (1) NULL ,
  vendor varchar (12) NULL ,
  buy_flag char (1) NULL default('N'),
  uom char (2) NULL ,
  buyer varchar (10) NULL ,
  prod_no int NULL ,
  location2 varchar (10) NULL ,
  min_stock decimal(20,8),							-- mls 12/10/04 SCR 33703
  max_stock decimal(20,8),							-- mls 12/10/04 SCR 33703
  row_id int IDENTITY (1, 1) NOT NULL ,
)
CREATE  UNIQUE  INDEX #resdem1 ON 
  #resource_demand(ilevel, location, part_no, source, source_no, demand_date, status, parent)
CREATE INDEX #resdem2 on #resource_demand(qty,source)
CREATE INDEX #resdem3 on #resource_demand(source,part_no,location)
CREATE INDEX #resdem4 on #resource_demand(status,ilevel)
create index #resdem5 on #resource_demand(row_id)
create index #resdem6 on #resource_demand(status,part_no,location,qty)
create index #resdem7 on #resource_demand(part_no,location)

CREATE TABLE #resource_avail (
  batch_id varchar (20) NOT NULL ,
  part_no varchar (30) NOT NULL ,
  qty decimal(20, 8) NOT NULL ,
  avail_date datetime NOT NULL ,
  commit_ed decimal(20, 8) NOT NULL ,
  source char (1) NULL ,
  location varchar (10) NULL ,
  source_no varchar (20) NULL ,
  temp_qty decimal(20, 8) NULL ,
  type char (1) NULL ,
  status char (1) NULL ,
  row_id int IDENTITY (1, 1) NOT NULL 
)
create index #resav1 on #resource_avail(qty)
create index #resav2 on #resource_avail(status,part_no,location,avail_date, source, source_no,qty)
create index #resav3 on #resource_avail(part_no,location)

select @xerr = 0

--******************************************************************************
--* Clear the resource tables of any records with this batch id
--******************************************************************************
DELETE	resource_avail
WHERE	batch_id = @batch_id

DELETE	resource_demand
WHERE	batch_id = @batch_id

DELETE	resource_demand_group
WHERE	batch_id = @batch_id

DELETE	resource_depends
WHERE	batch_id = @batch_id	

--******************************************************************************
--* Calculate gross supply
--******************************************************************************
EXEC fs_sch_avail @batch_id				-- skk 03/05/01 SCR 26115
if @@error <> 0 
begin
   select @xerr = -1
   select @xerr
   return
end

--******************************************************************************
--* Calculate gross demand
--******************************************************************************
EXEC fs_sch_demand @batch_id
if @@error <> 0 
begin
	select @xerr = -2
	select @xerr
	return
end

--******************************************************************************
--* Do first pass netting demand with supply
--******************************************************************************
EXEC fs_sch_step1 @batch_id
if @@error <> 0
begin
   select @xerr = -3
   select @xerr
   return
end

--******************************************************************************
--* Does the user want to explode build plans?
--******************************************************************************
SELECT	@explode_flag	= explode_flag
FROM	resource_batch
WHERE	batch_id 		= @batch_id

if @explode_flag = 'Y'
begin
	--**************************************************************************
	--* If yes, then determine if we have any (U)nfilled demand rows in table 
	--* resource_demand.  If there are, then call fs_sch_step2 to explode items
	--* with components and do second pass netting.  Each call to this proc will
	--* explode the build plan one level further down, so we keep calling it 
	--* until the lowest level is completed and there is no more (U)nfilled demand.
	--**************************************************************************
	
	while exists (select 1 FROM #resource_demand WHERE status = 'U' )
	begin
		EXEC fs_sch_step2 @batch_id
		if @@error <> 0
		begin
			select @xerr = -4
			select @xerr
			return
		end
	end -- while @count > 0
end
else
begin
	--**************************************************************************
	--* If we are not exploding, then set all of the (U)nfilled rows in
	--* resource_demand to (X)Completed.  We are done with them and need to
	--* suggest purchase orders.
	--**************************************************************************
	UPDATE	#resource_demand
	SET	status		= 'X'
	WHERE	status		= 'U'
end

delete from #resource_demand where source = 'T'

--******************************************************************************
--* Group demand and apply order minimum and multiple
--******************************************************************************
exec fs_sch_group @batch_id
if @@error <> 0
begin
   select @xerr = -5
   select @xerr
   return
end

INSERT INTO resource_avail 
  (batch_id, part_no, qty, avail_date, commit_ed, source, location, source_no, temp_qty, type, status, row_id)
select 
  batch_id, part_no, qty, avail_date, commit_ed, source, location, source_no, temp_qty, type, status, row_id
from #resource_avail

INSERT INTO resource_demand
  (batch_id, group_no, part_no, qty, demand_date, ilevel, location, source, status, commit_ed, source_no, 
  parent, pqty, p_used, type, vendor, buy_flag, uom, buyer, prod_no, location2, row_id)
select 
  batch_id, group_no, part_no, qty, demand_date, ilevel, location, source, status, commit_ed, source_no, 
  parent, pqty, p_used, type, vendor, buy_flag, uom, buyer, prod_no, location2, row_id
from #resource_demand

select @xerr = 1
select @xerr 'err_code'

GO
GRANT EXECUTE ON  [dbo].[fs_sch_distribution] TO [public]
GO
