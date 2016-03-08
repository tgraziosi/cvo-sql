CREATE TABLE [dbo].[inv_list]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avg_cost] [decimal] (20, 8) NOT NULL,
[avg_direct_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__avg_di__2BA05F6B] DEFAULT ((0)),
[avg_ovhd_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__avg_ov__2C9483A4] DEFAULT ((0)),
[avg_util_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__avg_ut__2D88A7DD] DEFAULT ((0)),
[in_stock] [decimal] (20, 8) NOT NULL,
[hold_qty] [decimal] (20, 8) NOT NULL,
[rank_class] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_stock] [decimal] (20, 8) NOT NULL,
[max_stock] [decimal] (20, 8) NOT NULL,
[min_order] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__min_or__2E7CCC16] DEFAULT ((0)),
[issued_mtd] [decimal] (20, 8) NOT NULL,
[issued_ytd] [decimal] (20, 8) NOT NULL,
[lead_time] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [decimal] (20, 8) NOT NULL,
[qty_year_end] [decimal] (20, 8) NOT NULL,
[qty_month_end] [decimal] (20, 8) NOT NULL,
[qty_physical] [decimal] (20, 8) NOT NULL,
[entered_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_date] [datetime] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_list__void__2F70F04F] DEFAULT ('N'),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[std_labor] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__std_la__30651488] DEFAULT ((0)),
[std_direct_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__std_di__315938C1] DEFAULT ((0)),
[std_ovhd_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__std_ov__324D5CFA] DEFAULT ((0)),
[std_util_dolrs] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__std_ut__33418133] DEFAULT ((0)),
[setup_labor] [decimal] (20, 8) NOT NULL,
[freight_unit] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__freigh__3435A56C] DEFAULT ((0)),
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_date] [datetime] NULL,
[acct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eoq] [decimal] (20, 8) NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[dock_to_stock] [int] NOT NULL CONSTRAINT [DF__inv_list__dock_t__3529C9A5] DEFAULT ((0)),
[order_multiple] [decimal] (20, 8) NOT NULL CONSTRAINT [DF__inv_list__order___361DEDDE] DEFAULT ((0)),
[abc_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abc_code_frozen_flag] [int] NOT NULL CONSTRAINT [DF__inv_list__abc_co__37121217] DEFAULT ((0)),
[po_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[so_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__inv_list__qc_qty__38063650] DEFAULT ((0)),
[so_qty_increment] [decimal] (20, 8) NULL
) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [cvo_inv_list_location_051515] ON [dbo].[inv_list] ([location]) INCLUDE ([in_stock], [issued_mtd], [min_stock], [part_no]) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[CVO_AC_inv_list_cyclecount_update] ON [dbo].[inv_list] 
 FOR UPDATE
AS


/****************************************************************************************
**  				Clear Vision
**  DATE		:	Jan 2012
**  FILE    	:	CVO_AC_inv_list_cyclecount_update.sql
**	CREATED BY	:   Alain Hurtubise - Antler Consulting
**
**  DESCRIPTION	:	Trigger to create cycle count entry
**		
**	Version		:   1.0
** 
*****************************************************************************************/

