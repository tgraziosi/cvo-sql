CREATE TABLE [dbo].[prod_batch]
(
[timestamp] [timestamp] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prod_date] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[project_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[batch_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insprodbat] ON [dbo].[prod_batch] 
FOR INSERT
AS
declare @xlp int, @reterr int, @nextno int, @xpno int, @xpext int
declare @errmsg varchar(255), @lot varchar(25), @bin varchar(12), @expdate datetime
declare @glmethod int

select @xlp=isnull((select min(row_id) from inserted),0)
while @xlp > 0 begin

	


	IF exists (select * from inserted where prod_no=0 and row_id=@xlp)
	begin	
		update next_prod_no set last_no=last_no+1
		select @nextno=last_no from next_prod_no
		update prod_batch set prod_no=@nextno
                       where row_id=@xlp
		
		if exists (select * from config where flag='PSQL_GLPOST_MTH' and value_str != 'I')
		begin
			select @glmethod = indirect_flag from glco

			-- Commented because of SCR #21733 JSL
			








		end
	end
	ELSE
	begin
		select @xpno=prod_no, @xpext=prod_ext from inserted where row_id=@xlp	
		IF exists (select * from produce_all where prod_no=@xpno and prod_ext=@xpext)
		begin	
			update produce_all set qty=inserted.qty
			from inserted where produce_all.prod_no=inserted.prod_no and 

			produce_all.prod_ext=inserted.prod_ext and produce_all.prod_no=@xpno and
			produce_all.prod_ext=@xpext and inserted.row_id=@xlp
		end
		ELSE
		begin
			select @bin=bin_no, @lot=lot_ser, @expdate=date_expires
				from inserted
				where 
				inserted.row_id=@xlp 
			insert produce_all (prod_no,prod_ext, prod_date, part_type, 
				status, part_no, location, qty, prod_type,

				down_time, who_entered, conv_factor, uom, printed, void,
				tot_avg_cost, tot_direct_dolrs, tot_ovhd_dolrs, tot_util_dolrs, tot_labor,
				tot_prod_avg_cost, tot_prod_direct_dolrs, tot_prod_ovhd_dolrs, tot_prod_util_dolrs, tot_prod_labor,
				est_avg_cost, est_direct_dolrs, est_ovhd_dolrs, est_util_dolrs, est_labor,
				scrapped, qc_flag, project_key, qty_scheduled, date_entered, order_no )
			select prod_no, prod_ext, prod_date, 'P','N',
				inserted.part_no, inserted.location,qty,inserted.batch_type,
				0, inserted.who_entered,1, uom,'Y','N',
				0,0,0,0,0,
				0,0,0,0,0,
				0,0,0,0,0,
				0, inserted.qc_flag, inserted.project_key, qty, getdate(), 0
				from inserted, inventory
				where inventory.part_no=inserted.part_no and
				inventory.location=inserted.location and
				inserted.row_id=@xlp and
				inserted.status='S'
			
			
			if exists(select * from inserted where inserted.row_id=@xlp
					and inserted.status='S') begin
			execute @reterr=fs_do_prod @xpno, @xpext, @lot, @bin, @expdate
			if @reterr = -1 begin
				rollback tran
				exec adm_raiserror 86431 ,'Error In Posting Production'
				return
				end
			if @reterr = -2 begin
				rollback tran
				exec adm_raiserror 86433, 'You Can Not Batch Post Production That Has LOT/BIN Tracking Items!'
				return
				end
			if @reterr = -3 begin
				rollback tran
                                select @errmsg = 'No Valid BOM For This Item/Location! (['+inserted.part_no+'])'
				       from inserted
				       where inserted.row_id=@xlp
				exec adm_raiserror 86435, @errmsg

				return
				end
			if @reterr = -4 begin
				rollback tran
                                select @errmsg = 'Insufficient Lots/Bins!'

				       from inserted
				       where inserted.row_id=@xlp
				exec adm_raiserror 86436, @errmsg

				return
				end
			if @reterr != 1 begin
				rollback tran
				exec adm_raiserror 86437 ,'SQL Error In Posting Production'
				return
				end
			end
		end
	end
	select @xlp=isnull((select min(row_id) from inserted where row_id > @xlp),0)
end 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updprodbat] ON [dbo].[prod_batch] 
FOR UPDATE 
AS
declare @xlp int,@reterr int, @xpno int, @xpext int
declare @errmsg varchar(255), @bin varchar(12), @lot varchar(25), @expdate datetime

