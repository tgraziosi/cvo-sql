CREATE TABLE [dbo].[inv_costing]
(
[timestamp] [timestamp] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence] [int] NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[tran_line] [int] NOT NULL,
[tran_date] [datetime] NOT NULL,
[tran_age] [datetime] NOT NULL,
[unit_cost] [decimal] (20, 8) NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[balance] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[labor] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[account] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_cost] [decimal] (20, 8) NOT NULL,
[audit] [int] NOT NULL IDENTITY(1, 1),
[tot_mtrl_cost] [decimal] (20, 8) NULL,
[tot_dir_cost] [decimal] (20, 8) NULL,
[tot_ovhd_cost] [decimal] (20, 8) NULL,
[tot_util_cost] [decimal] (20, 8) NULL,
[tot_labor_cost] [decimal] (20, 8) NULL,
[lot_ser] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__inv_costi__lot_s__2216F531] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t503delinvcost] ON [dbo].[inv_costing] FOR delete AS 
BEGIN

DECLARE @d_part_no varchar(30), @d_location varchar(10), @d_sequence int, @d_tran_code char(1),
@d_tran_no int, @d_tran_ext int, @d_tran_line int, @d_tran_date datetime, @d_tran_age datetime,
@d_unit_cost decimal(20,8), @d_quantity decimal(20,8), @d_balance decimal(20,8),
@d_direct_dolrs decimal(20,8), @d_ovhd_dolrs decimal(20,8), @d_labor decimal(20,8),
@d_util_dolrs decimal(20,8), @d_account varchar(10), @d_org_cost decimal(20,8), @d_audit int,
@d_tot_mtrl_cost decimal(20,8), @d_tot_dir_cost decimal(20,8), @d_tot_ovhd_cost decimal(20,8),
@d_tot_util_cost decimal(20,8), @d_tot_labor_cost decimal(20,8)

declare @d_lot_ser varchar(255)

declare @qty decimal(20,8),@stock_acct varchar(10)
declare @avg_cost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8),		-- mls 6/5/01 SCR 27031
@tot_mtrl_cost decimal(20,8), @tot_dir_cost decimal(20,8), @tot_ovhd_cost decimal(20,8), @tot_util_cost decimal(20,8)

select @stock_acct='STOCK'

DECLARE t700delinv__cursor CURSOR LOCAL STATIC FOR
SELECT d.part_no, d.location, d.sequence, d.tran_code, d.tran_no, d.tran_ext, d.tran_line,
d.tran_date, d.tran_age, d.unit_cost, d.quantity, d.balance, d.direct_dolrs, d.ovhd_dolrs,
d.labor, d.util_dolrs, d.account, d.org_cost, d.audit, d.tot_mtrl_cost, d.tot_dir_cost,
d.tot_ovhd_cost, d.tot_util_cost, d.tot_labor_cost, d.lot_ser
from deleted d
where account = @stock_acct

OPEN t700delinv__cursor

if @@cursor_rows = 0
begin
CLOSE t700delinv__cursor
DEALLOCATE t700delinv__cursor
return
end

FETCH NEXT FROM t700delinv__cursor into
@d_part_no, @d_location, @d_sequence, @d_tran_code, @d_tran_no, @d_tran_ext, @d_tran_line,
@d_tran_date, @d_tran_age, @d_unit_cost, @d_quantity, @d_balance, @d_direct_dolrs,
@d_ovhd_dolrs, @d_labor, @d_util_dolrs, @d_account, @d_org_cost, @d_audit, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost, @d_lot_ser

