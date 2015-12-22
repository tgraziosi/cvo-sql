SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.1 CB 12/16/2010 - Additional parameter for order value
-- v2.0 TM 08/29/2011 - Check for NO Service Lines
-- v2.1 CB 15/11/2011 - Allow routine to be called from SQL
-- v2.2 CB 28/03/2012 - Use value of allocated stock if allocated
-- v2.3 TM 04/11/2012 - If Carrier is USPS% then allow the fractional weights
-- v2.4 CB 16/04/2012 - Only compare the left 5 digits
-- v2.5 CB 20/04/2012 - Fix issue when no freight charge is found
-- v2.6 TM 04/25/2012 - If Country is not US do not consider Zip Code
-- v2.7 CT 21/09/2012 - Added missing logic for Messenger weights
-- v2.8 CB 26/10/2012 - If order has a global ship to then use the zip code from the global ship to
-- v2.9 CB 12/11/2012 - Issue #882 - Remove over weight error
-- v3.0 CB 31/01/2013 - Code change as requested by CVO
-- v3.1 CB 28/02/2013 - Issue #1169 - Calc freight error message based on non backordered stock
-- v3.2 CB 16/04/2013 - Issue #1206 - If -RB or -TB then use ord_list
-- v3.3 CT 24/04/2013 - Issue #1240 - When using cvo_soft_alloc_det to calculate order value, ignore custom frames temple changes
-- v3.4 CB 08/05/2013 - Performance
-- vtag may 3,2013 - put back weight check but only for usps - from v2.9
-- v3.5	CT 11/06/2013 - Issue #1307	- If weight is over carrier maximum then return error message
-- v3.6	CT 28/01/2014 - Issue #1438 - Residential Address additional freight charge
-- v3.7 CB 18/09/2014 - #572 Masterpack - Third Party Ship To 
-- v3.8 CB 22/09/2014 - #572 Masterpack - Global Ship To 
-- v3.9 CB 17/09/2015 - #1540 - weight code for non US
/*
 DECLARE @freight_amt decimal(20,8)
 EXEC [CVO_GetFreight_tot_sp] 1419617, 0, 0, '96782-2657', 1, 'UPS1D', '', 50213.12, @freight_amt OUTPUT
select @freight_amt
*/

CREATE PROCEDURE  [dbo].[CVO_GetFreight_tot_sp]   
			@order_no INT,
			@ext INT,
			@current_freight DECIMAL (20, 8), 
			@zip_code VARCHAR(15), 
			@weight DECIMAL(20, 8), 
			@carrier_code VARCHAR(255),
			@freight_type VARCHAR(30),
			@order_value DECIMAL(20,8) = 0.0, -- v1.1
			@freight_amt decimal(20,8) = 0.0 OUTPUT AS -- v2.1
