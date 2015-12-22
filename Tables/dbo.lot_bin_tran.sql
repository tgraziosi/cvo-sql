CREATE TABLE [dbo].[lot_bin_tran]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[direction] [smallint] NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [decimal] (20, 8) NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[line_no] [int] NOT NULL,
[who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t500dellbtran] ON [dbo].[lot_bin_tran]   FOR DELETE AS 
BEGIN
	rollback tran
	exec adm_raiserror 73899 ,'You Cannot Delete A Transaction'
	return
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[t500updlbtran] ON [dbo].[lot_bin_tran]   FOR UPDATE  AS 
BEGIN
	rollback tran
	exec adm_raiserror 93831, 'You Cannot Update A Transaction'
	return
END

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/04/2015 - Performance Changes 
-- v1.1 CB 28/07/2015 - Writing tdc log only when stock actually received for auto receive credits (credit return posting)
 
  
CREATE TRIGGER [dbo].[t603inslbtran] ON [dbo].[lot_bin_tran] 
FOR INSERT  
AS   
BEGIN  
  
	declare @c_tran_code char(1)  
	declare @c_config_val varchar(20)  
	declare @c_config_flag_class varchar(10)  
	declare @c_part_no  varchar(30)  
	declare @c_last_lot varchar(25)  
	declare @i_serial_flag smallint  
	declare @i_ret_val int  
	declare @error varchar(100)  
	declare @i_ser_count int  
	declare @c_bin_no varchar(12), @c_location varchar(10), @c_lot_ser varchar(25),  
	  @c_tran_no int, @c_tran_ext int, @c_date_tran datetime, @c_date_expires datetime,  
	  @c_qty decimal(20,8), @c_direction int, @c_line_no int, @c_cost decimal(20,8)  
	declare @c_last_part varchar(30), @c_last_loc varchar(10), @c_last_bin varchar(12)  
	declare @test_sum decimal(20,8)  
	DECLARE @eq decimal(20,8), @tdc_rtn int  
	DECLARE @data			VARCHAR(7500) -- v1.1
	DECLARE @who_entered varchar(20),@part_type	CHAR(1) -- v1.1
  
	IF EXISTS (SELECT *  FROM inserted WHERE bin_no < '!' OR lot_ser < '!')   
	BEGIN  
		ROLLBACK TRAN   
		EXEC adm_raiserror 83803 ,'You Must Have A Valid Lot/Bin Number Entered.'  
		RETURN  
	END   
     
	SELECT @c_config_val = UPPER(ISNULL((SELECT value_str FROM config (NOLOCK) WHERE flag = 'INV_LOT_BIN'),'YES'))  
	SELECT @c_last_part = '', @c_last_loc = '', @c_last_bin = '', @c_last_lot = ''  
  
	-- v1.0 Start
	DECLARE	@row_id			int,
			@last_row_id	int

	CREATE TABLE #c_lbt (
		row_id			int IDENTITY(1,1),
		c_part_no		varchar(30) NULL,
		c_location		varchar(10) NULL,
		c_bin_no		varchar(12) NULL,
		c_lot_ser		varchar(25) NULL,
		c_tran_code		char(1) NULL,
		c_tran_no		int NULL,
		c_tran_ext		int NULL,
		c_date_tran		datetime NULL,
		c_date_expires	datetime NULL,
		c_qty			decimal(20,8) NULL,
		c_direction		int,
		c_cost			decimal(20,8) NULL,
		c_line_no		int,
		i_serial_flag	smallint NULL)

	INSERT	#c_lbt (c_part_no, c_location, c_bin_no, c_lot_ser, c_tran_code, c_tran_no, c_tran_ext, c_date_tran, c_date_expires, c_qty,
				c_direction, c_cost, c_line_no, i_serial_flag)	
	-- v1.0 DECLARE c_lbt CURSOR FOR  
	SELECT	i.part_no, i.location, i.bin_no, i.lot_ser, i.tran_code, i.tran_no,   
			i.tran_ext, i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.line_no, isnull(serial_flag,0)  
	FROM	inserted i  
	LEFT OUTER JOIN inv_master m (NOLOCK) 
	ON		i.part_no = m.part_no  
	ORDER BY i.part_no, i.lot_ser, i.location, i.bin_no  
  
	-- v1.0 OPEN c_lbt  
  
	-- Get first row  
	-- v1.0 FETCH c_lbt INTO @c_part_no, @c_location, @c_bin_no, @c_lot_ser, @c_tran_code, @c_tran_no,  
	-- v1.0 @c_tran_ext, @c_date_tran, @c_date_expires, @c_qty, @c_direction, @c_cost, @c_line_no, @i_serial_flag  
  
	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@c_part_no = c_part_no, 
			@c_location = c_location, 
			@c_bin_no = c_bin_no, 
			@c_lot_ser = c_lot_ser, 
			@c_tran_code = c_tran_code, 
			@c_tran_no = c_tran_no, 
			@c_tran_ext = c_tran_ext, 
			@c_date_tran = c_date_tran, 
			@c_date_expires = c_date_expires, 
			@c_qty = c_qty,
			@c_direction = c_direction, 
			@c_cost = c_cost, 
			@c_line_no = c_line_no, 
			@i_serial_flag = i_serial_flag
	FROM	#c_lbt
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	-- v1.0 WHILE @@fetch_status = 0  
	WHILE (@@ROWCOUNT <> 0)
	BEGIN  
    
		IF (@i_serial_flag = 1) and @c_tran_code in ('A', 'B', 'R', 'P', 'S', 'I','V','C','Q')  -- mls 4/23/02 SCR 28797  
		-- mls 7/27/01 SCR 27301 4/20/01 SCR 26762  
		BEGIN  --if serial controlled  
			IF @c_last_lot = @c_lot_ser AND @c_last_part = @c_part_no  
			BEGIN  
				-- v1.0 CLOSE c_lbt  
				-- v1.0 DEALLOCATE c_lbt  
				ROLLBACK TRAN   
				SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) is duplicated in the data that you just entered..'  
				EXEC adm_raiserror 90000, @error  
				RETURN  
			END  
		  
			IF @c_config_val = 'RELAXED'       -- mls 7/11/05 SCR 35142  
			BEGIN  
				SELECT @test_sum = ISNULL((SELECT COUNT(*) FROM lot_bin_ship i (NOLOCK) WHERE i.part_no = @c_part_no AND i.lot_ser = @c_lot_ser AND i.tran_no = @c_tran_no),0)  
				IF @test_sum > 1      -- mls 7/11/05 SCR 35142  
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) already exists on this order.'  
					EXEC adm_raiserror 90000, @error  
					RETURN  
				END  
			END  
  
			SELECT @test_sum = ISNULL((SELECT SUM(i.direction * i.qty) FROM inserted i   
							WHERE i.part_no = @c_part_no AND i.lot_ser = @c_lot_ser AND i.tran_code = @c_tran_code),0)  
	  
			IF @test_sum NOT IN (0,1,-1)       -- mls 7/11/05 SCR 35142  
			BEGIN  
				-- v1.0 CLOSE c_lbt  
				-- v1.0 DEALLOCATE c_lbt  
				ROLLBACK TRAN   
				SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) must have a qty of 1.'  
				EXEC adm_raiserror 90000, @error  
				RETURN  
			END  
  
			IF (@test_sum > 0 AND @c_tran_code != 'S')   
			--      or (@test_sum < 0 and @c_tran_code = 'S' and @c_config_val = 'RELAXED' )  -- mls 12/14/01 SCR 28068  
			BEGIN --if input action  
          
				EXEC @i_ret_val = ser_vrf_serial_no @c_part_no, @c_lot_ser, @c_tran_code  
				IF @i_ret_val = -1  
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) was shipped.  Must do credit return.'  
					EXEC adm_raiserror 90000, @error  
					RETURN  
				END  
        
				IF @i_ret_val = -2  
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) was adjusted out.  Must do inventory adjustment.'  
					EXEC adm_raiserror 90000, @error  
					RETURN  
				END  
			
				IF @i_ret_val > 0   
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Serial Number ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) already exists.'  
					EXEC adm_raiserror 90000, @error  
					RETURN  
				END  
          
				EXEC ser_ins_serial_no @c_part_no, @c_lot_ser, @c_tran_code  
				IF @@error <> 0   
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Problem inserting serial number  ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) into serial_ctrl table.'  
					EXEC adm_raiserror 90001 ,@error  
					RETURN  
				END  
			END --if input action  
      
			IF ((@test_sum > 0) AND (@c_tran_code = 'S') AND (@c_config_val = 'RELAXED')) OR  
				((@test_sum < 0) AND (@c_tran_code IN ( 'B', 'R', 'P','I','V','C','S','Q') )) -- mls 4/23/02 SCR 28797  
			-- mls 7/27/01 SCR 27301  4/20/01 SCR 26762  
			BEGIN --if output action  
				EXEC @i_ret_val = ser_del_serial_no @c_part_no, @c_lot_ser, @c_tran_code  
				IF @i_ret_val > 0   
				BEGIN  
					-- v1.0 CLOSE c_lbt  
					-- v1.0 DEALLOCATE c_lbt  
					ROLLBACK TRAN   
					SELECT @error = 'Problem deleting serial number  ([' + @c_lot_ser +  ']) for Part ([' + @c_part_no + ']) from serial_ctrl table.'  
					EXEC adm_raiserror 90001, @error  
					RETURN  
				END   
			END --if output action  
		END -- if serial controlled  
    
		-- Now you update the lot_bin_stock table to see if it is a current part.  This update can fail with no problems, the insert further down  will fire if it is a new record.  
		-- Be aware that if there is a serial number for a serial controlled part, and the serial number is currently in stock, this should fire and cause an error from  
		-- lot_bin stock, along the lines of 'Serial controlled parts cannot have a qty that exceeds '1'.'  
  
		-- NOTE: This updates the expiration date specifically for the alter reciepts functionality.  This means that if   
		-- anywhere else in the code the app is sloppy about saving the expiration date it might be reset with this.  What  
		-- can be done to improve this is have the expiration date set to a local variable that is set by checking to see  
		-- if the transaction type is from the recieving side, because an update from the recieving side most likely is going to  
		-- be alter reciepts. RLT  
		IF @c_tran_code NOT IN ( 'Q','A')     -- mls 4/23/02 SCR 28797 -- mls 3/18/03 SCR 30856  
		BEGIN  
  
			IF (@c_direction * @c_qty) < 0   
			BEGIN  
  
				-- This is here so no part can be negative on a part that is not in stock, otherwise the insert statement would insert a negative qty.  
  
				IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE location = @c_location AND part_no = @c_part_no AND bin_no = @c_bin_no AND lot_ser = @c_lot_ser )  
				BEGIN  
					UPDATE	lot_bin_stock   
					SET		qty = lot_bin_stock.qty + (@c_direction * @c_qty),  
							cost = @c_cost   
					--      date_expires = @c_date_expires --RLT 6/27/00 SCR 23183  -- mls 8/30/01 SCR 27508  
					WHERE	location = @c_location 
					AND		part_no = @c_part_no 
					AND		bin_no = @c_bin_no 
					AND		lot_ser = @c_lot_ser   
  
					IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE location = @c_location AND part_no = @c_part_no AND bin_no = @c_bin_no AND lot_ser = @c_lot_ser AND qty < 0)  
					BEGIN  
						-- v1.0 CLOSE c_lbt  
						-- v1.0 DEALLOCATE c_lbt  
						ROLLBACK TRAN   
						EXEC adm_raiserror 83831, 'In Stock Quantity Is Less Than ZERO!'  
						RETURN  
					END  
				END  
				ELSE  
				BEGIN  
					IF @c_config_val = 'YES'  
					BEGIN        
						-- v1.0 CLOSE c_lbt  
						-- v1.0 DEALLOCATE c_lbt  
						ROLLBACK TRAN   
						EXEC adm_raiserror 83833, 'No Stock Exists - Can Not Do A Negative Transaction!'  
						RETURN  
					END     
				END  
			END  --  < 0  
			ELSE  
			BEGIN  
				-- This inserts into the lot_bin_stock table any new items that are not currently in stock.  At this time, this can enter any serial number that it wants.  
				-- Up above is the check to see whether the serial number is unique, before it tries to insert it into lot_bin_stock down here.  
				IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE location = @c_location AND part_no = @c_part_no AND bin_no = @c_bin_no AND lot_ser = @c_lot_ser)  
				BEGIN  
					UPDATE	lot_bin_stock   
					SET		qty = lot_bin_stock.qty + (@c_direction * @c_qty),  
							cost = @c_cost ,   
							date_expires = @c_date_expires   
					--		date_expires = case when @c_tran_code = 'C' then date_expires else @c_date_expires end -- mls 8/30/01 SCR 27508  
					--RLT 6/27/00 SCR 23183  
					WHERE	location = @c_location 
					AND		part_no = @c_part_no 
					AND		bin_no = @c_bin_no 
					AND		lot_ser = @c_lot_ser  
				END  
				ELSE  
				BEGIN   
					IF @c_config_val = 'YES'  
					BEGIN  
						INSERT lot_bin_stock (location,part_no,bin_no,lot_ser,date_tran,date_expires,qty,cost,qty_physical)  
						SELECT	@c_location, @c_part_no, @c_bin_no, @c_lot_ser, @c_date_tran,   
								convert(char(8),@c_date_expires,1) , (@c_qty * @c_direction), @c_cost, 0   
					END  
				END  
			END  

			-- v1.1 Start
			IF (@c_tran_code = 'C')
			BEGIN
				IF EXISTS (SELECT 1 FROM CVO_auto_receive_credit_return (NOLOCK) WHERE order_no = @c_tran_no AND ext = @c_tran_ext
							AND processed >= 2)
				BEGIN

					SELECT @data = dbo.f_create_tdc_log_data_string (@c_tran_no,@c_tran_ext,@c_line_no) 

					SELECT	@who_entered = who_entered
					FROM	orders_all (NOLOCK)
					WHERE	order_no = @c_tran_no
					AND		ext = @c_tran_ext

					SELECT	@part_type = part_type
					FROM	ord_list (NOLOCK)
					WHERE	order_no = @c_tran_no
					AND		order_ext = @c_tran_ext
					AND		line_no = @c_line_no

					INSERT INTO dbo.tdc_log  WITH (ROWLOCK) (tran_date, UserID, trans_source, module, trans, tran_no,
							tran_ext, part_no, lot_ser, bin_no, location, quantity, data) 										
					SELECT	GETDATE(), @who_entered, 'CO', 'ADH', 'CRRETN', CAST(@c_tran_no AS VARCHAR(20)),
							CAST(@c_tran_ext AS VARCHAR(5)), @c_part_no, CASE @part_type WHEN 'P' THEN @c_lot_ser ELSE '' END, 
							CASE @part_type WHEN 'P' THEN @c_bin_no ELSE '' END, @c_location, CAST(CAST(@c_qty AS INT) AS VARCHAR(20)), 
							@data

					UPDATE	CVO_auto_receive_credit_return
					SET		processed = 3
					WHERE	order_no = @c_tran_no 
					AND		ext = @c_tran_ext
				END
			END
			-- v1.1 End
  
			SELECT @c_last_lot = @c_lot_ser, @c_last_part = @c_part_no, @c_last_loc = @c_location, @c_last_bin = @c_bin_no  
	  
			SELECT	@eq = ISNULL((SELECT qty FROM lot_bin_stock (NOLOCK) WHERE location = @c_location AND part_no = @c_part_no AND bin_no = @c_bin_no AND lot_ser = @c_lot_ser),0)  
  
			EXEC @tdc_rtn = tdc_inventory_update @c_location, @c_part_no, @c_lot_ser, @c_bin_no, @eq, @c_qty, @c_direction, @c_tran_no  
  
			IF ( @tdc_rtn < 0 )  
			BEGIN  
				-- v1.0 CLOSE c_lbt  
				-- v1.0 DEALLOCATE c_lbt  
				ROLLBACK TRAN   
				EXEC adm_raiserror 84900 ,'Invalid Inventory Update From TDC.'  
				RETURN  
			END  
		END -- c_tran_code not 'Q' or 'A'  
  
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@c_part_no = c_part_no, 
				@c_location = c_location, 
				@c_bin_no = c_bin_no, 
				@c_lot_ser = c_lot_ser, 
				@c_tran_code = c_tran_code, 
				@c_tran_no = c_tran_no, 
				@c_tran_ext = c_tran_ext, 
				@c_date_tran = c_date_tran, 
				@c_date_expires = c_date_expires, 
				@c_qty = c_qty,
				@c_direction = c_direction, 
				@c_cost = c_cost, 
				@c_line_no = c_line_no, 
				@i_serial_flag = i_serial_flag
		FROM	#c_lbt
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC	

		-- v1.0 FETCH c_lbt INTO @c_part_no, @c_location, @c_bin_no, @c_lot_ser, @c_tran_code, @c_tran_no,  
		-- v1.0 @c_tran_ext, @c_date_tran, @c_date_expires, @c_qty, @c_direction, @c_cost, @c_line_no, @i_serial_flag  
	END --while part  
  
	-- v1.0 CLOSE c_lbt  
	-- v1.0 DEALLOCATE c_lbt  
  
	--Deletes all the zero qty's in stock  
	DELETE	lot_bin_stock   
	FROM	inserted   
	WHERE	lot_bin_stock.location = inserted.location 
	AND		lot_bin_stock.part_no = inserted.part_no 
	AND		lot_bin_stock.bin_no = inserted.bin_no 
	AND		lot_bin_stock.lot_ser = inserted.lot_ser 
	AND		lot_bin_stock.qty = 0  
    
END  
GO
CREATE NONCLUSTERED INDEX [lbtrn1] ON [dbo].[lot_bin_tran] ([location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [lbtrn2] ON [dbo].[lot_bin_tran] ([tran_code], [tran_no]) WITH (ALLOW_PAGE_LOCKS=OFF) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_tran] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_tran] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_tran] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_tran] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_tran] TO [public]
GO
