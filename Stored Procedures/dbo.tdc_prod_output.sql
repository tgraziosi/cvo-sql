SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* This SP is used report production output.			*/
/*								*/
/* Return Values:						*/
/* Value = positive or zero 					*/
/*	Good Return						*/
/* Value = Other negative					*/
/*	Error occured. Check error message field.		*/
/*								*/

/*								*/
/* 11/03/1998	Initial		GCJ				*/
/*								*/

CREATE PROC [dbo].[tdc_prod_output]
AS

--Declarations

DECLARE @row_id int, @err int, @time_no int, @type char(1), @ptype char(1)

DECLARE @employee_key	varchar (10)	,	--Employee Code
	@prod_no	int 		,	--Production Number
	@prod_ext 	int 		,	--Produceion Extension
        @prod_part      varchar (30)    ,       --End Item Being Produced
	@location 	varchar (10) 	,	--Location	
	@seq_no 	varchar (4) 	,	--Sequence Number being Consumed..When a production record leave blank ''
	@part_no 	varchar (30) 	,	--Part number being Consumed when
	@project_key 	varchar (10) 	,	--Project key for jobs
	@tran_date 	datetime 	,	--date of transaction normally getdate()
	@plan_qty 	decimal(20, 8) 	,	--Planned used qty. For Items in prod_list this is defaulted from prod_list(so set to 0). For adhoc entries this needs to be supplied.
	@used_qty 	decimal(20, 8) 	,	--Used Qty for consumption
	@plan_pcs 	decimal(20, 8) 	,	--Planned completed pieces.For end item this is defaulted. For 
	@pieces 	decimal(20, 8) 	,	--Completed Pieces 
	@prod_used_qty 	decimal(20, 8) 	, 	--used qty got from prod_list table 
	@prod_pieces	decimal(20, 8) 	,	--pieces got from prod_list table
	@shift 		int 		,	--Shift
	@who_entered 	varchar (50) 	,	--Who Entered entry
	@note 		varchar (255) 	,	--Note; set to '' if not note.
	@scrap_pcs 	decimal(20, 8) 	,	--Items scapped
	@lot_ser 	varchar (25) 	,	--Lot number required if LB tracked Item
	@bin_no 	varchar (12) 	,	--Bin Number required if LB tracked Item
	@c_status	char(1),			-- 'C','P','' - C=close, P=Partial Close, '' -Make Routed Item   For Makes C and P are the only two valid. For Routed/Jobs '' and C are the only two available.
	@dir		int,
	@exp_date	datetime,
	@month		int,
	@lb_tracking 	char(1)

SELECT @row_id = 0

