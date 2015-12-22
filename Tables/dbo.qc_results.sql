CREATE TABLE [dbo].[qc_results]
(
[timestamp] [timestamp] NOT NULL,
[qc_no] [int] NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[ext] [int] NULL,
[line_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_qty] [decimal] (20, 8) NOT NULL,
[reject_qty] [decimal] (20, 8) NOT NULL,
[reject_reason] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor_key] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appearance] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[composition] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[inspector] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_inspected] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_inspected] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_complete] [datetime] NULL,
[picture_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[picture_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reject_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delqcresult] ON [dbo].[qc_results]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_QC_RESULT' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 78099 ,'You Can Not Delete A QC Result!' 
	return
	end
end



GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insqcresult] ON [dbo].[qc_results]   FOR INSERT AS 
begin
	if exists (select * from inserted where location like 'DROP%') begin
		rollback tran
		exec adm_raiserror 88003 ,'You Can NOT QC A DROP Location.'
		return 
	end	


declare @xlp int, @dir smallint, @cost decimal(20,8), @uom char(2), @src char(1),
	@uom_qty decimal(20,8), @conv_factor decimal(20,8), @who varchar(20), @dexp datetime

select @xlp=isnull((select min(qc_no) from inserted where lb_tracking='Y'),0)
while @xlp > 0 begin

	
	
	select @src=tran_code
		from inserted
		where
		qc_no=@xlp

	if @src='P' begin
		update lot_bin_prod set qc_flag='Y' 
			from inserted i
			where
			i.qc_no=@xlp and
			i.location=lot_bin_prod.location and
			i.part_no=lot_bin_prod.part_no and
			i.bin_no=lot_bin_prod.bin_no and
			i.lot_ser=lot_bin_prod.lot_ser and
			i.tran_no=lot_bin_prod.tran_no and
			i.ext=lot_bin_prod.tran_ext and
			i.line_no=lot_bin_prod.line_no and
			(lot_bin_prod.qc_flag != 'Y' OR lot_bin_prod.qc_flag is null) 
	end
	if @src='R' begin
		update lot_bin_recv set qc_flag='Y'
			from inserted i
			where
			i.qc_no=@xlp and
			i.location=lot_bin_recv.location and
			i.part_no=lot_bin_recv.part_no and
			i.bin_no=lot_bin_recv.bin_no and
			i.lot_ser=lot_bin_recv.lot_ser and
			i.tran_no=lot_bin_recv.tran_no and
			i.ext=lot_bin_recv.tran_ext and
			i.line_no=lot_bin_recv.line_no and
			(lot_bin_recv.qc_flag != 'Y' OR lot_bin_recv.qc_flag is null) 
	end
	if @src='C' begin
		update lot_bin_ship set qc_flag='Y'  
			from inserted i
			where
			i.qc_no=@xlp and
			i.location=lot_bin_ship.location and
			i.part_no=lot_bin_ship.part_no and
			i.bin_no=lot_bin_ship.bin_no and
			i.lot_ser=lot_bin_ship.lot_ser and
			i.tran_no=lot_bin_ship.tran_no and
			i.ext=lot_bin_ship.tran_ext and
			i.line_no=lot_bin_ship.line_no and
			(lot_bin_ship.qc_flag != 'Y' OR lot_bin_ship.qc_flag is null) 
	end


	select @xlp=isnull((select min(qc_no) from inserted where lb_tracking='Y' and qc_no > @xlp),0)
end
return
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updqcresult] ON [dbo].[qc_results]   FOR UPDATE AS 
begin

if exists (select * from inserted where qc_qty < reject_qty) begin
	rollback tran
	exec adm_raiserror 98031, 'Reject Qty Can NOT Be Greater Than QC Quantity!'
	return
end

