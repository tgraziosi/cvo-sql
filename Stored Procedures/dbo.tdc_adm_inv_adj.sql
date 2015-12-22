SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****************************************************************************************/
/* This procedure adjusts inventory by creating an issue 				*/
/* to either add or remove some quantity of an item      				*/
/* if the entered date expire does not exists in inventory for this lot bin part	*/
/* the inventory will be updated.							*/
/****************************************************************************************/
CREATE PROC [dbo].[tdc_adm_inv_adj] 
AS
  
SET NOCOUNT ON

DECLARE @recid int, 
	@issue_no int, 
	@part varchar(30), 
	@loc varchar(10),
	@qty decimal(20,8),
	@bin varchar(12),
	@dir int,
	@code varchar(8),
	@who varchar(50),
	@reason_code varchar(10),
	@date_exp datetime,
	@lot varchar(25),
	@language varchar(10),
	@msg varchar(255),
	@lb_tracking char(1),
	@cost_flag char(1),
	@avg_cost decimal(20,8),
	@direct_dolrs decimal(20,8),
	@ovhd_dolrs decimal(20,8),
	@util_dolrs decimal(20,8),
	@serial_flag int,
	@uom varchar(2)

DECLARE @mtrl_account_expense varchar (32), 
	@direct_account_expense varchar (32), 
	@ovhd_account_expense varchar (32), 
	@util_account_expense varchar (32),
	@inv_cost_method char(1)

SELECT @recid = 0	/* Find the first record */

BEGIN TRAN