While @@FETCH_STATUS = 0
begin




  if not exists (select 1 from inv_master (nolock) where part_no = @d_part_no and inv_cost_method = 'A')		-- mls 7/14/00 SCR 23527 start
  begin
    select @avg_cost = NULL, @direct = NULL, @overhead = NULL, @utility = NULL				-- mls 6/5/01 SCR 27031 start
    select @qty = NULL
    select @qty= sum( balance ), 
      @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),
      @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),
      @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
      @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance))
    from inv_costing 
    where part_no= @d_part_no and location = @d_location and account=@stock_acct
    

    if isnull(@qty,0) != 0 
    begin
      select @avg_cost = @tot_mtrl_cost / @qty,
        @direct = @tot_dir_cost / @qty,
        @overhead = @tot_ovhd_cost / @qty,
        @utility = @tot_util_cost / @qty

      if exists (select 1 from inv_list (nolock)
        where part_no = @d_part_no and location = @d_location and 
         (avg_cost != isnull(@avg_cost,avg_cost) or avg_direct_dolrs != isnull(@direct,avg_direct_dolrs) or 
          avg_ovhd_dolrs != isnull(@overhead,avg_ovhd_dolrs) or avg_util_dolrs != isnull(@utility,avg_util_dolrs)))
      begin
        update inv_list set avg_cost=abs(isnull(@avg_cost,avg_cost)),
          avg_direct_dolrs = abs(isnull(@direct, avg_direct_dolrs)),
          avg_ovhd_dolrs = abs(isnull(@overhead, avg_ovhd_dolrs)),
          avg_util_dolrs = abs(isnull(@utility, avg_util_dolrs))
        where location=@d_location and part_no=@d_part_no
      end														-- mls 6/5/01 SCR 27031 end
    end 
  end													-- mls 7/14/00 SCR 23527 end

  
  insert inv_cost_history (part_no,location,ins_del_flag,tran_code,tran_no,tran_ext,tran_line,
    tran_date,tran_age,account,unit_cost,quantity,inv_cost_bal,direct_dolrs,ovhd_dolrs,
    labor,util_dolrs,audit,org_cost,tot_mtrl_cost,tot_dir_cost,tot_ovhd_cost,tot_util_cost,tot_labor_cost,
    lot_ser) 
  select @d_part_no,@d_location,1,@d_tran_code,@d_tran_no,@d_tran_ext,@d_tran_line,
    @d_tran_date,@d_tran_age,@d_account,@d_unit_cost,@d_quantity,0,@d_direct_dolrs,@d_ovhd_dolrs,
    @d_labor,@d_util_dolrs,@d_audit,@d_org_cost ,
    @d_tot_mtrl_cost, @d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost ,
    @d_lot_ser

FETCH NEXT FROM t700delinv__cursor into
@d_part_no, @d_location, @d_sequence, @d_tran_code, @d_tran_no, @d_tran_ext, @d_tran_line,
@d_tran_date, @d_tran_age, @d_unit_cost, @d_quantity, @d_balance, @d_direct_dolrs,
@d_ovhd_dolrs, @d_labor, @d_util_dolrs, @d_account, @d_org_cost, @d_audit, @d_tot_mtrl_cost,
@d_tot_dir_cost, @d_tot_ovhd_cost, @d_tot_util_cost, @d_tot_labor_cost, @d_lot_ser
end -- while

CLOSE t700delinv__cursor
DEALLOCATE t700delinv__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t503insinvcost] ON [dbo].[inv_costing] FOR insert AS 
BEGIN

DECLARE @i_part_no varchar(30), @i_location varchar(10), @i_sequence int, @i_tran_code char(1),
@i_tran_no int, @i_tran_ext int, @i_tran_line int, @i_tran_date datetime, @i_tran_age datetime,
@i_unit_cost decimal(20,8), @i_quantity decimal(20,8), @i_balance decimal(20,8),
@i_direct_dolrs decimal(20,8), @i_ovhd_dolrs decimal(20,8), @i_labor decimal(20,8),
@i_util_dolrs decimal(20,8), @i_account varchar(10), @i_org_cost decimal(20,8), @i_audit int,
@i_tot_mtrl_cost decimal(20,8), @i_tot_dir_cost decimal(20,8), @i_tot_ovhd_cost decimal(20,8),
@i_tot_util_cost decimal(20,8), @i_tot_labor_cost decimal(20,8),
@qty decimal(20,8), @stock_acct varchar(10),
@avgc decimal(20,8), @dirc decimal(20,8),@ovhc decimal(20,8), @utlc decimal(20,8),
@qty2 decimal(20,8), @zero_ind decimal(20,8),				-- mls 9/2/04 SCR 33101
									-- mls 12/11/02 SCR 29565	
@tot_mtrl_cost decimal(20,8), @tot_dir_cost decimal(20,8), @tot_ovhd_cost decimal(20,8), @tot_util_cost decimal(20,8),
@r_cost decimal(20,8), @r_direct decimal(20,8), @r_overhead decimal(20,8), @r_utility decimal(20,8),	
@avg_cost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8),			-- mls 6/5/01 SCR 27031
@max_seq int

select @stock_acct='STOCK'

DECLARE t700insinv__cursor CURSOR LOCAL STATIC FOR
SELECT i.part_no, i.location, i.sequence, i.tran_code, i.tran_no, i.tran_ext, i.tran_line,
i.tran_date, i.tran_age, i.unit_cost, i.quantity, i.balance, i.direct_dolrs, i.ovhd_dolrs,
i.labor, i.util_dolrs, i.account, i.org_cost, i.audit, i.tot_mtrl_cost, i.tot_dir_cost,
i.tot_ovhd_cost, i.tot_util_cost, i.tot_labor_cost
from inserted i
where account in (@stock_acct,'ADJUST')

OPEN t700insinv__cursor

if @@cursor_rows = 0
begin
CLOSE t700insinv__cursor
DEALLOCATE t700insinv__cursor
return
end