declare @in_src char(1), @in_tran_no int, @in_ext int, @in_line_no int,
	@in_qc_qty decimal(20,8), @in_rejected decimal(20,8), 
	@in_bin_no varchar(25), @in_lot_ser varchar(25), @in_lb char(1),
        @in_location varchar(10), @in_part_no varchar(30), @in_status char(1),
        @in_date_expires datetime							-- mls 11/15/02 SCR 29957
declare @dl_src char(1), @dl_tran_no int, @dl_ext int, @dl_line_no int,
	@dl_qc_qty decimal(20,8), @dl_rejected decimal(20,8), 
	@dl_bin_no varchar(25), @dl_lot_ser varchar(25), @dl_lb char(1),
        @dl_location varchar(10), @dl_part_no varchar(30),
        @dl_date_expires datetime							-- mls 11/15/02 SCR 29957
declare @xlp int,
	@dir smallint, @cost decimal(20,8), @uom char(2),
	@uom_qty decimal(20,8), @conv_factor decimal(20,8), @who varchar(20),
        @in_date_complete datetime
declare @new_status char(1) --RLT 24018
declare @new_qc_flag char(1) --RLT 24018

declare @max_line int, @max_display_line int

declare @inv_lot_bin varchar(10), @sum_qc_qty decimal(20,8), @sum_reject_qty decimal(20,8)	-- mls 2/23/01

select @inv_lot_bin = upper(isnull((select substring(value_str,1,1) from config (nolock)	-- mls 2/23/01 SCR 26060
  where flag = 'INV_LOT_BIN'),'N'))