BEGIN

	SET NOCOUNT ON;
	
	DECLARE @last_cycle_date datetime
	DECLARE	@new_cycle_date datetime
	DECLARE @part_no varchar(30)
	DECLARE @location varchar(10)
	DECLARE @qty decimal(20,8)
	DECLARE @category varchar(10)
	DECLARE @style varchar(40)
	
	
	DECLARE cyclecount__cursor CURSOR LOCAL STATIC FOR
	SELECT	i.location, i.part_no, i.cycle_date,d.cycle_date
	FROM	inserted i, deleted d
	WHERE	i.part_no=d.part_no
	AND		i.location = d.location

	OPEN cyclecount__cursor 
	IF @@cursor_rows = 0
	BEGIN
	  CLOSE cyclecount__cursor
	  DEALLOCATE cyclecount__cursor
	  RETURN
	END
	
	FETCH NEXT FROM cyclecount__cursor INTO
	@location, @part_no,  @new_cycle_date, @last_cycle_date

	WHILE @@FETCH_STATUS = 0
	BEGIN	
	
		
		IF (@last_cycle_date <> @new_cycle_date)
		BEGIN


			SELECT @category = isnull(category,'') FROM inv_master(NOLOCK) WHERE part_no = @part_no
			SELECT @style = isnull(field_2,'') FROM inv_master_add(NOLOCK) WHERE part_no = @part_no
			
			SELECT @qty = 0

			SELECT	@qty = isnull(qty,0)
			FROM	issues_all
			WHERE	@part_no = part_no
			AND		@location = location_from
			AND		Month(issue_date) = Month(@new_cycle_date)
			AND		Year(issue_date) = Year(@new_cycle_date)
			AND		Day(issue_date) = Day(@new_cycle_date)		


			INSERT INTO [dbo].[CVO_ac_inv_cyclecount]
				   ([part_no]
				   ,[location]
				   ,[issue_date]
				   ,[qty]
					,[category]
					,[style]
					,[month]
					,[year])
			VALUES (@part_no
				   ,@location
				   ,@new_cycle_date
				   ,@qty
				   ,@category
				   ,@style
				   ,Month(@new_cycle_date)
				   ,Year(@new_cycle_date)
				   )
				   
		
		END	



		FETCH NEXT FROM cyclecount__cursor INTO
		@location, @part_no, @new_cycle_date, @last_cycle_date
		
	END -- while

	CLOSE cyclecount__cursor
	DEALLOCATE cyclecount__cursor



END			      
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_inv_list_del] ON [dbo].[inv_list]   FOR DELETE  AS 
begin
	DECLARE @item_id varchar(30), @data varchar(40)

	/* check to see if part locations can be deleted */
	if not exists (select * from config where flag='TRIG_DEL_INVM' and value_str='DISABLE')

	   begin
	   /* need to see if EAI is installed first */	
	   if exists (select * from config where flag = 'EAI' and value_str = 'Y')
	      begin
		/* call the stored procedure to update info from INV_list */
		select distinct @item_id = min(part_no) from deleted 
		while (@item_id > '') begin
			select @data = @item_id + '|0'	-- send in a 0 to show it's not a service agreement
			exec EAI_process_insert 'Part', @data, 'BO'

			select distinct @item_id = min(part_no) from deleted where part_no > @item_id
		end
		return
	      end
	   end
	/* else, they get a message from the ADM trigger that they can't delete an inv_list record */
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_inv_list_insupd] ON [dbo].[inv_list]   FOR INSERT, UPDATE  AS 
BEGIN
	DECLARE @item_id varchar(30), @data varchar(40)
	Declare @send_document_flag char(1)  -- rev 4


	if exists( SELECT * FROM config WHERE flag = 'EAI' and value_str = 'Y') begin	-- EAI is enabled
		select distinct @item_id = min(part_no) from inserted 
		while (@item_id > '') begin

		   select @send_document_flag = 'N'

		   if ((exists( select distinct 'X' from inserted i, deleted d
			where	((i.location <> d.location) or
				(i.void <> d.void) or
				(i.part_no <> d.part_no) or
				(i.note <> d.note) or
				(i.std_cost <> d.std_cost) or
				(i.std_direct_dolrs <> d.std_direct_dolrs) or
				(i.std_ovhd_dolrs <> d.std_ovhd_dolrs) or
				(i.std_util_dolrs <> d.std_util_dolrs) or
				(i.std_labor <> d.std_labor))
				-- don't worry about custom kits or resources
				and (exists (select 'X' from inv_master (NOLOCK) 
					where part_no = @item_id and status not in ('R')))))	
				OR (not exists(select 'X' from deleted) and 
					-- don't worry about custom kits or resources
					(exists (select 'X' from inv_master (NOLOCK) 
					where part_no = @item_id and status not in ('R')))))
			BEGIN
				select @send_document_flag = 'Y'	--passes the initial test
			END
			ELSE BEGIN
			-- rev 4:  add ability to send individual docs through Query Analyzer
				If (Update(location) or Update(void) or Update(part_no) or Update(note) or 
				Update(std_cost) or Update(std_direct_dolrs) or Update(std_ovhd_dolrs) or
				Update(std_util_dolrs) or Update(std_labor)) and 
				(exists (select 'X' from inv_master (NOLOCK) 
				where part_no = @item_id and status not in ('R'))) begin
					select @send_document_flag = 'Y'
				end
			END

		   If @send_document_flag = 'Y' BEGIN	--c_quote has been changed, send data to Front Office

			-- inv_list has been changed or inserted, send data to Front Office
			select @data = @item_id + '|0'	-- it's not a service agreement
			exec EAI_process_insert 'Part', @data, 'BO'
		   end
		   select distinct @item_id = min(part_no) from inserted where part_no > @item_id
	   	end
	end
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[t602delinvl] ON [dbo].[inv_list]  FOR DELETE AS 
begin

