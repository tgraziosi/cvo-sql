SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************************************************************/
/* This Procedure is used to insert Production Usage into the Prod Use table for make routed and jobs	*/
/********************************************************************************************************/
CREATE PROC [dbo].[tdc_bc_prod_use]  AS

	SET NOCOUNT ON

--Declarations
DECLARE @row_id int, @err int, @time_no int, @type char(1), @ptype char(1), @err_msg varchar(255)

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
	@qty 		decimal(20, 8) 	,
	@plan_pcs 	decimal(20, 8) 	,	--Planned completed pieces.For end item this is defaulted. For 
	@pieces 	decimal(20, 8) 	,	--Completed Pieces 
	@shift 		int 		,	--Shift
	@who_entered 	varchar (50) 	,	--Who Entered entry
	@note 		varchar (255) 	,	--Note; set to '' if not note.
	@scrap_pcs 	decimal(20, 8) 	,	--Items scapped
	@lot_ser 	varchar (25) 	,	--Lot number required if LB tracked Item
	@bin_no 	varchar (12) 	,	--Bin Number required if LB tracked Item
	@c_status	char(1)		,	-- 'C','P','' - C=close, P=Partial Close, '' -Make Routed Item   For Makes C and P are the only two valid. For Routed/Jobs '' and C are the only two available.
	@oper_status	char(1)		, 	
	@date_expires   datetime	,
	@lb_track	char(1),
	@language 	varchar(10)

/* Initialize the error code to 'No errors' */
SELECT @err = 0

/* Find the first record */
SELECT @row_id = 0
SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT MIN(who_entered) FROM #prod_use_temp)), 'us_english')

