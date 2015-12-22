CREATE TABLE [dbo].[inv_master]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[upc_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sku_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_status_14__13] DEFAULT ('A'),
[cubic_feet] [decimal] (20, 8) NOT NULL,
[weight_ea] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comm_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_void_18__13] DEFAULT ('N'),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[entered_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[entered_date] [datetime] NULL,
[std_cost] [decimal] (20, 8) NULL CONSTRAINT [DF_inv_master_std_cost_15__13] DEFAULT ((0)),
[utility_cost] [decimal] (20, 8) NULL CONSTRAINT [DF_inv_master_utility_co17__13] DEFAULT ((0)),
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_qc_flag_7__13] DEFAULT ('N'),
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_lb_tracking3__13] DEFAULT ('N'),
[rpt_uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[freight_unit] [decimal] (20, 8) NULL,
[taxable] [int] NULL CONSTRAINT [DF_inv_master_taxable_16__13] DEFAULT ((0)),
[freight_class] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL CONSTRAINT [DF_inv_master_conv_factor1__13] DEFAULT ((1)),
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cycle_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inv_cost_method] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_inv_cost_me2__13] DEFAULT ('A'),
[buyer] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cfg_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_inv_master_cfg_flag_1__10] DEFAULT ('N'),
[allow_fractions] [smallint] NULL CONSTRAINT [DF_inv_master_allow_fract1__13] DEFAULT ((1)),
[tax_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[obsolete] [smallint] NULL CONSTRAINT [DF_inv_master_obsolete_1__10] DEFAULT ((0)),
[serial_flag] [smallint] NULL CONSTRAINT [DF_inv_master_serial_flag_1_10] DEFAULT ((0)),
[web_saleable_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_inv_master_web_saleable_flg] DEFAULT ('N'),
[reg_prod] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_inv_master_reg_prod] DEFAULT ((0)),
[warranty_length] [int] NULL,
[call_limit] [int] NULL,
[yield_pct] [decimal] (5, 2) NULL CONSTRAINT [DF_inv_master_yield_pct] DEFAULT ((100)),
[tolerance_cd] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pur_prod_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_inv_master_pur_prod_flag] DEFAULT ('N'),
[sales_order_hold_flag] [int] NOT NULL CONSTRAINT [DF_inv_master_sales_order_hold_flag] DEFAULT ((0)),
[abc_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[abc_code_frozen_flag] [int] NOT NULL CONSTRAINT [DF_inv_master_abc_code_frozen_flag] DEFAULT ((0)),
[country_code] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cmdty_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[height] [decimal] (20, 8) NOT NULL,
[width] [decimal] (20, 8) NOT NULL,
[length] [decimal] (20, 8) NOT NULL,
[min_profit_perc] [smallint] NULL,
[sku_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eprocurement_flag] [int] NULL CONSTRAINT [DF__inv_maste__eproc__42A229A6] DEFAULT ((0)),
[non_sellable_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_maste__non_s__43964DDF] DEFAULT ('N'),
[so_qty_increment] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE TRIGGER [dbo].[EAI_inv_master_insupddel] ON [dbo].[inv_master]   FOR INSERT, UPDATE, DELETE  AS 
BEGIN
	DECLARE @item_id varchar(30), @data varchar(40)
	Declare @send_document_flag char(1)  -- rev 4

	select @send_document_flag = 'N'

	if exists( SELECT * FROM config WHERE flag = 'EAI' and value_str like 'Y%') begin	-- EAI is enabled
		if ( (exists(select distinct 'X' from inserted i, deleted d
			where 	((i.part_no <> d.part_no) or
				(i.description <> d.description) or
				(i.weight_ea <> d.weight_ea) or
				(i.cubic_feet <> d.cubic_feet) or
				(i.status <> d.status) or
				(i.uom <> d.uom) or
				(i.taxable <> d.taxable) or
				(i.tax_code <> d.tax_code) or
				(i.serial_flag <> d.serial_flag) or
				(i.note <> d.note) or
				(i.void <> d.void) or
				(i.call_limit <> d.call_limit) or
				(i.pur_prod_flag <> d.pur_prod_flag) or
				(i.reg_prod <> d.reg_prod) or
				(i.warranty_length <> d.warranty_length) or
				(i.category <> d.category) or
				(i.void <> d.void))
				AND (i.status not in ('R')) ))
				-- can't be a custom kit or resource
				or (Not Exists(select 'X' from deleted) and 
					not exists (select 'X' from inserted i where i.status in ('R')))
				or (Not Exists(select 'X' from inserted) and 
					not exists (select 'X' from deleted d where d.status in ('R'))))
		begin	-- inv_master has been inserted or updated, send data to Front Office
			select @send_document_flag = 'Y'
		end else
		begin
			If (Update(description) or Update(weight_ea) or Update(cubic_feet) or
			   Update(status) or Update(uom) or Update(taxable) or Update(tax_code) or Update(serial_flag) or
			   Update(note) or Update(void) or Update(call_limit) or Update(pur_prod_flag) or Update(reg_prod) or
			   Update(warranty_length) or Update(category) or Update(void)) and
			   (exists (select 'X' from inserted i where i.status not in ('R')))
			begin
				select @send_document_flag = 'Y'
			end		
		end

		if @send_document_flag = 'Y' begin
			if (exists(select 'X' from inserted)) begin	-- insert or update
				select distinct @item_id = min(part_no) from inserted 
			end
			else begin	-- deleted 
				select distinct @item_id = min(part_no) from deleted 
			end

			while (@item_id > '') begin
				select @data = @item_id + '|0'	-- not a service agreement
				exec EAI_process_insert 'Part', @data, 'BO'

				if (exists(select 'X' from inserted)) begin	-- insert or update
					select distinct @item_id = min(part_no) from inserted
						where part_no > @item_id and inserted.status not in ('R')
				end
				else begin		-- deleted 
					select distinct @item_id = min(part_no) from deleted
						where part_no > @item_id and deleted.status not in ('R')
				end
			end
		end
	END
END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE trigger [dbo].[inv_master_insert_trg] on [dbo].[inv_master]
for insert
as 


if exists (select 1 from inserted where inv_cost_method = 'E')
begin
  if not exists (select 1 from config (nolock) where flag = 'INV_LOT_BIN' and value_str like 'Y%')
  begin
    rollback tran
    exec adm_raiserror 931341, 'You Can Not do lot/serial costing when you are not lot bin tracking.'
    return
  end
end

insert EFORECAST_PRODUCT (PART, [NAME], PART_NO, LEADTIME, FORECAST_FLAG, SUPPLIER,					--v1.0
						  BRAND, ITEM_TYPE, COMMODITY)												--v1.0
select part_no, Substring(description,1,30), part_no, '0', 0, substring(v.vendor_name,1,30),
		category, type_code, cmdty_code																-- v1.0
from 	inserted i, apvend v
where	status in ('C' , 'H' , 'K' , 'M' , 'P' )
and i.vendor = v.vendor_code 

if @@error <>0 
  begin
	rollback tran
	exec adm_raiserror 91353, 'Error inserting a record in EFORECAST_PRODUCT'
  end

insert inv_master_add (part_no)
select part_no
from inserted i
where status != 'R' and not exists (select 1 from inv_master_add a where a.part_no = i.part_no)

if @@error <>0 
  begin
	rollback tran
	exec adm_raiserror 91353, 'Error inserting a record in EFORECAST_PRODUCT'
  end


-- END restore trigger




GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[inv_master_integration_del_trg]
	ON [dbo].[inv_master]
	FOR DELETE AS
BEGIN
	INSERT INTO epintegrationrecs 
	SELECT part_no, '', 2, 'D', 0 
	FROM Deleted
	WHERE eprocurement_flag = 1
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[inv_master_integration_ins_trg]
	ON [dbo].[inv_master]
	FOR INSERT AS
BEGIN
	INSERT INTO epintegrationrecs 
	SELECT part_no, '', 2, 'I', 0 
	FROM Inserted
	WHERE eprocurement_flag = 1
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


/*                                                      
               Confidential Information                 
    Limited Distribution of Authorized Persons Only     
    Created 2005 and Protected as Unpublished Work      
          Under the U.S. Copyright Act of 1976          
 Copyright (c) 2005 Epicor Software Corporation, 2005   
                  All Rights Reserved                   
*/

CREATE TRIGGER [dbo].[inv_master_integration_upd_trg]
	ON [dbo].[inv_master]
	FOR UPDATE AS
BEGIN	
	DELETE EP
	FROM epintegrationrecs EP
		INNER JOIN Inserted INS ON EP.id_code = INS.part_no
	WHERE EP.action = 'U' AND EP.type = 2 

	
	INSERT INTO epintegrationrecs 
	SELECT part_no, '', 2, 'U', 0 
	FROM Inserted
	WHERE eprocurement_flag = 1
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500delinvm] ON [dbo].[inv_master]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_INVM' and value_str='DISABLE')
 	return