FETCH NEXT FROM t700insinv__cursor into
@i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
@i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
@i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost

While @@FETCH_STATUS = 0
begin
  select @qty = NULL,@avg_cost = NULL, @direct = NULL, @overhead = NULL, @utility = NULL	-- mls 6/5/01 SCR 27031 start

  select @qty= sum( balance ), @qty2 = sum(abs(balance)) ,
      @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),
      @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),
      @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
      @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance)),
      @max_seq = max(case when account = @stock_acct then sequence else 0 end)
  from inv_costing 
  where part_no = @i_part_no and location = @i_location and account in (@stock_acct,'ADJUST')

  select @qty = isnull(@qty,0), @qty2 = isnull(@qty2,0)

  --Case negative cost offset with positive cost, need to convert all cost to positive
  select @zero_ind = @qty

  --Case negative cost offset with positive cost, need to convert all cost to positive
  if ( @qty = 0 ) 
    select @qty = @qty2

  if @qty != 0
  begin
    select @avg_cost = @tot_mtrl_cost / @qty,
      @direct = @tot_dir_cost / @qty,
      @overhead = @tot_ovhd_cost / @qty,
      @utility = @tot_util_cost / @qty

    if @zero_ind != 0
    begin
      if exists (select 1 from inv_list (nolock)
        where part_no = @i_part_no and location = @i_location and 
         (avg_cost != isnull(@avg_cost,avg_cost) or avg_direct_dolrs != isnull(@direct,avg_direct_dolrs) or 
          avg_ovhd_dolrs != isnull(@overhead,avg_ovhd_dolrs) or avg_util_dolrs != isnull(@utility,avg_util_dolrs)))
      begin
        update inv_list set avg_cost=abs(isnull(@avg_cost,avg_cost)),
          avg_direct_dolrs = abs(isnull(@direct, avg_direct_dolrs)),
          avg_ovhd_dolrs = abs(isnull(@overhead, avg_ovhd_dolrs)),
          avg_util_dolrs = abs(isnull(@utility, avg_util_dolrs))
        where location=@i_location and part_no=@i_part_no
      end
    end														-- mls 6/5/01 SCR 27031 end
  end 

  
  

  if exists (select 1 from inv_master m (nolock) where part_no = @i_part_no and inv_cost_method = 'A')
    and @zero_ind != 0
  begin
    select 
      @avgc = avg_cost, 
      @dirc = avg_direct_dolrs,
      @ovhc = avg_ovhd_dolrs, 
      @utlc = avg_util_dolrs
    from inv_list l (nolock)
    where l.part_no = @i_part_no and l.location = @i_location

    select @r_cost = @tot_mtrl_cost - (@avgc * @qty),
      @r_direct = @tot_dir_cost - (@dirc * @qty),
      @r_overhead = @tot_ovhd_cost - (@ovhc * @qty),
      @r_utility = @tot_util_cost - (@utlc * @qty)

    update inv_costing 
    set	unit_cost = @avgc, 
      direct_dolrs = @dirc, 
      ovhd_dolrs = @ovhc,
      util_dolrs = @utlc,
      tot_mtrl_cost = (@avgc * balance) + case when sequence = @max_seq then @r_cost else 0 end,
      tot_dir_cost = (@dirc * balance) + case when sequence = @max_seq then @r_direct else 0 end,
      tot_ovhd_cost = (@ovhc * balance) + case when sequence = @max_seq then @r_overhead else 0 end,
      tot_util_cost = (@utlc * balance) + case when sequence = @max_seq then @r_utility else 0 end
    where part_no = @i_part_no and location = @i_location and account  = @stock_acct
  end   

FETCH NEXT FROM t700insinv__cursor into
@i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
@i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
@i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost
end -- while

CLOSE t700insinv__cursor
DEALLOCATE t700insinv__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[t503updinvcost] ON [dbo].[inv_costing] FOR update AS 
BEGIN
if NOT (update(balance) OR update(account) OR update(location) OR update(part_no) OR update(quantity)) return

DECLARE @i_part_no varchar(30), @i_location varchar(10), @i_sequence int, @i_tran_code char(1),
@i_tran_no int, @i_tran_ext int, @i_tran_line int, @i_tran_date datetime, @i_tran_age datetime,
@i_unit_cost decimal(20,8), @i_quantity decimal(20,8), @i_balance decimal(20,8),
@i_direct_dolrs decimal(20,8), @i_ovhd_dolrs decimal(20,8), @i_labor decimal(20,8),
@i_util_dolrs decimal(20,8), @i_account varchar(10), @i_org_cost decimal(20,8), @i_audit int,
@i_tot_mtrl_cost decimal(20,8), @i_tot_dir_cost decimal(20,8), @i_tot_ovhd_cost decimal(20,8),
@i_tot_util_cost decimal(20,8), @i_tot_labor_cost decimal(20,8)