/* Look at each record... */
WHILE (@recid >= 0)
BEGIN
	SELECT @recid = ISNULL((SELECT MIN(row_id) FROM #adm_inv_adj WHERE row_id > @recid), -1)
      	IF @recid = -1 BREAK

      	SELECT @part = part_no, @loc = loc, @qty = qty, @bin = bin_no, @dir = direction, @code = code,
		@who = who_entered, @reason_code = reason_code, @date_exp = date_exp, @lot = lot_ser,
		@avg_cost = avg_cost, @direct_dolrs = direct_dolrs, @ovhd_dolrs = ovhd_dolrs, 
		@util_dolrs = util_dolrs, @cost_flag = cost_flag
		FROM #adm_inv_adj 
			WHERE row_id = @recid
	
	SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = @who), 'us_english')
	-- SCR #35149. get user log in without domain
	SELECT @who = login_id FROM #temp_who

      	/* Make sure part number exists */
      	SELECT @lb_tracking = lb_tracking, @serial_flag = serial_flag, @uom = uom, @inv_cost_method = inv_cost_method 
	  FROM inv_master (nolock)
	 WHERE part_no = @part

	IF (@@ROWCOUNT = 0)
        BEGIN
          	IF @@TRANCOUNT > 0 ROLLBACK TRAN
		-- Error: Part number %s is not valid.
          	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -101 AND language = @language
		RAISERROR (@msg, 16, 1, @part)
          	RETURN -101
        END

        /* Make sure location exists */
        IF NOT EXISTS (SELECT * FROM locations (nolock) WHERE location = @loc)
        BEGIN
            	IF @@TRANCOUNT > 0 ROLLBACK TRAN
		-- Error: Location %s is not valid.
          	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -102 AND language = @language
		RAISERROR (@msg, 16, 1, @loc)
            	RETURN -102
  	END

	IF NOT EXISTS ( SELECT * FROM inventory (nolock) WHERE location = @loc AND part_no = @part )
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		-- Error: Item %s does not exist at location %s.
		SELECT @msg = err_msg FROM tdc_lookup_error WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -103 AND language = @language
		RAISERROR (@msg, 16, 1, @part, @loc)
		RETURN -103
	END

       	/* Make sure quantity is positive */
	IF (@qty <= 0.0)
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		-- Error: Adjustment quantity must be positive.
          	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -104 AND language = @language
		RAISERROR (@msg, 16, 1)
              	RETURN -104
     	END

	/* Make sure direction is 1 or -1 */
	IF (@dir NOT IN (1, -1))
	BEGIN
		IF @@TRANCOUNT > 0 ROLLBACK TRAN 
		-- Error: Incorrect direction %d.
          	SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -105 AND language = @language
		RAISERROR (@msg, 16, 1, @dir)
                RETURN -105
	END

	/* If lot bin tracking is off for the item... */
	IF (@lb_tracking = 'Y')
		IF ((@bin IS NULL) OR (@lot IS NULL) OR (@date_exp IS NULL))
		BEGIN
			IF @@TRANCOUNT > 0 ROLLBACK TRAN 
			-- Error: Lot bin info required for item %s.
          		SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -106 AND language = @language
			RAISERROR (@msg, 16, 1, @part)
                      	RETURN -106
		END

	/* If removing from inventory... */
	IF ( @dir = -1 ) 
	BEGIN
		IF (@lb_tracking = 'Y')
		BEGIN
			IF NOT EXISTS ( SELECT * FROM lot_bin_stock (nolock)
							WHERE bin_no = @bin AND lot_ser = @lot AND
                                           		location = @loc AND part_no = @part)
			BEGIN
                                IF @@TRANCOUNT > 0 ROLLBACK TRAN
				-- Error: Invalid lot bin information for item %s.
          			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -107 AND language = @language
				RAISERROR (@msg, 16, 1, @part)
                                RETURN -107
			END

			IF ( SELECT isnull(qty, 0) FROM lot_bin_stock 
							WHERE bin_no = @bin AND lot_ser = @lot AND
                                           		location = @loc AND part_no = @part ) < @qty
			BEGIN
                                IF @@TRANCOUNT > 0 ROLLBACK TRAN
				-- Error: There is not enough of item %s in stock.
          			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -108 AND language = @language
				RAISERROR (@msg, 16, 1, @part)
                                RETURN -108
			END
		END
		ELSE
		BEGIN
			IF NOT EXISTS ( SELECT * FROM inventory (nolock)
							WHERE location = @loc AND part_no = @part AND in_stock >= @qty )
                        BEGIN
                                IF @@TRANCOUNT > 0 ROLLBACK TRAN
				-- Error: There is not enough of item %s in stock.
          			SELECT @msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_inv_adj' AND err_no = -108 AND language = @language
				RAISERROR (@msg, 16, 1, @part)
                                RETURN -108
                        END
                END
	END
 
	/* Get the next issue number */
	SELECT @issue_no = (SELECT last_no FROM next_iss_no) + 1
	UPDATE next_iss_no SET last_no = @issue_no
	IF OBJECT_ID('tempdb..#account_for_adj') IS NOT NULL
	BEGIN
		DROP TABLE #account_for_adj
	END

	CREATE TABLE #account_for_adj (
			account varchar (32),
			direct_account_expense varchar (32), 
			ovhd_account_expense varchar (32),
			util_account_expense varchar (32),
			desc_account varchar (40),
			desc_direct_accnt varchar (40),
			desc_ovhd_accnt varchar (40),
			desc_util_accnt varchar (40),
			ref_account_flag int,
			ref_direct_accnt_flag int,
			ref_ovhd_accnt_flag int,
			ref_util_accnt_flag int 
		) 

	INSERT #account_for_adj (
			account,
			direct_account_expense , 
			ovhd_account_expense ,
			util_account_expense ,
			desc_account ,
			desc_direct_accnt ,
			desc_ovhd_accnt ,
			desc_util_accnt ,
			ref_account_flag ,
			ref_direct_accnt_flag ,
			ref_ovhd_accnt_flag ,
			ref_util_accnt_flag
		) EXEC dbo.fs_issue_code_gl_accounts_sp_wrap @code

	SELECT 	@mtrl_account_expense = account, 
		@direct_account_expense = direct_account_expense,
		@ovhd_account_expense = ovhd_account_expense, 
		@util_account_expense = util_account_expense 
		FROM #account_for_adj
		
	IF ( @cost_flag = 'Y' ) -- allow update cost
	BEGIN
		
		IF (@lb_tracking = 'Y')
		BEGIN
			INSERT INTO dbo.lot_serial_bin_issue  
					( line_no, tran_no,   part_no, location, bin_no, tran_code, date_tran,  date_expires, qty,  direction, uom,  who, cost,    lot_ser, tran_ext ) 
					SELECT 	1, @issue_no, @part,   @loc,     @bin,    'I',       getdate(), @date_exp,    @qty, @dir,   @uom, @who,   @avg_cost, @lot,     0 
						FROM inv_list inv 
							WHERE inv.part_no = @part AND inv.location = @loc
		END

		INSERT INTO issues ( issue_no,  part_no, location_from, avg_cost,  who_entered, code, issue_date, qty, inventory, direction, lb_tracking,  direct_dolrs,  ovhd_dolrs,  util_dolrs,     labor,  reason_code,  mtrl_account_expense,  direct_account_expense,  ovhd_account_expense,  util_account_expense,  serial_flag ) 
			SELECT 	    @issue_no, @part,   @loc,          @avg_cost, @who,        @code, getdate(), @qty, 'N',      @dir,      @lb_tracking, @direct_dolrs, @ovhd_dolrs, @util_dolrs, inv.labor, @reason_code, @mtrl_account_expense, @direct_account_expense, @ovhd_account_expense, @util_account_expense, @serial_flag 
				FROM inventory inv 
					WHERE inv.part_no = @part AND inv.location = @loc
	END
	ELSE
	BEGIN
		IF (@inv_cost_method != 'S')
		BEGIN

			-- This insert was moved in front of the insert into issues so the new lot serial costing method would work
			IF (@lb_tracking = 'Y')
			BEGIN
				SELECT @avg_cost = 0
				SELECT @avg_cost = avg_cost FROM inv_list (nolock) WHERE location = @loc AND part_no = @part
				INSERT INTO dbo.lot_serial_bin_issue  
					( line_no, tran_no,   part_no, location, bin_no, tran_code, date_tran,  date_expires, qty,  direction, uom,  who,     cost,  lot_ser, tran_ext ) 
					VALUES(	1, @issue_no, @part,   @loc,     @bin,    'I',       getdate(), @date_exp,    @qty, @dir,   @uom, @who, @avg_cost, @lot,     0 )
			END

			INSERT INTO issues ( issue_no,  part_no, location_from, avg_cost,  who_entered, code, issue_date, qty, inventory, direction, lb_tracking,         direct_dolrs,         ovhd_dolrs,         util_dolrs,     labor,  reason_code,  mtrl_account_expense,  direct_account_expense,  ovhd_account_expense,  util_account_expense,  serial_flag ) 
				SELECT 	    @issue_no, @part,   @loc,       inv.avg_cost, @who,        @code, getdate(), @qty, 'N',      @dir,      @lb_tracking, inv.avg_direct_dolrs, inv.avg_ovhd_dolrs, inv.avg_util_dolrs, inv.labor, @reason_code, @mtrl_account_expense, @direct_account_expense, @ovhd_account_expense, @util_account_expense, @serial_flag 
					FROM inv_list inv (nolock)
						WHERE inv.part_no = @part AND inv.location = @loc

		END
		ELSE
		BEGIN

			-- This insert was moved in front of the insert into issues so the new lot serial costing method would work
			IF (@lb_tracking = 'Y')
			BEGIN
				SELECT @avg_cost = 0
				SELECT @avg_cost = std_cost FROM inv_list (nolock) WHERE location = @loc AND part_no = @part
				INSERT INTO dbo.lot_serial_bin_issue  
					( line_no, tran_no,   part_no, location, bin_no, tran_code, date_tran,  date_expires, qty,  direction, uom,  who,     cost,  lot_ser, tran_ext ) 
					VALUES(	1, @issue_no, @part,   @loc,     @bin,    'I',       getdate(), @date_exp,    @qty, @dir,   @uom, @who, @avg_cost, @lot,     0 )
			END

			INSERT INTO issues ( issue_no,  part_no, location_from, avg_cost,  who_entered, code, issue_date, qty, inventory, direction, lb_tracking,         direct_dolrs,         ovhd_dolrs,         util_dolrs,     labor,  reason_code,  mtrl_account_expense,  direct_account_expense,  ovhd_account_expense,  util_account_expense,  serial_flag ) 
				SELECT 	    @issue_no, @part,   @loc,       inv.std_cost, @who,        @code, getdate(), @qty, 'N',      @dir,      @lb_tracking, inv.std_direct_dolrs, inv.std_ovhd_dolrs, inv.std_util_dolrs, inv.labor, @reason_code, @mtrl_account_expense, @direct_account_expense, @ovhd_account_expense, @util_account_expense, @serial_flag 
					FROM inv_list inv (nolock)
						WHERE inv.part_no = @part AND inv.location = @loc
		END

	
	END

	UPDATE #adm_inv_adj SET adj_no = @issue_no WHERE row_id = @recid
END -- end while loop

IF @@ERROR = 0
BEGIN
	IF @@TRANCOUNT > 0 COMMIT TRAN
END
ELSE
BEGIN
	IF @@TRANCOUNT > 0 ROLLBACK TRAN
END

RETURN @issue_no
GO
GRANT EXECUTE ON  [dbo].[tdc_adm_inv_adj] TO [public]
GO