/* Look at each record... */
WHILE (@row_id >= 0)
BEGIN
      	SELECT @row_id = ISNULL((SELECT min(row_id) FROM #prod_use_temp WHERE row_id > @row_id),-1)

      	IF @row_id = -1 BREAK  --Kick out of loop if row not found

      	SELECT 	@employee_key	=	employee_key,
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

	SELECT @lb_track = lb_tracking FROM inv_master (nolock) WHERE part_no = @part_no
	
      	IF not exists (SELECT * FROM employee (nolock) WHERE kys = @employee_key)
      	BEGIN
        -- 	UPDATE #prod_use_temp SET err_msg = 'Invalid Employee %s.' WHERE row_id = @row_id
 		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error (nolock)
				WHERE module = 'SPR' AND trans = 'tdc_bc_prod_use' AND err_no = -101 AND language = @language
		RAISERROR (@err_msg, 16, 1, @employee_key)
		RETURN -101
       	END

      	IF not exists (SELECT * FROM produce (nolock) WHERE prod_no = @prod_no and prod_ext = @prod_ext and status < 'R' and status >= 'N'  )
       	BEGIN
        -- 	UPDATE #prod_use_temp SET err_msg = 'Production No %d-%d Not Found or Closed.' WHERE row_id = @row_id
 		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error (nolock)
				WHERE module = 'SPR' AND trans = 'tdc_bc_prod_use' AND err_no = -102 AND language = @language
		RAISERROR (@err_msg, 16, 1, @prod_no, @prod_ext)
		RETURN -102
       	END
      
      	--Get Production type/finished item/location from Production Header
      	SELECT 	@type      = prod_type,
             	@prod_part = part_no,
		@location  = location
       	FROM 	produce (nolock)
       	WHERE 	prod_no  = @prod_no and 
              	prod_ext = @prod_ext 

      	--Get the part_type and confirm the sequence number matches the item number and that it is a valid sequence number
      	SELECT 	@ptype = part_type		
       	FROM 	prod_list (nolock)
       	WHERE 	prod_no  = @prod_no  AND
             	prod_ext = @prod_ext AND
             	part_no  = @part_no  AND
             	seq_no   = @seq_no   

      	IF @@rowcount <= 0 
       	BEGIN
        -- 	UPDATE #prod_use_temp SET err_msg = 'Sequence Number %s Does Not Match Part Number %s.'
 		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_bc_prod_use' AND err_no = -103 AND language = @language
		RAISERROR (@err_msg, 16, 1, @seq_no, @part_no)
		RETURN -103         		
       	END 

      	--Check to verify that if the sequence number is '' then the part supplied = production part
      	IF @seq_no = '' and (@prod_part != @part_no)
       	BEGIN
        -- 	UPDATE #prod_use_temp SET err_msg = 'Produced Item %s Does Not Match Sequence Number.' WHERE row_id = @row_id
 		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error 
				WHERE module = 'SPR' AND trans = 'tdc_bc_prod_use' AND err_no = -104 AND language = @language
		RAISERROR (@err_msg, 16, 1, @prod_part)
		RETURN -104   
       	END
       
      	BEGIN TRAN

	UPDATE next_time_no SET last_no = last_no + 1
	SELECT @time_no = last_no FROM next_time_no

	IF( @lb_track = 'Y' )
	BEGIN	
		SELECT @date_expires = date_expires 
			FROM lot_bin_stock (nolock)
				WHERE location = @location AND part_no = @part_no
				AND   bin_no   = @bin_no   AND lot_ser = @lot_ser

		IF(@scrap_pcs = 0)
		BEGIN
			INSERT INTO prod_use ( 	time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status,
							tran_date, prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, 
							location, shift, who_entered, date_entered, void, lot_ser, bin_no, 
							oper_status, date_expires )
			SELECT  @time_no, @employee_key, @prod_no, @prod_ext, @seq_no, @part_no, 'P', 
					@tran_date, @prod_part, plan_qty - used_qty, @used_qty, 0, 0, 0, 
                   			location, @shift, @who_entered, getdate(), 'N', @lot_ser, @bin_no,
					oper_status, @date_expires
			      	FROM 	prod_list (nolock)
			       	WHERE 	prod_no  = @prod_no  AND
			             	prod_ext = @prod_ext AND
			             	part_no  = @part_no  AND
			             	seq_no   = @seq_no
		END
		ELSE
		BEGIN
			INSERT INTO prod_use ( 	time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status,
							tran_date, prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, 
							location, shift, who_entered, date_entered, void, lot_ser, bin_no, 
							oper_status, date_expires )
			SELECT  @time_no, @employee_key, @prod_no, @prod_ext, @seq_no, @part_no, 'P', 
					@tran_date, @prod_part, plan_qty - used_qty, @scrap_pcs, 0, 0, @scrap_pcs, 
                   			location, @shift, @who_entered, getdate(), 'N', @lot_ser, @bin_no,
					oper_status, @date_expires
			      	FROM 	prod_list (nolock)
			       	WHERE 	prod_no  = @prod_no  AND
			             	prod_ext = @prod_ext AND
			             	part_no  = @part_no  AND
			             	seq_no   = @seq_no
		END
	END
	ELSE	
	BEGIN						
		IF(@ptype = 'R')	-- Resource
		BEGIN
			INSERT INTO prod_use ( 	time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status, 
							tran_date, prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, 
							location, shift, who_entered, date_entered, void ) 
         		SELECT  @time_no, @employee_key, @prod_no, @prod_ext, @seq_no, @part_no, 'P',
					@tran_date, @prod_part, plan_qty - used_qty, @used_qty, plan_pcs - pieces, 0, @scrap_pcs,
                   			location, @shift, @who_entered, getdate(), 'N'
			      	FROM 	prod_list (nolock)
			       	WHERE 	prod_no  = @prod_no  AND
			             	prod_ext = @prod_ext AND
			             	part_no  = @part_no  AND
			             	seq_no   = @seq_no
		END
		ELSE
		BEGIN
			IF(@scrap_pcs = 0)
			BEGIN
				INSERT INTO prod_use ( 	time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status, 
								tran_date, prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, 
								location, shift, who_entered, date_entered, void ) 
	         		SELECT  @time_no, @employee_key, @prod_no, @prod_ext, @seq_no, @part_no, 'P',
						@tran_date, @prod_part, plan_qty - used_qty, @used_qty, 0, 0, 0,
	                   			location, @shift, @who_entered, getdate(), 'N'
				      	FROM 	prod_list (nolock)
				       	WHERE 	prod_no  = @prod_no  AND
				             	prod_ext = @prod_ext AND
				             	part_no  = @part_no  AND
				             	seq_no   = @seq_no
			END
	   		ELSE
			BEGIN
				INSERT INTO prod_use ( 	time_no, employee_key, prod_no, prod_ext, seq_no, part_no, status, 
								tran_date, prod_part, plan_qty, used_qty, plan_pcs, pieces, scrap_pcs, 
								location, shift, who_entered, date_entered, void ) 
	         		SELECT  @time_no, @employee_key, @prod_no, @prod_ext, @seq_no, @part_no, 'P',
						@tran_date, @prod_part, plan_qty - used_qty, @scrap_pcs, 0, 0, @scrap_pcs,
	                   			location, @shift, @who_entered, getdate(), 'N'
				      	FROM 	prod_list (nolock)
				       	WHERE 	prod_no  = @prod_no  AND
				             	prod_ext = @prod_ext AND
				             	part_no  = @part_no  AND
				             	seq_no   = @seq_no
			END
		END
	END                         				                        				                       				              
       		  
    	COMMIT TRAN

END --While

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_bc_prod_use] TO [public]
GO