else
	begin
	rollback tran
	exec adm_raiserror 73099 ,'You Can Not Delete An INV_MASTER!' 
	return
	end
end


GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t604updinvm] ON [dbo].[inv_master]   FOR UPDATE  AS 
BEGIN
if update(part_no) begin
	rollback tran
	exec adm_raiserror 93031, 'You Can Not Change A Part Number!'
	return
end 
if exists (select * from config where flag='TRIG_UPD_INVM' and value_str='DISABLE')  RETURN

create table #lots (lot_ser varchar(255), qty decimal(20,8), row_id int identity(1,1))
create table #lot1 (lot_ser varchar(255), qty decimal(20,8), row_id int identity(1,1))

DECLARE @part_no varchar(30)

DECLARE @in_qc_flag char(1), @in_lb_tracking char(1), @in_status char(1), @in_inv_cost_method char(1),
@in_void char(1), @in_uom char(2), @in_obsolete int, @in_void_who varchar(20), @in_void_date datetime

DECLARE @dl_qc_flag char(1), @dl_lb_tracking char(1), @dl_status char(1), @dl_inv_cost_method char(1),
@dl_void char(1), @dl_uom char(2), @dl_obsolete int

declare @account varchar(20), @use_std char(1), @location varchar(10), @x int,
  @avg_unit_cost decimal(20,8), @avg_direct_dolrs decimal(20,8), @avg_ovhd_dolrs decimal(20,8),
  @avg_util_dolrs decimal(20,8), @labor decimal(20,8), @qty decimal (20,8),
  @std_unit_cost decimal(20,8), @std_direct_dolrs decimal(20,8), @std_ovhd_dolrs decimal(20,8),
  @std_util_dolrs decimal(20,8)