select @xlp=isnull((select min(row_id) from inserted where status='S'),0)
while @xlp > 0 begin
	select @xpno=prod_no, @xpext=prod_ext from inserted where row_id=@xlp
	IF exists (select * from produce_all where prod_no=@xpno and prod_ext=@xpext)
	begin	
		update produce_all set qty=inserted.qty
		from inserted where produce_all.prod_no=inserted.prod_no and 
		produce_all.prod_ext=inserted.prod_ext and produce_all.prod_no=@xpno and
		produce_all.prod_ext=@xpext and inserted.row_id=@xlp
	end
	ELSE
	begin
		
			select @bin=bin_no, @lot=lot_ser, @expdate=date_expires
				from inserted
				where 
				inserted.row_id=@xlp 
			insert produce_all (prod_no,prod_ext, prod_date, part_type, 
				status, part_no, location, qty, prod_type,

				down_time, who_entered, conv_factor, uom, printed, void,
				tot_avg_cost, tot_direct_dolrs, tot_ovhd_dolrs, tot_util_dolrs, tot_labor,
				tot_prod_avg_cost, tot_prod_direct_dolrs, tot_prod_ovhd_dolrs, tot_prod_util_dolrs, tot_prod_labor,
				est_avg_cost, est_direct_dolrs, est_ovhd_dolrs, est_util_dolrs, est_labor,
				scrapped, qc_flag, project_key, qty_scheduled, date_entered, order_no )
			select prod_no, prod_ext, prod_date, 'P','N',
				inserted.part_no, inserted.location,qty,inserted.batch_type,
				0, inserted.who_entered,1, uom,'Y','N',
				0,0,0,0,0,
				0,0,0,0,0,
				0,0,0,0,0,
				0, inserted.qc_flag, inserted.project_key, qty, getdate(), 0
				from inserted, inventory
				where inventory.part_no=inserted.part_no and
				inventory.location=inserted.location and
				inserted.prod_no=@xpno
		
		execute @reterr=fs_do_prod @xpno, @xpext, @lot, @bin, @expdate
		if @reterr = -1 begin
			rollback tran
			exec adm_raiserror 96431 ,'Error In Posting Production'
			return

			end
		if @reterr = -2 begin

			rollback tran
			exec adm_raiserror 96433 ,'You Can Not Batch Post Production That Has LOT/BIN Tracking Items!'
			return

			end

		if @reterr = -3 begin
			rollback tran
                        select @errmsg = 'No Valid BOM For This Item/Location! (['+inserted.part_no+'])'
		           from inserted
			   where inserted.row_id=@xlp
			exec adm_raiserror 96435, @errmsg
			return
			end
		if @reterr = -4 begin
			rollback tran
                        select @errmsg = 'Insufficient Lots/Bins!'
		           from inserted
			   where inserted.row_id=@xlp
			exec adm_raiserror 96436, @errmsg
			return
			end
		if @reterr != 1 begin
			rollback tran
			exec adm_raiserror 96437, 'SQL Error In Posting Production'
			return

			end
	end
	select @xlp=isnull((select min(row_id) from inserted where row_id > @xlp and status='S' ),0)
end 
GO
CREATE CLUSTERED INDEX [prodbat1] ON [dbo].[prod_batch] ([prod_no], [prod_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prod_batch] TO [public]
GO
GRANT SELECT ON  [dbo].[prod_batch] TO [public]
GO
GRANT INSERT ON  [dbo].[prod_batch] TO [public]
GO
GRANT DELETE ON  [dbo].[prod_batch] TO [public]
GO
GRANT UPDATE ON  [dbo].[prod_batch] TO [public]
GO