declare @xlp int, @qty decimal(20,8),  @stock_acct varchar(10)
declare @avg_cost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8),		-- mls 6/5/01 SCR 27031
@tot_mtrl_cost decimal(20,8), @tot_dir_cost decimal(20,8), @tot_ovhd_cost decimal(20,8), @tot_util_cost decimal(20,8)

select @stock_acct='STOCK'
DECLARE t700updinv__cursor CURSOR LOCAL STATIC FOR
SELECT i.part_no, i.location, i.sequence, i.tran_code, i.tran_no, i.tran_ext, i.tran_line,
i.tran_date, i.tran_age, i.unit_cost, i.quantity, i.balance, i.direct_dolrs, i.ovhd_dolrs,
i.labor, i.util_dolrs, i.account, i.org_cost, i.audit, i.tot_mtrl_cost, i.tot_dir_cost,
i.tot_ovhd_cost, i.tot_util_cost, i.tot_labor_cost
from inserted i
where account = @stock_acct

OPEN t700updinv__cursor

if @@cursor_rows = 0
begin
CLOSE t700updinv__cursor
DEALLOCATE t700updinv__cursor
return
end

FETCH NEXT FROM t700updinv__cursor into
@i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
@i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
@i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost

While @@FETCH_STATUS = 0
begin
  
  
  
  select @qty = NULL,@avg_cost = NULL, @direct = NULL, @overhead = NULL, @utility = NULL	

  select @qty= sum(balance), 				 					-- mls 7/28/99 SCR 70 20153
      @tot_mtrl_cost = sum(isnull(tot_mtrl_cost,unit_cost * balance)),
      @tot_dir_cost = sum(isnull(tot_dir_cost,direct_dolrs * balance)),
      @tot_ovhd_cost = sum(isnull(tot_ovhd_cost,ovhd_dolrs * balance)),
      @tot_util_cost = sum(isnull(tot_util_cost,util_dolrs * balance))
  from inv_costing
  where part_no = @i_part_no and location = @i_location and account=@stock_acct

   
  if isnull(@qty,0) != 0 
  begin
    select @avg_cost = @tot_mtrl_cost / @qty,
      @direct = @tot_dir_cost / @qty,
      @overhead = @tot_ovhd_cost / @qty,
      @utility = @tot_util_cost / @qty

    if exists (select 1 from inv_list (nolock)
      where part_no = @i_part_no and location = @i_location and 
       (avg_cost != isnull(@avg_cost,avg_cost) or avg_direct_dolrs != isnull(@direct,avg_direct_dolrs) or 
        avg_ovhd_dolrs != isnull(@overhead,avg_ovhd_dolrs) or avg_util_dolrs != isnull(@utility,avg_util_dolrs)))
    begin
      -- mls 2/11/02 SCR 28338 start
      if isnull(@avg_cost,0) < 0 select @avg_cost = 0
      if isnull(@direct,0) < 0 select @direct = 0
      if isnull(@overhead,0) < 0 select @overhead = 0
      if isnull(@utility,0) < 0 select @utility = 0
      -- mls 2/11/02 SCR 28338 end

      update inv_list 
      set avg_cost= abs(isnull(@avg_cost,avg_cost)),
        avg_direct_dolrs = abs(isnull(@direct, avg_direct_dolrs)),
        avg_ovhd_dolrs = abs(isnull(@overhead, avg_ovhd_dolrs)),
        avg_util_dolrs = abs(isnull(@utility, avg_util_dolrs))
      where location=@i_location and part_no=@i_part_no
    end															-- mls 6/5/01 SCR 27031
  end 


FETCH NEXT FROM t700updinv__cursor into
@i_part_no, @i_location, @i_sequence, @i_tran_code, @i_tran_no, @i_tran_ext, @i_tran_line,
@i_tran_date, @i_tran_age, @i_unit_cost, @i_quantity, @i_balance, @i_direct_dolrs,
@i_ovhd_dolrs, @i_labor, @i_util_dolrs, @i_account, @i_org_cost, @i_audit, @i_tot_mtrl_cost,
@i_tot_dir_cost, @i_tot_ovhd_cost, @i_tot_util_cost, @i_tot_labor_cost
end -- while

CLOSE t700updinv__cursor
DEALLOCATE t700updinv__cursor

END
GO
CREATE UNIQUE NONCLUSTERED INDEX [invcost2] ON [dbo].[inv_costing] ([audit]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [invcost3] ON [dbo].[inv_costing] ([part_no], [location], [account], [lot_ser], [sequence]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [invcost1] ON [dbo].[inv_costing] ([part_no], [location], [account], [sequence]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[inv_costing] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_costing] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_costing] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_costing] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_costing] TO [public]
GO
