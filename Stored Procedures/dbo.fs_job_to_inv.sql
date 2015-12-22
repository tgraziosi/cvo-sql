SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_job_to_inv] @prodno int, @partno varchar(30), 
	@qty decimal(20,8), @who varchar(10), @lot varchar(25), @bin varchar(12), @edt datetime, @err int OUT AS

begin





declare @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8),
	@labor decimal(20,8), @ino int, @lb_tracking char(1), @loc varchar(10)
DECLARE @serial_flag int

select @err = -99

if NOT exists (select * from produce_all where prod_no=@prodno and prod_type='J') begin
	raiserror 62501 'Production / Job Does Not Exists.'
        select @err = -1
	return 
end

if NOT exists (select * from produce_all where prod_no=@prodno and status >='P' and status <='Q') begin
	raiserror 62502 'Production Job Is Completed Or Not Picked.'
        select @err = -2
	return 
end

SELECT @loc=location FROM produce_all WHERE prod_no=@prodno and prod_ext=0

if NOT exists (select * from inventory where location=@loc and part_no=@partno and void != 'V') begin
	raiserror 62503 'Item Does Not Exists In Inventory - Please Create Item First.'
        select @err = -3
	return 

end

if @qty <=0 begin
	raiserror 62504 'Quantity Must Be Greater Than Zero.'
        select @err = -4
	return 
end



	UPDATE next_iss_no SET last_no=(last_no + 1)
		WHERE last_no = last_no

 	SELECT @ino=last_no FROM next_iss_no

	UPDATE prod_list SET status='S'
		WHERE
		prod_no=@prodno and
		prod_ext=0 and
		status != 'S' and
		direction = -1 

	UPDATE produce_all SET status='S', part_no=@partno, qty=@qty,
                        note=note+'  ***Adj# '+convert(varchar(10), @ino)
		WHERE 
		prod_no=@prodno and
		prod_ext=0

	
	SELECT 	@unitcost=p.tot_avg_cost / @qty,
		@direct=p.tot_direct_dolrs / @qty,
		@overhead=p.tot_ovhd_dolrs / @qty,
		@labor=p.tot_labor / @qty,
		@utility=p.tot_util_dolrs / @qty
		FROM produce_all p
		WHERE 
		p.prod_no=@prodno and
		p.prod_ext=0

	SELECT @lb_tracking=lb_tracking, @serial_flag = serial_flag FROM inventory WHERE part_no=@partno and location=@loc

 	SELECT @ino=last_no FROM next_iss_no

	INSERT into issues_all 

	  ( issue_no,     part_no,     location_from, 
	    avg_cost,     who_entered, code, 
	    issue_date,   note,        qty, direction, 
	    lb_tracking, direct_dolrs, 
	    ovhd_dolrs,   util_dolrs,  labor, serial_flag   )
	  values
	  ( @ino,         @partno,      @loc, 
	    @unitcost,    @who,        'WIP', 
	    getdate(),    '', 	       @qty, 1, 
	    @lb_tracking,         @direct, 
	    @overhead,    @utility,    @labor, @serial_flag)

	if @@error <> 0 begin
                select @err = -4
		return 
	  end

	IF (@lb_tracking = 'Y' or @serial_flag = 1)
	BEGIN
		INSERT INTO lot_serial_bin_issue
		( tran_no, tran_ext, line_no, part_no, location, 
		bin_no, tran_code, date_tran, date_expires, 
		qty, direction, who, cost, lot_ser) 
		(SELECT @ino, 0, 1, @partno, @loc, 
		@bin, 'I', getdate(), @edt, 
		@qty, 1, @who, @unitcost, @lot)						-- mls 2/12/01 SCR 25947
		
		IF (@@error <> 0 )
		BEGIN
			select @err = -4
			return
		END
	END

select @err = 1
return 

end
GO
GRANT EXECUTE ON  [dbo].[fs_job_to_inv] TO [public]
GO