WHILE (@row_id >= 0)
BEGIN
	SELECT @row_id = ISNULL((SELECT MIN(row_id) FROM #prod_use_temp WHERE row_id > @row_id), -1)
      	IF @row_id = -1 BREAK

	SELECT  @employee_key	=	employee_key,
		@prod_no	=	prod_no,
		@prod_ext	=	prod_ext,
		@seq_no 	=	seq_no,
		@part_no 	=	part_no,
		@project_key	=	project_key,
		@tran_date 	=	tran_date,
		@plan_qty 	=	plan_qty,
		@used_qty 	=	used_qty,
		@plan_pcs 	=	plan_pcs,
		@pieces 	=	pieces,
		@shift 		=	shift,
		@who_entered 	=	who_entered,
		@note 		=	note,
		@scrap_pcs 	=	scrap_pcs,
	 	@lot_ser	=	lot_ser,
		@bin_no 	=	bin_no,
		@c_status	=	c_status
	FROM #prod_use_temp
	WHERE row_id = @row_id

	SELECT @who_entered = login_id FROM #temp_who
	       
	
	IF not exists (SELECT * FROM employee WHERE kys = @employee_key)
	BEGIN
		-- Error: Employee is not valid.
		UPDATE #prod_use_temp SET err_msg = '' 
		RETURN -101
	END
	
	IF NOT EXISTS (SELECT * FROM produce WHERE prod_no = @prod_no AND prod_ext = @prod_ext AND status < 'R' AND status >= 'N' )
	BEGIN
		-- Error: Production %s Not Found or Closed.
		UPDATE #prod_use_temp SET err_msg = convert(varchar(10), @prod_no) 
		RETURN -102
	END
	
	--Get Production type/finished item/location from Production Header
	SELECT  @type = prod_type, @prod_part = part_no, @location = location
	FROM    produce (nolock)
	WHERE   prod_no = @prod_no AND prod_ext = @prod_ext 
	
	--Get the part_type and confirm the sequence number matches the item number and that it is a valid sequence number
	SELECT  @ptype = part_type, @plan_pcs = plan_pcs, @plan_qty = plan_qty, @dir = direction, @prod_used_qty = used_qty, @prod_pieces = pieces, @lb_tracking = lb_tracking
	FROM    prod_list (nolock)
	WHERE   prod_no = @prod_no AND prod_ext = @prod_ext AND part_no = @part_no AND seq_no = @seq_no AND line_no > 0  
	
	IF @@rowcount <= 0 
	BEGIN
		-- Error: Sequence Number does not Match Part number on Prod_list or Sequence Number Does Not.
		UPDATE #prod_use_temp SET err_msg = ''
		RETURN -103
	END
	
	--Check to verify that if the sequence number is '' then the part supplied = production part
	IF @seq_no = '' AND (@prod_part != @part_no)
	BEGIN
		-- Error: Item produced does not match produce table.
		UPDATE #prod_use_temp SET err_msg = ''
		RETURN -104
	END
	
	IF(@lb_tracking = 'Y')
	BEGIN
		SELECT @month = CAST(ISNULL(value_str, 12) AS INT) FROM tdc_config (nolock) WHERE [function] = 'exp_date'
		SELECT @exp_date = DATEADD(month, @month, getdate())
	END

	IF (@ptype != 'R') SELECT @scrap_pcs = 0
	
	BEGIN TRAN
	
		UPDATE next_time_no SET last_no = last_no + 1
		SELECT @time_no = last_no FROM next_time_no
	
		IF (@seq_no = '')
		BEGIN
	--		IF(@type = 'R')
	--		BEGIN
				-- Production Output of Make Routed Type Part
	--			INSERT INTO prod_use ( time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status, tran_date,  prod_part, plan_qty, 		      used_qty, plan_pcs, 		  pieces, scrap_pcs, location, shift, who_entered, date_entered, void, lot_ser, bin_no) 
	--			VALUES               (@time_no,@employee_key,@prod_no,@prod_ext, '',    @part_no, 'P',    getdate(), @prod_part, @plan_qty - @prod_used_qty, @pieces,  @plan_pcs - @prod_pieces, @pieces, 0,        @location,     1,@who_entered, getdate(),    'N', @lot_ser, @bin_no)
	--		END
	--		ELSE
	--		BEGIN
				-- Production Output of Make Type Part
				INSERT INTO prod_use ( time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status, tran_date,  prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, location, shift, who_entered, date_entered, void, lot_ser, bin_no, date_expires) 
				VALUES               (@time_no,@employee_key,@prod_no,@prod_ext, '',    @part_no, 'P',    getdate(), @prod_part, 0,       @pieces,   0,       @pieces, 0,        @location,     1,@who_entered, getdate(), 'N', @lot_ser, @bin_no, @exp_date)
	--		END
		END
		ELSE
		BEGIN
			IF(@dir = 1)
			BEGIN
				-- Production Output of by product
				INSERT INTO prod_use ( time_no, employee_key, prod_no, prod_ext, seq_no,  part_no, status, tran_date,  prod_part , plan_qty , 		       used_qty, plan_pcs , 		   pieces, scrap_pcs, location, shift, who_entered, date_entered, void, lot_ser, bin_no, oper_status, date_expires) 
				VALUES               (@time_no,@employee_key,@prod_no,@prod_ext,@seq_no, @part_no, 'P',    getdate(), @prod_part, @plan_qty - @prod_used_qty, @pieces , @plan_pcs - @prod_pieces, @pieces, 0,        @location,     1,@who_entered, getdate(),   'N',  @lot_ser, @bin_no, 'N', @exp_date)
			END
			
			IF(@ptype = 'R')
			BEGIN
				-- Production Output of Resource
				INSERT INTO prod_use ( time_no, employee_key, prod_no, prod_ext, seq_no,  part_no, status, tran_date,  prod_part,  plan_qty, 		used_qty,  plan_pcs, 			pieces, scrap_pcs, location, shift, who_entered, date_entered, void, oper_status) 
				VALUES               (@time_no,@employee_key,@prod_no,@prod_ext,@seq_no, @part_no, 'P',    getdate(), @prod_part, @plan_qty - @prod_used_qty,  0, @plan_pcs - @prod_pieces,    @pieces, 0,	  @location, 1,    @who_entered, getdate(),   'N',	'N')
			END
		END
	
	COMMIT TRAN
END

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_prod_output] TO [public]
GO