BEGIN
	SET NOCOUNT ON

	DECLARE @part_no_c		VARCHAR(30),
			@location_c		VARCHAR(30),
			@ordered		DECIMAL(20, 8),
			@available		DECIMAL(20, 8),
			@ordered_i		DECIMAL(20, 8),
			@promo_id		varchar(20),							-- T McGrady	22.MAR.2011
			@promo_level	varchar(30),							-- T McGrady	22.MAR.2011
			@promo_free_frt	varchar(1)								-- T McGrady	22.MAR.2011

	DECLARE @frght_tp		VARCHAR(30),
			@frght_amt		DECIMAL (20, 8),
			@wght			DECIMAL (20, 8),
			@Weight_code	VARCHAR(255),
			@Max_charge		DECIMAL (20, 8),
			@serv_desc		varchar(255),							-- V2.0
			@country_code	varchar(3)								-- v2.6

	DECLARE @IsAllocated	int, -- v2.2
			@global_shipto	varchar(10), -- v2.8
			@global_zip		varchar(20) -- v2.8

	DECLARE	@line_no		int, -- v3.1
			@IsAvailable	int, -- v3.1
			@RBTB			smallint -- v3.2
	
	DECLARE	@row_id			int, -- v3.4
			@last_row_id	int -- 3.4

	DECLARE	@third_party_zip varchar(20) -- v3.6	

	DECLARE	@gs_flat_fee	decimal(20,8) -- v3.8

	CREATE TABLE #parts_temp(
		id			INT,
		part_no		VARCHAR(30),
		location	VARCHAR(20),
		available	DECIMAL(20,8),
		weight		DECIMAL(20,8)
	)

	-- v2.6 Beg
	SET @country_code = ''
	SELECT @country_code = IsNull(ship_to_country_cd,'') FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext -- v3.4
	-- v2.6 End

	-- v3.2 Start
	IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND (RIGHT(user_category,2) = 'TB' OR RIGHT(user_category,2) = 'RB'))
		SET @RBTB = 1
	ELSE
		SET @RBTB = 0
	-- v3.2 End

	-- v2.2 Start
	SET @IsAllocated = 0
	IF EXISTS (SELECT 1 FROM tdc_soft_alloc_tbl (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND order_type = 'S')
		SET @IsAllocated = 1
	-- v2.2 End

	-- v3.4 Start
	CREATE TABLE #gf_ord_list_cursor (
		row_id			int IDENTITY(1,1),
		line_no			int,
		part_no			varchar(30),
		location		varchar(10))

	INSERT	#gf_ord_list_cursor (line_no, part_no, location)
	SELECT line_no, part_no, location FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext

	CREATE INDEX #gf_ord_list_cursor_ind0 ON #gf_ord_list_cursor(row_id)
	