select @part_no = isnull((select min(part_no) from inserted),NULL)

while @part_no is not NULL
begin
  select @in_qc_flag = qc_flag, @in_lb_tracking = lb_tracking, @in_status = status,
    @in_inv_cost_method = inv_cost_method, @in_uom = uom, @in_obsolete = obsolete,
    @in_void_who = void_who, @in_void_date = void_date,
    @in_void = void								-- mls 1/18/02 SCR 28195
  from inv_master
  where part_no = @part_no

  select @dl_qc_flag = qc_flag, @dl_lb_tracking = lb_tracking, @dl_status = status,
    @dl_inv_cost_method = inv_cost_method, @dl_uom = uom, @dl_obsolete = obsolete,
    @dl_void = void								-- mls 1/18/02 SCR 28195
  from deleted
  where part_no = @part_no

  if @in_uom != @dl_uom
  BEGIN
    if exists (select 1 from inventory i where i.part_no = @part_no and
      (i.in_stock <> 0 OR i.commit_ed <> 0 OR  i.hold_qty <> 0 OR i.hold_ord <> 0 OR i.hold_mfg <> 0 OR
       i.hold_rcv <> 0 OR i.hold_xfr <> 0 or i.sch_alloc <> 0 or i.transit <> 0 or i.qty_alloc <> 0 ))	-- mls 3/3/03 SCR 30627
    begin
      rollback tran
      exec adm_raiserror 93135, 'You Can Not Change Unit of Measure On Items With Stock, Committed, Or Hold Qty!  Use Issues To Relieve Stock First.'
      return
    end
    if exists (select * from inv_xfer i where i.part_no = @part_no and i.commit_ed <> 0 ) 	-- mls 3/3/03 SCR 30627
    begin
      rollback tran
      exec adm_raiserror 93137, 'You Can Not Change Unit of Measure On Items That Are On Transfers!'
      return
    end 
    if exists (select * from inv_recv i where i.part_no = @part_no and i.po_on_order <> 0 ) 
    begin
      rollback tran
      exec adm_raiserror 93137, 'You Can Not Change Unit of Measure On Items That Are On Purchase Orders!'
      return
    end 

    update what_part						-- mls 3/3/03 SCR 30627
    set uom = @in_uom
    where part_no = @part_no
  END

  if @in_void != @dl_void
  begin
    UPDATE inv_list SET
      void= @in_void,
      void_who= @in_void_who,
      void_date= @in_void_date
    WHERE  part_no =  @part_no and void != @in_void
  end

  if @in_status != @dl_status
  begin
    if @in_status in ('C','V')
    begin
      if exists (select 1 from inv_list l (nolock),inv_produce p (nolock), 
        inv_sales s (nolock), inv_xfer x (nolock), inv_recv r (nolock)
        where l.part_no = @part_no and l.part_no=p.part_no and l.location=p.location and l.part_no=r.part_no and
        l.location=r.location and l.part_no=s.part_no and l.location=s.location and l.part_no=x.part_no and
        l.location=x.location AND (s.commit_ed <> 0 OR  l.hold_qty <> 0 OR s.hold_ord <> 0 OR p.hold_mfg <> 0 OR
        (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd <> 0) OR          
         r.hold_rcv <> 0 OR x.hold_xfr <> 0 ) )
      begin
        rollback tran
        exec adm_raiserror 93139 ,'You Can Not Change Status to Custom Kit or Non-Quantity Bearing On Items With Stock, Committed, Or Hold Qty!  Use Issues To Relieve Stock First.'
        return
      end
      if exists (select 1 from inv_sales i where i.part_no = @part_no and i.oe_on_order <> 0 ) 
      begin
        rollback tran
        exec adm_raiserror 93140 ,'You Can Not Change Status to Custom Kit or Non-Quantity Bearing On Items That Are On A Customers ORDER!'
        return
      end 
      if exists (select 1 from inv_recv i where i.part_no = @part_no and i.po_on_order <> 0 ) 
      begin
        rollback tran
        exec adm_raiserror 93141 ,'You Can Not Change Status to Custom Kit or Non-Quantity Bearing On Items That Are On Purchase Orders!'
        return
      end 
      if @in_status = 'V'						-- mls 6/15/04 SCR 33013
      begin 
        if exists (select 1 from what_part w (nolock)
	  join inv_master m (nolock) on m.part_no = w.asm_no
          where w.part_no = @part_no and m.status in ('C','K'))	
        begin
          rollback tran
          exec adm_raiserror 93142 ,'You Can Not Change Status to Non-Quantity Bearing On Items That Are On Kit Build Plans!'
          return
        end
      end
      if @in_status = 'C'
      begin 
        if exists (select 1 from what_part w (nolock)
	  join inv_master m (nolock) on m.part_no = w.asm_no
          where w.part_no = @part_no)	-- mls 6/15/04 SCR 33013
        begin
          rollback tran
          exec adm_raiserror 93142 ,'You Can Not Change Status to Custom Kit On Items That Are On Build Plans!'
          return
        end
      end
    end

    UPDATE inv_list 
    SET status= @in_status
    WHERE  part_no =  @part_no and status != @in_status

    if @in_status = 'H'
    begin
      UPDATE what_part
      SET constrain='N'
      WHERE asm_no = @part_no and constrain = 'Y' 
    end
    else
    begin
      UPDATE what_part
      SET plan_pcs=0, lag_qty=0
      WHERE asm_no = @part_no and ( plan_pcs != 0 or lag_qty != 0 )
    end
  END

  if @in_lb_tracking != @dl_lb_tracking
  BEGIN
    if exists (select 1 from inventory i where i.part_no = @part_no and (i.in_stock <> 0 OR i.commit_ed <> 0 OR i.hold_qty <> 0 ))
    begin
      rollback tran
      exec adm_raiserror 93132 ,'You Can Not Change Lot Bin Tracking On Items With Stock, Committed, Or Hold Qty!  Use Issues To Relieve Stock First.'
      return
    end
    if exists (select 1 from inv_sales i where i.part_no = @part_no and i.oe_on_order <> 0 ) 
    begin
      rollback tran
      exec adm_raiserror 93133 ,'You Can Not Change inv_list Lot/Bin Tracking That Is On A Customers ORDER!'
      return
    end 
    if exists (select 1 from inv_recv i where i.part_no = @part_no and i.po_on_order <> 0 ) 
    begin
      rollback tran
      exec adm_raiserror 93134 ,'You Can Not Change inv_list Lot/Bin Tracking That Is On Purchase Order!'
      return
    end 
  END

  if @in_inv_cost_method != @dl_inv_cost_method and @in_status != 'R'
  begin
    select @account=isnull((select value_str from config where flag='INV_STOCK_ACCOUNT'),'STOCK')

    delete from inv_costing  
    where inv_costing.part_no=@part_no
 
    select @use_std = 'N'
    if @in_inv_cost_method = 'S' or @dl_inv_cost_method = 'S'	
    begin
      select @use_std = 'Y'
    end

    if @in_inv_cost_method = 'E'
    begin
      if not exists (select 1 from config(nolock) where flag = 'INV_LOT_BIN' and value_str like 'Y%')
      begin
        rollback tran
        exec adm_raiserror 931341 ,'You Can Not do lot/serial costing when you are not lot bin tracking.'
        return
      end
    end       

    select @location = isnull((select min(location) from inventory
      where part_no = @part_no and (in_stock + hold_ord + hold_xfr) != 0),NULL)

    while @location is not NULL
    begin
      select @avg_unit_cost = i.avg_cost,
        @avg_direct_dolrs = i.avg_direct_dolrs,
        @avg_ovhd_dolrs = i.avg_ovhd_dolrs,
        @avg_util_dolrs = i.avg_util_dolrs,
        @std_unit_cost = i.std_cost,
        @std_direct_dolrs = i.std_direct_dolrs,
        @std_ovhd_dolrs = i.std_ovhd_dolrs,
        @std_util_dolrs = i.std_util_dolrs,
        @labor = i.labor,
        @qty = (i.in_stock + i.hold_ord + i.hold_xfr)
      from inventory i
      where i.part_no = @part_no and i.location = @location
   
      if @in_inv_cost_method != 'E'
      begin
        insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext,tran_line,account,
          tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,labor,util_dolrs, org_cost) 
        select @part_no, @location, 1, @in_inv_cost_method, 0, 0, 0, @account, getdate(),
          getdate(), 
          isnull(case @use_std when 'N' then @avg_unit_cost else @std_unit_cost end,0),
          @qty, @qty,
          isnull(case @use_std when 'N' then @avg_direct_dolrs else @std_direct_dolrs end,0),
          isnull(case @use_std when 'N' then @avg_ovhd_dolrs else @std_ovhd_dolrs end,0), 
          isnull(@labor,0), 
          isnull(case @use_std when 'N' then @avg_util_dolrs else @std_util_dolrs end,0), 
          isnull(case @use_std when 'N' then @avg_unit_cost else @std_unit_cost end,0)
      end
      else
      begin

        delete from #lots
        insert #lot1 (lot_ser, qty)
        select lot_ser, sum(qty)
        from lot_bin_stock
        where part_no = @part_no and location = @location
        group by lot_ser

        insert #lot1 (lot_ser, qty)
        select lot_ser, sum(qty)
        from lot_bin_ship s
        join ord_list o on o.order_no = s.tran_no and o.order_ext = s.tran_ext and o.status between 'P' and 'R'
          and o.line_no = s.line_no and o.ordered != 0
        where s.part_no = @part_no and s.location = @location
        group by lot_ser

        insert #lot1 (lot_ser, qty)
        select s.lot_ser, sum(qty)
        from lot_bin_xfer s
        join xfer_list x on x.xfer_no = s.tran_no and x.status between 'P' and 'Q'
          and x.line_no = s.line_no
        where s.part_no = @part_no and s.location = @location
        group by s.lot_ser

        insert #lots (lot_ser,qty)
        select lot_ser, sum(qty)
        from #lot1
        group by lot_ser

        insert into inv_costing (part_no,location,sequence,tran_code,tran_no,tran_ext,tran_line,account,
          tran_date,tran_age,unit_cost,quantity,balance,direct_dolrs,ovhd_dolrs,labor,util_dolrs, org_cost, lot_ser) 
        select @part_no, @location, row_id, @in_inv_cost_method, 0, 0, 0, @account, getdate(),
          getdate(), 
          isnull(case @use_std when 'N' then @avg_unit_cost else @std_unit_cost end,0),
          qty, qty,
          isnull(case @use_std when 'N' then @avg_direct_dolrs else @std_direct_dolrs end,0),
          isnull(case @use_std when 'N' then @avg_ovhd_dolrs else @std_ovhd_dolrs end,0), 
          isnull(@labor,0), 
          isnull(case @use_std when 'N' then @avg_util_dolrs else @std_util_dolrs end,0), 
          isnull(case @use_std when 'N' then @avg_unit_cost else @std_unit_cost end,0),
          lot_ser
        from #lots
      end

      if @in_inv_cost_method = 'S'
      begin
        SELECT @x=count(*) FROM next_new_cost						

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
        SELECT @x, @location, @part_no, '','M',0,0,getdate(),'',getdate(),
          'COST MTHD CHGD TO S',
          'M', null, getdate(), @qty, @avg_unit_cost, @avg_direct_dolrs, @avg_ovhd_dolrs,
          @avg_util_dolrs, @std_unit_cost, @std_direct_dolrs, @std_ovhd_dolrs, @std_util_dolrs				

        Update new_cost
        set status = 'P'
        where kys = @x and row_id = @@identity							
      END --IF typ = 'S'

      select @location = isnull((select min(location) from inventory
        where part_no = @part_no and location > @location and (in_stock + hold_ord + hold_xfr) != 0),NULL)
    end
  end 
  
  if @in_obsolete != @dl_obsolete and @in_obsolete = 1
  BEGIN
    DELETE resource_demand
    WHERE part_no = @part_no
  END

  select @part_no = isnull((select min(part_no) from inserted where part_no > @part_no),NULL)