DECLARE @process_id varchar(10)

if exists (select * from config where flag='TRIG_DEL_INV' and value_str='DISABLE')
	begin
	delete inv_recv from deleted where inv_recv.part_no=deleted.part_no and
		inv_recv.location=deleted.location
	delete inv_xfer from deleted where inv_xfer.part_no=deleted.part_no and
		inv_xfer.location=deleted.location
	delete inv_produce from deleted where inv_produce.part_no=deleted.part_no and
		inv_produce.location=deleted.location
	delete inv_sales from deleted where inv_sales.part_no=deleted.part_no and
		inv_sales.location=deleted.location
	delete inv_substitutes from deleted where inv_substitutes.part_no=deleted.part_no
	delete inv_substitutes from deleted where inv_substitutes.sub_part=deleted.part_no

	return
	end

if exists (select * from inv_master m , deleted l , inv_produce p, inv_sales s,
	inv_xfer x, inv_recv r
	where m.part_no=l.part_no and
	l.part_no=p.part_no and
	l.location=p.location and
	l.part_no=r.part_no and
	l.location=r.location and
	l.part_no=s.part_no and
	l.location=s.location and
	l.part_no=x.part_no and
	l.location=x.location and
	(l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd) != 0 and
	m.status not in ( 'R','V'))					-- mls 1/13/09 SCR 50184
begin
		rollback tran
		exec adm_raiserror 73181, 'You Can Not Delete Inventory With In Stock Quantities!'
		return
	end 