--	DECLARE ord_list_cursor CURSOR
--	FOR SELECT line_no, part_no, location FROM ord_list (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext
--	OPEN ord_list_cursor
--	FETCH NEXT FROM ord_list_cursor
--	INTO @line_no, @part_no_c, @location_c
--
--	WHILE @@FETCH_STATUS = 0
--	BEGIN

	SET @last_row_id = 0

	SELECT	TOP 1 @row_id = row_id,
			@line_no = line_no,
			@part_no_c = part_no,
			@location_c = location
	FROM	#gf_ord_list_cursor
	WHERE	row_id > @last_row_id
	ORDER BY row_id ASC

	WHILE (@@ROWCOUNT <> 0)
	BEGIN
	-- v3.4 End

		IF NOT EXISTS(SELECT 1 FROM #parts_temp WHERE part_no = @part_no_c AND location = @location_c)
		BEGIN
			-- v2.2
			IF @IsAllocated = 1
			BEGIN
				SELECT	@ordered_i = SUM(qty)
				FROM	tdc_soft_alloc_tbl (NOLOCK)
				WHERE	order_no = @order_no
				AND		order_ext = @ext
				AND		order_type = 'S'
				AND		location = @location_c
				AND		part_no = @part_no_c
				AND		line_no = @line_no
			END
			ELSE
			BEGIN

				-- v3.2 Start
				IF (@RBTB = 1)
				BEGIN

					SELECT	@ordered_i = SUM(ordered)
					FROM	ord_list (NOLOCK)
					WHERE	order_no = @order_no AND order_ext = @ext AND part_no = @part_no_c AND location = @location_c AND line_no = @line_no
				END
				ELSE
				BEGIN
					-- v3.1 Start
					SELECT	@IsAvailable = ISNULL(inv_avail,0)
					FROM	cvo_soft_alloc_det (NOLOCK)
					WHERE	order_no = @order_no 
					AND		order_ext = @ext 
					AND		part_no = @part_no_c 
					AND		location = @location_c 
					AND		line_no = @line_no


					IF (@IsAvailable = 1)
					BEGIN

						SELECT	@ordered = SUM(ordered)
						FROM	ord_list (NOLOCK)
						WHERE	order_no = @order_no AND order_ext = @ext AND part_no = @part_no_c AND location = @location_c AND line_no = @line_no

						EXEC @available = [CVO_CheckAvailabilityInStock_sp] @part_no_c, @location_c

						IF @available >= @ordered
							SELECT @ordered_i = @ordered
						ELSE
							SELECT @ordered_i = @available	
					END
					ELSE
					BEGIN
						SET @ordered_i = 0
					END
					-- v3.1 End	
				END -- v3.2 End
			END -- v2.2 End
			
			INSERT INTO #parts_temp (part_no, location, available, weight)		
			VALUES (@part_no_c, @location_c, ISNULL(@ordered_i,0), 0)
		END

		-- v3.4 Start
		SET @last_row_id = @row_id

		SELECT	TOP 1 @row_id = row_id,
				@line_no = line_no,
				@part_no_c = part_no,
				@location_c = location
		FROM	#gf_ord_list_cursor
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

--		FETCH NEXT FROM ord_list_cursor
--		INTO @line_no, @part_no_c, @location_c
	END
	
--	CLOSE ord_list_cursor
--	DEALLOCATE ord_list_cursor
	DROP TABLE #gf_ord_list_cursor
-- v3.4 End

	UPDATE #parts_temp SET weight = p.available * i.weight_ea
	FROM #parts_temp p INNER JOIN inv_master i (NOLOCK) ON p.part_no = i.part_no


	SELECT @weight = SUM(weight) FROM #parts_temp

	-- v2.2 Start
	IF @IsAllocated = 1
	BEGIN
		SELECT	@order_value = SUM((a.curr_price * b.qty) - CASE WHEN a.discount <> 0 THEN (a.curr_price * (a.discount / 100) * b.qty) ELSE 0 END)  
		FROM	ord_list a (NOLOCK)
		JOIN	tdc_soft_alloc_tbl b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext 
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext
		AND		b.order_type = 'S'
	END 
	ELSE -- v3.1 Start
	BEGIN
		SELECT	@order_value = SUM((a.curr_price * a.ordered) - CASE WHEN a.discount <> 0 THEN (a.curr_price * (a.discount / 100) * a.ordered) ELSE 0 END)  
		FROM	ord_list a (NOLOCK)
		JOIN	cvo_soft_alloc_det b (NOLOCK)
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext 
		AND		a.line_no = b.line_no
		WHERE	a.order_no = @order_no
		AND		a.order_ext = @ext
		AND		b.inv_avail = 1
		AND		ISNULL(b.kit_part,0) = 0 -- v3.3

	END -- v3.1 End
	-- v2.2 End

	DROP TABLE #parts_temp

	SELECT @frght_tp = value_str FROM config (NOLOCK) WHERE flag = 'FRTHTYPE'
	
	SELECT @freight_type = ISNULL(@freight_type, '')

	-- IF weight in the sales order is 0, it means that there is not items availables to ship.
	IF @weight = 0
	BEGIN
		IF @frght_tp <>  @freight_type
			SELECT @frght_amt = 0
		ELSE
			SELECT @frght_amt = @current_freight
	END	
	ELSE
	BEGIN
		-- v2.8 Start
		IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND ISNULL(sold_to,'') <> '')
		BEGIN
			SELECT	@global_shipto = sold_to
			FROM	orders_all (NOLOCK)
			WHERE	order_no = @order_no 
			AND		ext = @ext

			SELECT	@global_zip = postal_code,
					@gs_flat_fee = ISNULL(credit_limit,0) -- v3.8
			FROM	armaster_all (NOLOCK) 
			where	customer_code = @global_shipto 
			AND		address_type = 9

			IF ISNULL(@global_zip,'') <> ''
			BEGIN
				SET @zip_code = @global_zip
				
				-- v3.8 Start
				IF (@gs_flat_fee > 0)
				BEGIN
					SET @frght_amt = @gs_flat_fee
					SET @freight_amt = @frght_amt
					SELECT 0, 'OK', @frght_amt
					RETURN
				END
				-- v3.8 End

			END
		END
		-- v2.8 End

		-- v3.6 Start
		IF EXISTS (SELECT 1 FROM cvo_order_third_party_ship_to (NOLOCK) WHERE order_no = @order_no AND order_ext = @ext AND ISNULL(third_party_code,'') <> '')
		BEGIN
			SELECT	@third_party_zip = tp_zip
			FROM	cvo_order_third_party_ship_to (NOLOCK) 
			WHERE	order_no = @order_no 
			AND		order_ext = @ext 
			AND		ISNULL(third_party_code,'') <> ''

			IF ISNULL(@third_party_zip,'') <> ''
				SET @zip_code = @third_party_zip
		END
		-- v3.6 End
	
		-- v2.3
		IF @carrier_code NOT LIKE 'USPS%'	
		BEGIN
			SELECT @weight = CEILING(@weight)
		END

		-- v2.6 Beg
		IF @country_code IN ('US','PR')
		BEGIN
			SELECT	@wght = MAX(Max_weight), @serv_desc = MAX(description)
			FROM	CVO_carriers (NOLOCK)
			WHERE	Carrier = @carrier_code AND
					Lower_zip <= LEFT(@zip_code,5) AND -- v2.4
					Upper_zip >= LEFT(@zip_code,5) -- v2.4
		END
		ELSE
		BEGIN
			SELECT	@wght = MAX(Max_weight), @serv_desc = MAX(description)
			FROM	CVO_carriers (NOLOCK)
			WHERE	Carrier = @carrier_code
		END
		-- v2.6 End


		IF @serv_desc like '%NO SERVICE%'
		BEGIN
			SELECT 1, 'No Service For This Zip Code and Carrier ' + @carrier_code, 0.0
			RETURN
		END

		-- v2.9 Start
		-- VTAG - PUT BACK WEIGHT CHECK ON USPS
		IF @weight > @wght and @carrier_code = 'USPS'
		BEGIN
			SELECT 1, 'Over ' + CAST(CAST(@wght AS DECIMAL(20,4)) AS VARCHAR(20)) + ' lbs. can’t ship ' + @carrier_code, 0.0
			RETURN
		END
		-- v2.9 End


		IF (@wght IS NULL)
		BEGIN
			SELECT 1, 'No charges exist for this weight (' + CAST(CAST(@weight AS DECIMAL(20,4)) AS VARCHAR(20)) + 'lbs) and carrier(' + @carrier_code + ')', 0.0
			RETURN
		END

		IF @frght_tp <>  @freight_type
		BEGIN
			-- v2.6 Beg
			IF @country_code IN ('US','PR')
			BEGIN
				SELECT	@wght = MIN(Max_weight)
				FROM	CVO_carriers (NOLOCK)
				WHERE	Carrier = @carrier_code AND
						Lower_zip <= LEFT(@zip_code,5) AND -- v2.4
						Upper_zip >= LEFT(@zip_code,5) AND -- v2.4
						Max_weight >= @weight

				-- START v3.5
				IF (@wght IS NULL)
				BEGIN
					SELECT 1, 'This order cannot ship via this carrier. Please manually freight.', 0.0
					RETURN
				END
				-- END v3.5

				SELECT	@Weight_code = MIN(Weight_code)
				FROM	CVO_carriers (NOLOCK)
				WHERE	Carrier = @carrier_code AND
						Lower_zip <= LEFT(@zip_code,5) AND -- v2.4
						Upper_zip >= LEFT(@zip_code,5) AND -- v2.4
						Max_weight = @wght
			END
			ELSE
			BEGIN
				SELECT	@wght = MIN(Max_weight)
				FROM	CVO_carriers (NOLOCK)
				WHERE	Carrier = @carrier_code AND
						Max_weight >= @weight
				
				-- START v3.5
				IF (@wght IS NULL)
				BEGIN
					SELECT 1, 'This order cannot ship via this carrier. Please manually freight.', 0.0
					RETURN
				END
				-- END v3.5

				-- v3.9 Start
				SET @Weight_code = ''

				SELECT	@Weight_code = ISNULL(weight_code,'')
				FROM	gl_country (NOLOCK)
				WHERE	country_code = @country_code

				IF (@Weight_code = '')
				BEGIN
					SELECT	@Weight_code = MIN(Weight_code)
					FROM	CVO_carriers (NOLOCK)
					WHERE	Carrier = @carrier_code AND
							Max_weight = @wght
				END
				-- v3.9 End
			END
			-- v2.6 End

			-- tag - 5/2/2013 0 fix usps weight breaks
			-- START v2.7 - if weight code starts with M_ then get freight for 1lb
			IF LEFT(@Weight_code,2) = 'M_'
			BEGIN
				SELECT	@frght_amt = ISNULL(MIN(Weights.charge), 0)
				FROM	CVO_weights Weights (NOLOCK)
				WHERE	Weight_code = @Weight_code AND
						wgt = 1
			END
			IF @WEIGHT_CODE = 'USPS'
			BEGIN
				SELECT @FRGHT_AMT = ISNULL(MIN(weights.charge), 0)
				from cvo_weights weights (nolock)
				where weight_code = @weight_code and wgt > @weight
			end
			if (@weight_code <> 'USPS' AND LEFT(@WEIGHT_CODE,2) <> 'M_')
			BEGIN
				SELECT	@frght_amt = ISNULL(MIN(Weights.charge), 0)
				FROM	CVO_weights Weights (NOLOCK)
				WHERE	Weight_code = @Weight_code AND
						wgt = CEILING(CAST(@weight AS FLOAT)) -- v3.0
						-- v3.0 wgt >= @weight
			END
			-- END v2.7

			-- START v3.6
			-- Add residential charge if applicable
			SET @frght_amt = @frght_amt + ISNULL(dbo.f_calculate_residential_charge (@order_no, @ext),0)
			-- END v3.6
		END
		ELSE
		BEGIN
			SELECT @frght_amt = @current_freight
		END
	END
	
	-- v2.6 Beg
	IF @country_code IN ('US','PR')
	BEGIN
		SELECT	@Max_charge = MAX(Max_charge)
		FROM	CVO_carriers (NOLOCK)
		WHERE	Carrier = @carrier_code AND
				Lower_zip <= LEFT(@zip_code,5) AND -- v2.4
				Upper_zip >= LEFT(@zip_code,5) -- v2.4
	END
	ELSE
	BEGIN
		SELECT	@Max_charge = MAX(Max_charge)
		FROM	CVO_carriers (NOLOCK)
		WHERE	Carrier = @carrier_code
	END
	-- v2.6 End


--	IF @frght_amt > @Max_charge -- v1.1 Use Order Value
	IF @order_value > @Max_charge -- v1.1
	BEGIN
-- v1.1	SELECT 1, 'Over $' + CAST(CAST(@Max_charge AS MONEY) AS VARCHAR(20))  + ' can’t ship ' + @carrier_code, @frght_amt
		SELECT 1, 'Order Value Over $' + CAST(CAST(@Max_charge AS MONEY) AS VARCHAR(20))  + ' can’t ship ' + @carrier_code, @order_value
		RETURN
	END

-- Determine if Free Shipping from Promo																-- T McGrady	22.MAR.2011
	SELECT @promo_free_frt = ISNull(free_shipping,'N')													-- T McGrady	22.MAR.2011
	  FROM cvo_orders_all (NOLOCK)																				-- T McGrady	22.MAR.2011
	 WHERE order_no = @order_no AND ext = @ext															-- T McGrady	22.MAR.2011
																										-- T McGrady	22.MAR.2011
	IF @promo_free_frt = 'Y'																			-- T McGrady	22.MAR.2011
	BEGIN																								-- T McGrady	22.MAR.2011
		SELECT @frght_amt = 0																			-- T McGrady	22.MAR.2011
	END																									-- T McGrady	22.MAR.2011
--			
																				

	-- v2.1
	SET @freight_amt = @frght_amt

-- v1.1	SELECT 0, 'OK', @frght_amt
--	SELECT 0, 'OK', @order_value
	SELECT 0, 'OK', @frght_amt
	RETURN
END


GO
GRANT EXECUTE ON  [dbo].[CVO_GetFreight_tot_sp] TO [public]
GO