END -- while
END
GO
ALTER TABLE [dbo].[inv_master] ADD CONSTRAINT [CK_inv_master_abc_code_frozen_flag] CHECK (([abc_code_frozen_flag]=(1) OR [abc_code_frozen_flag]=(0)))
GO
ALTER TABLE [dbo].[inv_master] ADD CONSTRAINT [inv_master_pur_prod_flag_cc1] CHECK (([pur_prod_flag]='N' OR [pur_prod_flag]='Y'))
GO
ALTER TABLE [dbo].[inv_master] ADD CONSTRAINT [CK_inv_master_sales_order_hold_flag] CHECK (([sales_order_hold_flag]=(1) OR [sales_order_hold_flag]=(0)))
GO
ALTER TABLE [dbo].[inv_master] ADD CONSTRAINT [CK_inv_master_4] CHECK (([web_saleable_flag]='Y' OR [web_saleable_flag]='N'))
GO
ALTER TABLE [dbo].[inv_master] ADD CONSTRAINT [inv_master_yield_pct_cc1] CHECK (([yield_pct]>=(0) AND [yield_pct]<=(100)))
GO
CREATE NONCLUSTERED INDEX [invcat1] ON [dbo].[inv_master] ([category]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_idx2] ON [dbo].[inv_master] ([category], [type_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invdesc] ON [dbo].[inv_master] ([description]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invm1] ON [dbo].[inv_master] ([part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_master_ind1] ON [dbo].[inv_master] ([part_no], [timestamp]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [idx_invm_void] ON [dbo].[inv_master] ([part_no], [void]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_master_idx4_tag_050813] ON [dbo].[inv_master] ([type_code]) INCLUDE ([part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invupc] ON [dbo].[inv_master] ([upc_code]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [inv_master_idx3_tag_042213] ON [dbo].[inv_master] ([void], [lb_tracking], [uom]) INCLUDE ([part_no]) ON [PRIMARY]
GO
CREATE STATISTICS [_dta_stat_1101923693_2_8] ON [dbo].[inv_master] ([part_no], [type_code])
GO
CREATE STATISTICS [_dta_stat_1101923693_11_2] ON [dbo].[inv_master] ([weight_ea], [part_no])
GO
GRANT REFERENCES ON  [dbo].[inv_master] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_master] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_master] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_master] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_master] TO [public]
GO