if exists (select * from deleted d,inv_master m, inv_sales s where 
	d.part_no=m.part_no and 
	d.part_no=s.part_no and
	d.location=s.location and
	s.oe_on_order != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73182, 'You Can Not Delete Inventory That Has Open Orders!'

		return
	end 

if exists (select * from deleted d,inv_master m, inv_produce p where 
	d.part_no=m.part_no and
	d.part_no=p.part_no and
	d.location=p.location and
	p.hold_mfg != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73183, 'You Can Not Delete Inventory With On Hold Production Quantities!'
		return
	end 


if exists (select * from deleted d,inv_recv i, inv_master m where 
	d.part_no=m.part_no and
	d.part_no=i.part_no and
	d.location=i.location and
	i.hold_rcv != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73184, 'You Can Not Delete Inventory With On Hold Receiving Quantities!'
		return
	end 
if exists (select * from deleted d,inv_xfer i, inv_master m where 
	d.part_no=m.part_no and
	d.part_no=i.part_no and
	d.location=i.location and
	i.hold_xfr != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73185, 'You Can Not Delete Inventory With On Hold Transfer Quantities!'
		return
	end 
if exists (select * from deleted d,inv_sales i, inv_master m where 
	d.part_no=m.part_no and
	d.part_no=i.part_no and
	d.location=i.location and
	i.hold_ord != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73186, 'You Can Not Delete Inventory With On Hold Orders Quantities!'
		return
	end 

if exists (select * from deleted d,inv_recv i, inv_master m where 
	d.part_no=m.part_no and
	d.part_no=i.part_no and
	d.location=i.location and
	i.po_on_order != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73187, 'You Can Not Delete Inventory With Open Purchase Order Quantities!'
		return
	end

if exists (select * from deleted d,inv_sales i, inv_master m where 
	d.part_no=m.part_no and
	d.part_no=i.part_no and
	d.location=i.location and
	i.commit_ed != 0 and 
	m.status != 'R') begin
		rollback tran
		exec adm_raiserror 73188,'You Can Not Delete Inventory On A Open Order!'
		return
	end 

delete inv_recv from deleted where inv_recv.part_no=deleted.part_no and
	inv_recv.location=deleted.location
delete inv_xfer from deleted where inv_xfer.part_no=deleted.part_no and
	inv_xfer.location=deleted.location
delete inv_produce from deleted where inv_produce.part_no=deleted.part_no and
	inv_produce.location=deleted.location
delete inv_sales from deleted where inv_sales.part_no=deleted.part_no and
	inv_sales.location=deleted.location
delete inv_substitutes from deleted where inv_substitutes.part_no=deleted.part_no
delete inv_substitutes from deleted where inv_substitutes.sub_part=deleted.part_no

end


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insinvl] ON [dbo].[inv_list]  FOR INSERT AS 
begin

        IF (SELECT count(*)
             FROM  inserted    
	     WHERE  inserted.in_stock != 0 OR

                    inserted.hold_qty != 0 ) != 0
         BEGIN
	   ROLLBACK TRAN
	   exec adm_raiserror 83100, 'Inventory Quantities not allowed on Insert. The transaction is being rolled back.'
	   RETURN
	 END

	insert inv_sales (part_no, location, qty_alloc, commit_ed, sales_qty_mtd,                  
		sales_qty_ytd, 	last_order_qty, oe_on_order, 
		sales_amt_mtd, sales_amt_ytd, hold_ord)
	select part_no, location, 0,0,0,0,0,0,0,0,0  from inserted
	if @@error != 0 begin
		rollback tran
		exec adm_raiserror 83103, 'Error Inserting...Failed Insert Into Inv_Sales Table!'
		return
	end
	insert inv_produce (part_no, location, usage_mtd, usage_ytd, qty_scheduled,                  
		produced_mtd, produced_ytd, hold_mfg, sch_alloc)
	select part_no, location, 0,0,0,0,0,0,0 from inserted
	if @@error != 0 begin
		rollback tran
		exec adm_raiserror 83105, 'Error Inserting...Failed Insert Into Inv_Produce Table!'
		return
	end
	insert inv_xfer (part_no, location, commit_ed, xfer_mtd, xfer_ytd, hold_xfr)
	select part_no, location, 0,0,0,0 from inserted
	if @@error != 0 begin
		rollback tran
		exec adm_raiserror 83107, 'Error Inserting...Failed Insert Into Inv_Xfer Table!'
		return
	end
	insert inv_recv (part_no, location, po_on_order, cost, last_cost, recv_mtd,                       
		recv_ytd, hold_rcv)
	select part_no, location, 0,0,0,0,0,0 from inserted
	if @@error != 0 begin
		rollback tran
		exec adm_raiserror 83109, 'Error Inserting...Failed Insert Into Inv_Receiving Table!'
		return
	end

end



GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updinvl] ON [dbo].[inv_list] 
 FOR UPDATE
AS
BEGIN

DECLARE @company_id int, @natcode varchar(8)

if update(part_no) begin
	rollback tran
	exec adm_raiserror 93131, 'You Can Not Change A Part Number!'
	return
end 
	
if exists (select * from config (nolock) where flag='TRIG_UPD_INV' and value_str='DISABLE')  RETURN	-- mls 9/7/00 SCR 20582

DECLARE @xlp int, @iloop int, @retval int
DECLARE @tran_date datetime
DECLARE @part varchar(30), @acct_code varchar(8), @inv_acct varchar(32), @account varchar(32)
DECLARE @inv_direct varchar(32),@inv_ovhd varchar(32), @inv_util varchar(32), @std_inc varchar(32)
DECLARE @inc_direct varchar(32),@inc_ovhd varchar(32), @inc_util varchar(32), @std_dec varchar(32)
DECLARE @dec_direct varchar(32),@dec_ovhd varchar(32), @dec_util varchar(32), @typ char(1),
@std_acct_code VARCHAR(8), @group_part_no VARCHAR(30), @resource_part_no VARCHAR(30),
@use_order INT, @cmp_acct_code VARCHAR(8),
@cmp_direct_dolrs DECIMAL(20,8), @cmp_ovhd_dolrs DECIMAL(20,8), @cmp_util_dolrs DECIMAL(20,8)

DECLARE @in_stock decimal(20,8), @cost decimal(20,8),
@in_status char(1), @in_instock decimal(20,8), @in_void char(1), @in_loc char(10),
@in_std_direct decimal(20,8), @in_std_ovhd decimal(20,8), @in_std_util decimal(20,8), @in_std decimal(20,8),
@dl_status char(1), @dl_instock decimal(20,8), @dl_void char(1), @dl_loc char(10),
@dl_std_direct decimal(20,8), @dl_std_ovhd decimal(20,8), @dl_std_util decimal(20,8), @dl_std decimal(20,8)

DECLARE @x int												-- mls 1/25/01 SCR 20430

SELECT @xlp=isnull((select min(row_id) from inserted),0) 

WHILE @xlp > 0
BEGIN

select @part = part_no, @in_loc = location
from inserted where row_id = @xlp

select @in_status = status, @in_instock = in_stock, @in_void = void, @std_acct_code=acct_code,
@in_std_direct = std_direct_dolrs, @in_std_ovhd = std_ovhd_dolrs, @in_std_util = std_util_dolrs,
@in_std = std_cost, @acct_code = acct_code, @tran_date = getdate()
from inv_list 
where part_no = @part and location = @in_loc

select @dl_status = status, @dl_instock = in_stock, @dl_void = void,
@dl_loc = location, @dl_std_direct = std_direct_dolrs, @dl_std_ovhd = std_ovhd_dolrs, 
@dl_std_util = std_util_dolrs, @dl_std = std_cost
from deleted
where row_id = @xlp


IF not exists (SELECT 1 FROM dbo.inv_master ref (nolock) WHERE ref.part_no = @part)
BEGIN
	exec adm_raiserror 93101 ,'Error Inserting... No inv_list Master Exists For This Part Number!'
	ROLLBACK TRANSACTION
	RETURN
END
if @in_status in ('K','R')
begin
  if exists (select 1 from inv_master m (nolock) where m.part_no = @part and m.lb_tracking='Y') 
  begin
	rollback tran
	exec adm_raiserror 93133 ,'You Can Not Use KITTING/AUTOPRDUCTION That Is Lot/Bin Tracked!'
	return
  end
end	
if @in_status <> @dl_status and @in_status in ('C','V')						-- mls 8/31/00 SCR 24030 start
begin
  if exists (select 1 from inventory inv (nolock)
    where inv.part_no = @part and inv.location = @in_loc and inv.in_stock <> 0)
  begin
	rollback tran
	exec adm_raiserror 93138 ,'You Can Not change a part to Custom Kit or Non-Quantity Bearing with items in stock!'
	return
  end
end	
if @in_status in ('C','V') and @dl_instock <> @in_instock and @in_instock <> 0			-- mls 8/31/00 SCR 24030 end
begin
		rollback tran
		exec adm_raiserror 93138 ,'You Can Not keep In Stock quantities for Custom Kit and Non-Quantity Bearing Items!'
		return
end	
if @in_void = 'V' and @in_void != @dl_void
BEGIN
 delete resource_map_sch
 where resource_map_sch.item_no= @part and resource_map_sch.location= @in_loc
 	
 update what_part 
   set active='V' 
 where what_part.part_no = @part
END

-- ================================================================
-- Check resource group processing
-- ================================================================


-- If someone is trying to change the costs...
IF (@in_std_direct != @dl_std_direct or @in_std_ovhd != @dl_std_ovhd or @in_std_util != @dl_std_util)
and @in_status = 'R'							-- mls 3/2/06 SCR 36256
BEGIN
	-- If we are a group resource
	IF EXISTS(SELECT 1 FROM dbo.resource_group (nolock) WHERE group_part_no = @part)
	BEGIN
		-- What member has precedence
		SELECT	@use_order=MIN(RG.use_order)
		FROM	dbo.resource_group RG (nolock),dbo.inv_list IL (nolock)
		WHERE	RG.group_part_no = @part AND IL.part_no = RG.resource_part_no 
		AND	IL.location = @in_loc

		-- If there is a member...
		IF @use_order IS NOT NULL
		BEGIN
			-- Find the first member of this resource
			SELECT	@resource_part_no=MIN(RG.resource_part_no)
			FROM	dbo.resource_group RG (nolock),
				dbo.inv_list IL (nolock)
			WHERE	RG.group_part_no = @part AND	RG.use_order = @use_order
			AND	IL.part_no = RG.resource_part_no AND	IL.location = @in_loc


			-- Get their costs
			SELECT	@cmp_acct_code=IL.acct_code,
				@cmp_direct_dolrs=IL.std_direct_dolrs,
				@cmp_ovhd_dolrs=IL.std_ovhd_dolrs,
				@cmp_util_dolrs=IL.std_util_dolrs
			FROM	dbo.inv_list IL (nolock)
			WHERE	IL.part_no = @resource_part_no AND	IL.location = @in_loc

			-- If our costs do not match, prevent change
			IF @std_acct_code <> @cmp_acct_code OR 
			@cmp_direct_dolrs <> @in_std_direct OR 
			@cmp_ovhd_dolrs <> @in_std_ovhd OR @cmp_util_dolrs <> @in_std_util
			BEGIN
				ROLLBACK TRANSACTION
				exec adm_raiserror 93134 ,'Changing of a group resource costs must be performed on member resources'
				RETURN
			END
		END
	END

	-- Update any group resources that we belong to...
	SELECT	@group_part_no=MIN(RG.group_part_no)
	FROM	dbo.resource_group RG (nolock)
	WHERE	RG.resource_part_no = @part

	WHILE @group_part_no IS NOT NULL
	BEGIN
		-- Get rest of the information
		SELECT	@use_order=MIN(RG.use_order)
		FROM	dbo.resource_group RG (nolock)
		WHERE	RG.group_part_no = @group_part_no AND	RG.resource_part_no = @part

		-- Does the group resource have a this location
		IF EXISTS(SELECT 1 FROM dbo.inv_list (nolock) WHERE part_no = @group_part_no AND location = @in_loc)
		-- Do any of the earlier members override
		IF NOT EXISTS(	SELECT	1 FROM	dbo.resource_group RG (nolock),
				dbo.inv_list IL (nolock)
			WHERE	RG.group_part_no = @group_part_no
			AND	(	RG.use_order < @use_order
				OR	(	RG.use_order = @use_order AND	RG.resource_part_no < @part ))
			AND	IL.part_no = RG.resource_part_no AND	IL.location = @in_loc)
		BEGIN
			-- At this point, we have changed the member of a resource
			-- group which has the highest control over the resource group
			-- for this location. We need to update the cost on the group
			UPDATE	dbo.inv_list
			SET	acct_code = @std_acct_code,
				std_direct_dolrs=@in_std_direct,
				std_ovhd_dolrs=@in_std_ovhd,
				std_util_dolrs=@in_std_util
			WHERE	location = @in_loc
			AND	part_no = @group_part_no
		END
				
		-- Next resource group
		SELECT	@group_part_no=MIN(RG.group_part_no)
		FROM	dbo.resource_group RG (nolock)
		WHERE	RG.resource_part_no = @part
		AND	RG.group_part_no > @group_part_no
	END
END 

if (@in_std != @dl_std or @in_std_direct != @dl_std_direct or @in_std_ovhd != @dl_std_ovhd or
@in_std_util != @dl_std_util) and @in_status <> 'R'				-- mls 3/2/06 SCR 36256
BEGIN
  if not exists (select 1 from new_cost n where n.part_no = @part and n.location = @in_loc	-- mls 1/25/01 SCR 20430 start
    and n.status = 'W' and n.new_type in ('P','D') and n.curr_unit_cost = @in_std and
    n.curr_direct_dolrs = @in_std_direct and n.curr_ovhd_dolrs = @in_std_ovhd and
    n.curr_util_dolrs = @in_std_util)	
  begin												-- mls 1/25/01 SCR 20430 end
    SELECT @typ = inv_cost_method, 
      @in_stock = (in_stock + hold_ord + hold_xfr)							-- mls 1/25/01 SCR 20430
    FROM inventory (nolock)
    WHERE part_no = @part AND location = @in_loc

    --Default to Average if not in list
    if @typ NOT IN ('A','F','L','W','S') select @typ='A'

    if @typ = 'S' or @in_stock < 0
    BEGIN        
      SELECT @x=count(*) FROM next_new_cost							-- mls 1/25/01 SCR 20430 start

      if @x = 0
      begin
        INSERT next_new_cost (last_no)
        SELECT 0
      end 

      UPDATE next_new_cost
      SET    last_no=last_no + 1
  
      SELECT @x=last_no FROM  next_new_cost

      INSERT new_cost
           ( kys,
             location,
             part_no,
             cost_level,
             new_type,
             new_amt,
             new_direction,
             eff_date,
             who_entered,
             date_entered,
             reason,
             status,
             note,
             apply_date,
	     apply_qty,										
	     prev_unit_cost,							
	     prev_direct_dolrs,
	     prev_ovhd_dolrs,
	     prev_util_dolrs,
	     curr_unit_cost,
	     curr_direct_dolrs,
	     curr_ovhd_dolrs,
	     curr_util_dolrs )									
      SELECT @x, @in_loc, @part, '','M',0,0,getdate(),'',getdate(),'MANUAL STD COST CHG',
           'S', null, getdate(), @in_stock, @dl_std, @dl_std_direct, @dl_std_ovhd,
           @dl_std_util, @in_std, @in_std_direct, @in_std_ovhd, @in_std_util				

      update new_cost
      set status = status
      where kys = @x and row_id = @@identity
      -- this is now done in adm_inv_tran_new_cost
      




    END --IF typ = 'S'
  END -- not on new_cost
END -- IF update(std)

select @xlp=isnull((select min(row_id) from inserted where row_id > @xlp),0)
END --While

END

GO
ALTER TABLE [dbo].[inv_list] ADD CONSTRAINT [CK_inv_list_abc_code_frozen_flag] CHECK (([abc_code_frozen_flag]=(1) OR [abc_code_frozen_flag]=(0)))
GO

CREATE NONCLUSTERED INDEX [locstatIncPart_idx] ON [dbo].[inv_list] ([location], [status]) INCLUDE ([part_no]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invl_loc1] ON [dbo].[inv_list] ([part_no], [location]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invl_locst] ON [dbo].[inv_list] ([part_no], [location], [status]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_list] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_list] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_list] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_list] TO [public]
GO