select @xlp=isnull((select min(qc_no) from inserted),0)
while @xlp > 0 begin



  select @in_src=tran_code, @in_tran_no=tran_no, @in_ext=ext, @in_line_no=line_no, 
	@in_qc_qty=qc_qty, @in_rejected=reject_qty, @in_lot_ser=lot_ser, @in_bin_no=bin_no, @in_lb=lb_tracking,
	@in_location = location, @in_part_no = part_no, @in_status = status,
        @in_date_expires = date_expires,								-- mls 11/16/02 SCR 29957
        @in_date_complete = date_complete
  from inserted where qc_no=@xlp
  select @dl_src=tran_code, @dl_tran_no=tran_no, @dl_ext=ext, @dl_line_no=line_no, 
	@dl_qc_qty=qc_qty, @dl_rejected=reject_qty, @dl_lot_ser=lot_ser, @dl_bin_no=bin_no, @dl_lb=lb_tracking,
	@dl_location = location, @dl_part_no = part_no,
        @dl_date_expires = date_expires								-- mls 11/16/02 SCR 29957
  from deleted where qc_no=@xlp

  if @in_src='R' and @in_status = 'S'
  begin
	

    if @in_lb='Y' and @inv_lot_bin != 'R'							-- mls 3/29/01 SCR 26418
    begin
	update lot_bin_recv set qty=@in_qc_qty ,
		qc_flag='F',
		lot_ser=@in_lot_ser,
		bin_no=@in_bin_no,
                date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
	where	@in_location=location and @in_part_no=part_no and @dl_bin_no=bin_no and
		@dl_lot_ser=lot_ser and	@in_tran_no=tran_no
    end 

    UPDATE receipts_all
    SET qc_flag='F', rejected=@in_rejected
    where receipt_no=@in_tran_no 
  end 

  if @in_src='C' and @in_status = 'S'
  begin
    if @in_lb='Y' and @inv_lot_bin != 'R' 							-- mls 3/29/01 SCR 26418
	
    BEGIN
      UPDATE lot_bin_ship 
      SET qty=@in_qc_qty - @in_rejected,
        uom_qty = (@in_qc_qty - @in_rejected) / conv_factor,			-- mls 5/19/00 SCR 22943
        qc_flag='F',
        lot_ser=@in_lot_ser,
        bin_no=@in_bin_no,
        date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
      WHERE @in_location=location and @in_part_no=part_no and @dl_bin_no=bin_no and
        @dl_lot_ser=lot_ser and @in_tran_no=tran_no and @in_ext=tran_ext and
        @in_line_no=line_no
      --RLT 24018 start
      select @new_status = 'Q' -- this is the initial value, what the column should already be set to.
      select @new_qc_flag = 'Y' -- again what it should be.

      IF not exists (select 1 from  lot_bin_ship b 
        WHERE @in_tran_no=b.tran_no and @in_ext=b.tran_ext and @in_line_no=b.line_no and 
        isnull(b.qc_flag,'Y') = 'Y' )
      BEGIN
        select @new_status = 'R' --which is stating that the order is closed.
        select @new_qc_flag = 'F' -- I am not user why 'F', yet i think it states that it is finished.
      END

      UPDATE ord_list	
      SET qc_flag=@new_qc_flag, status= @new_status, 					--RLT 24018
        cr_shipped=cr_shipped - (@in_rejected / conv_factor),				-- mls 5/19/00 SCR 22943
        rejected= rejected + (@in_rejected / conv_factor)				-- mls 5/19/00 SCR 22943
      WHERE order_no=@in_tran_no and order_ext=@in_ext and line_no=@in_line_no 
      --RLT 24018 Notice no not exists statement, which means this fires all the time

	-- mls 4/20/06 SCR 35982
       if @in_rejected != 0
       begin
         select @max_line = max(line_no), @max_display_line = max(display_line)
         from ord_list
         where order_no = @in_tran_no and order_ext = @in_ext

	set @max_line = @max_line + 1
	set @max_display_line = @max_display_line + 1

	INSERT ord_list(order_no,order_ext,		line_no,		location,
		part_no,	description,		time_entered,		ordered,
		shipped,	price,			price_type,		note,
		status,		cost,			who_entered,		sales_comm,
		temp_price,	temp_type,		cr_ordered,		cr_shipped,
		discount,	uom,			conv_factor,		void,
		void_who,	void_date,		std_cost,		cubic_feet,
		printed,	lb_tracking,		labor,			direct_dolrs,
		ovhd_dolrs,	util_dolrs,		taxable,		weight_ea,
		qc_flag,	reason_code,		qc_no,			rejected,
		part_type,	orig_part_no,		back_ord_flag,		gl_rev_acct,
		total_tax,	tax_code,		curr_price,		oper_price,
		display_line,	std_direct_dolrs,	std_ovhd_dolrs,		std_util_dolrs,
		reference_code,	ship_to, service_agreement_flag, --skk 05/16/00 mshipto ,ssb 06/26/00 23195 							             
                agreement_id,   create_po_flag,         load_group_no,          return_code,	-- mls 10/2/03 SCR 31956
                user_count)
	SELECT	order_no,	order_ext,		@max_line,		location,
                part_no,	description,		time_entered,		0,
		0,		price,			price_type,		note,
		@new_status,	cost,			'qc',			sales_comm,
		temp_price,	temp_type,		@in_rejected / conv_factor, @in_rejected / conv_factor,
		discount,	uom,			conv_factor,		void,
		void_who,	void_date,		std_cost,		cubic_feet,
		printed,	lb_tracking,		labor,			direct_dolrs,
		ovhd_dolrs,	util_dolrs,		taxable,		weight_ea,
		qc_flag,	reason_code,		qc_no,			rejected,
		'N',		orig_part_no,		back_ord_flag,		gl_rev_acct,
		0,		tax_code,		curr_price,		oper_price,
		@max_display_line,	std_direct_dolrs,	std_ovhd_dolrs,		std_util_dolrs,
		reference_code,	ship_to, service_agreement_flag, --skk 05/16/00 mshipto, ssb 06/26/00 23195								        
                agreement_id,   create_po_flag,         0,   		        return_code,	-- mls 10/2/03 SCR 31956
                user_count
	FROM ord_list
	WHERE order_no=@in_tran_no and order_ext=@in_ext and line_no=@in_line_no
	if @@error != 0
	begin
	rollback tran
	exec adm_raiserror 99111, 'Error creating non inventory return line on credit return'
	end
	end -- in_rejected
    END   
    --RLT 24018 END
    ELSE										-- mls 3/29/01 SCR 26418
    BEGIN
      UPDATE ord_list 
      SET qc_flag='F', status='R',
        cr_shipped=cr_shipped - (@in_rejected / conv_factor),  				-- mls 5/19/00 SCR 22943
        rejected=(@in_rejected / conv_factor)    					-- mls 5/19/00 SCR 22943
      WHERE order_no=@in_tran_no and order_ext=@in_ext and line_no=@in_line_no

	-- mls 4/20/06 SCR 35982
       if @in_rejected != 0
       begin
         select @max_line = max(line_no), @max_display_line = max(display_line)
         from ord_list
         where order_no = @in_tran_no and order_ext = @in_ext

	set @max_line = @max_line + 1
	set @max_display_line = @max_display_line + 1

	INSERT ord_list(order_no,order_ext,		line_no,		location,
		part_no,	description,		time_entered,		ordered,
		shipped,	price,			price_type,		note,
		status,		cost,			who_entered,		sales_comm,
		temp_price,	temp_type,		cr_ordered,		cr_shipped,
		discount,	uom,			conv_factor,		void,
		void_who,	void_date,		std_cost,		cubic_feet,
		printed,	lb_tracking,		labor,			direct_dolrs,
		ovhd_dolrs,	util_dolrs,		taxable,		weight_ea,
		qc_flag,	reason_code,		qc_no,			rejected,
		part_type,	orig_part_no,		back_ord_flag,		gl_rev_acct,
		total_tax,	tax_code,		curr_price,		oper_price,
		display_line,	std_direct_dolrs,	std_ovhd_dolrs,		std_util_dolrs,
		reference_code,	ship_to, service_agreement_flag, --skk 05/16/00 mshipto ,ssb 06/26/00 23195 							             
                agreement_id,   create_po_flag,         load_group_no,          return_code,	-- mls 10/2/03 SCR 31956
                user_count)
	SELECT	order_no,	order_ext,		@max_line,		location,
                part_no,	description,		time_entered,		0,
		0,		price,			price_type,		note,
		'R',		cost,			'qc',			sales_comm,
		temp_price,	temp_type,		@in_rejected / conv_factor, @in_rejected / conv_factor,
		discount,	uom,			conv_factor,		void,
		void_who,	void_date,		std_cost,		cubic_feet,
		printed,	lb_tracking,		labor,			direct_dolrs,
		ovhd_dolrs,	util_dolrs,		taxable,		weight_ea,
		qc_flag,	reason_code,		qc_no,			rejected,
		'N',		orig_part_no,		back_ord_flag,		gl_rev_acct,
		0,		tax_code,		curr_price,		oper_price,
		@max_display_line,	std_direct_dolrs,	std_ovhd_dolrs,		std_util_dolrs,
		reference_code,	ship_to, service_agreement_flag, --skk 05/16/00 mshipto, ssb 06/26/00 23195								        
                agreement_id,   create_po_flag,         0,   		        return_code,	-- mls 10/2/03 SCR 31956
                user_count
	FROM ord_list
	WHERE order_no=@in_tran_no and order_ext=@in_ext and line_no=@in_line_no
	if @@error != 0
	begin
	rollback tran
	exec adm_raiserror 99111, 'Error creating non inventory return line on credit return'
	end
	end -- in_rejected
    END
    if not exists (select 1 from ord_list o 
      where o.status = 'Q' and o.order_no=@in_tran_no and o.order_ext=@in_ext and qc_flag = 'Y'
        and o.cr_shipped != 0)							-- mls 2/13/02 SCR 28234
    begin
      UPDATE ord_list SET status='R',
        qc_flag = case when qc_flag = 'Y' then 'F' else qc_flag end		-- mls 2/13/02 SCR 28234
      WHERE order_no=@in_tran_no and order_ext=@in_ext 
        and not (qc_flag = 'Y' and cr_shipped != 0) and status !='R'		-- mls 2/13/02 SCR 28234
    end

    
    if not exists (select 1 from ord_list o where o.status = 'Q' and o.order_no=@in_tran_no and
      o.order_ext=@in_ext)
    begin
      UPDATE orders_all 
      SET status='R', printed = 'R'    							-- mls 2/25/00 SCR 22492
      WHERE order_no=@in_tran_no and ext=@in_ext 
    end
  end 

  if @in_src='I' and @in_status = 'S'
  begin
    if @in_lb='Y' and @inv_lot_bin != 'R' 							-- mls 3/29/01 SCR 26418
	
    BEGIN
      UPDATE lot_serial_bin_issue
      SET tran_code = 'B',
        lot_ser=@in_lot_ser,
        bin_no=@in_bin_no,
        date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
      WHERE @in_location=location and @in_part_no=part_no and @dl_bin_no=bin_no and
        @dl_lot_ser=lot_ser and @in_tran_no=tran_no and @in_ext=tran_ext and
        @in_line_no=line_no
      --RLT 24018 start

      UPDATE issues_all
      SET status = 'S', issue_date = @in_date_complete
      WHERE issue_no=@in_tran_no 
    END   
    ELSE										-- mls 3/29/01 SCR 26418
    BEGIN
      UPDATE issues_all 
      SET status = 'S', issue_date = @in_date_complete
      WHERE issue_no=@in_tran_no 
    END
  end 

  

  if @in_src='P' and @in_status = 'S'
  begin
    if @in_lb='Y' and @inv_lot_bin = 'Y' 
    begin  										-- mls 2/23/01
      UPDATE lot_bin_prod 
      SET qty=@in_qc_qty - @in_rejected,
        uom_qty = (@in_qc_qty - @in_rejected) / conv_factor,				-- mls 5/19/00 SCR 22943
        lot_ser=@in_lot_ser,
        bin_no=@in_bin_no,
        date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
      WHERE @in_location= location and @in_part_no= part_no and @dl_bin_no= bin_no and
        @dl_lot_ser= lot_ser and @in_tran_no= tran_no and @in_ext= tran_ext and
        @in_line_no= line_no

      select @sum_qc_qty = sum(qc_qty), @sum_reject_qty = sum(reject_qty)
      from qc_results q
      where q.tran_no = @in_tran_no and q.ext = @in_ext and q.line_no = @in_line_no and status < 'T'

      UPDATE prod_list
      SET used_qty = @sum_qc_qty, scrap_pcs= @sum_reject_qty,
	last_tran_date = @in_date_complete						-- mls 11/29/05 SCR 35779
      where prod_no = @in_tran_no and prod_ext = @in_ext and line_no = @in_line_no

      if not exists (select 1 from qc_results   					-- mls 2/23/01 SCR 26060
        where tran_no = @in_tran_no and ext = @in_ext and line_no = @in_line_no and status < 'S')
      begin
        UPDATE lot_bin_prod
        set tran_code = 'S', qc_flag = 'F'
        where tran_no = @in_tran_no and tran_ext = @in_ext and line_no = @in_line_no

        UPDATE prod_list
        SET status='S', qc_no=0,
	last_tran_date = @in_date_complete						-- mls 11/29/05 SCR 35779
        WHERE prod_no=@in_tran_no and prod_ext=@in_ext and line_no=@in_line_no
      end
    end 
    else
    begin
      UPDATE prod_list
      SET status='S', qc_no=0, used_qty=@in_qc_qty,scrap_pcs=@in_rejected,
	last_tran_date = @in_date_complete						-- mls 11/29/05 SCR 35779
      WHERE prod_no=@in_tran_no and prod_ext=@in_ext and line_no=@in_line_no
    end

    
    if NOT exists (select 1 from prod_list where prod_no=@in_tran_no and prod_ext=@in_ext and
      status<='R' and direction=1 and plan_qty > 0) 
    and not exists (select 1 from produce_all (nolock) where prod_no = @in_tran_no and prod_ext = @in_ext
      and prod_type = 'R' and status < 'R')						-- mls 01/11/06 SCR 35894
    begin
      UPDATE produce_all 
      SET status='S'
      WHERE prod_no=@in_tran_no and prod_ext=@in_ext
    end
  end

  if @in_src='R' and @in_status != 'S' and @in_lb = 'Y' and @inv_lot_bin != 'R'		-- mls 3/29/01 SCR 26418
  begin
    
    if @in_lot_ser != @dl_lot_ser or @in_bin_no != @dl_bin_no or
      @in_date_expires != @dl_date_expires
    begin
      update lot_bin_recv 
      set lot_ser=@in_lot_ser,
        bin_no=@in_bin_no,
        date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
      where @in_location= location and @in_part_no= part_no and @dl_bin_no= bin_no and
        @dl_lot_ser= lot_ser and @in_tran_no= tran_no 
    end
  end 

  if @in_src='C'  and @in_status != 'S' and @in_lb = 'Y' and @inv_lot_bin != 'R'	-- mls 3/29/01 SCR 26418
  begin
    UPDATE lot_bin_ship 
    SET qty=@in_qc_qty - @in_rejected,
      lot_ser=@in_lot_ser,
      bin_no=@in_bin_no,
      date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
    WHERE @in_location= location and @in_part_no= part_no and @dl_bin_no= bin_no and
      @dl_lot_ser= lot_ser and @in_tran_no= tran_no and @in_ext= tran_ext and
      @in_line_no= line_no
  end 

  if @in_src='P' and @in_status != 'S' and @in_lb = 'Y' and @inv_lot_bin != 'R'		-- mls 3/29/01 SCR 26418
  begin
    UPDATE lot_bin_prod 
    SET qty=@in_qc_qty - @in_rejected,
      uom_qty = (@in_qc_qty - @in_rejected) / conv_factor,				-- mls 5/19/00 SCR 22943
      lot_ser=@in_lot_ser,
      bin_no=@in_bin_no,
      date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
    WHERE @in_location= location and @in_part_no= part_no and
      @dl_bin_no= bin_no and @dl_lot_ser= lot_ser and @in_tran_no= tran_no and
      @in_ext= tran_ext and @in_line_no= line_no
  end 

  if @in_src='I' and @in_status != 'S' and @in_lb = 'Y' and @inv_lot_bin != 'R'		-- mls 3/29/01 SCR 26418
  begin

    UPDATE lot_serial_bin_issue 
    SET qty=@in_qc_qty - @in_rejected,
      lot_ser=@in_lot_ser,
      bin_no=@in_bin_no,
      date_expires = @in_date_expires							-- mls 11/16/02 SCR 29957
    WHERE @in_location= location and @in_part_no= part_no and
      @dl_bin_no= bin_no and @dl_lot_ser= lot_ser and @in_tran_no= tran_no and
      @in_ext= tran_ext and @in_line_no= line_no
  end 

  select @xlp=isnull((select min(qc_no) from inserted where qc_no > @xlp),0)
end 
end 
GO
CREATE NONCLUSTERED INDEX [qcr3] ON [dbo].[qc_results] ([part_no], [location], [lot_ser], [bin_no], [qc_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [qcr1] ON [dbo].[qc_results] ([qc_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [qcr2] ON [dbo].[qc_results] ([tran_code], [tran_no], [qc_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[qc_results] TO [public]
GO
GRANT SELECT ON  [dbo].[qc_results] TO [public]
GO
GRANT INSERT ON  [dbo].[qc_results] TO [public]
GO
GRANT DELETE ON  [dbo].[qc_results] TO [public]
GO
GRANT UPDATE ON  [dbo].[qc_results] TO [public]
GO
