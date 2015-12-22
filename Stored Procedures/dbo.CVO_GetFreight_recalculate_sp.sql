SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  StoredProcedure [dbo].[CVO_GetFreight_recalculate_sp]    Script Date: 04/01/2010  *****
SED002 -- Freight 	  -- Freight Recalculation
Object:      Procedure CVO_GetFreight_recalculate_sp  
Source file: CVO_GetFreight_recalculate_sp.sql
Author:		 Jesus Velazquez
Created:	 04/01/2010
Function:    if 'multi-order Packout' then freight calculation to include all freight amount only in the first order packed into the carton
Modified:    
Calls:    
Called by:   WMS74 -- Ship Confirm Screen
Copyright:   Epicor Software 2010.  All rights reserved.  
v1.0 CB 25/03/2011 - Fix for free shipping on promotions
v1.1 CB 19/10/2011 - Performance
v1.2 CB 28/03/2012 - Use value of allocated stock if allocated
v1.3 TM 04/11/2012 - If Carrier is USPS% then allow the fractional weights
v1.4 CB 16/04/2012 - Only compare the left 5 digits
v1.5 CB 20/04/2012 - Fix issue when no freight charge is found
v2.6 TM 04/25/2012 - When country is not US ignore check on zip code
v2.7 CB 17/07/2012 - When called at the point of allocation need to include what is already packed
v2.8 CB 03/09/2012 - When called at the point of allocation need to include what is picked and not packed
v2.9 CT 21/09/2012 - Added missing logic for Messenger weights
v3.0 CB 12/11/2012 - Issue #882 - Remove over weight error
v3.1 CT 05/12/2012 - New calc_tot_ord_freight value of 2. This is used for calculating freight at carton close for DIM weight
v3.2 CB 31/01/2013 - Code change as requested by CVO
v3.3 CT 20/06/2013 - Issue #1308 - requirement to calculate per carton, change to hold order/carton details in temp table and calculate based on that
v3.4 CT 28/01/2014 - Issue #1438 - Residential Address additional freight charge
v3.5 CB 19/06/2014 - Performance
v3.6 CB 18/09/2014 - #572 Masterpack - Third Party Ship To 
v3.7 CB 22/09/2014 - #572 Masterpack - Global Ship To 
v3.8 CB 17/09/2015 - #1540 - weight code for non US

EXEC CVO_GetFreight_recalculate_sp 1420064, 0, 2
*/

CREATE PROCEDURE  [dbo].[CVO_GetFreight_recalculate_sp]
			@order_no				INT,
			@ext					INT,
			@calc_tot_ord_freight	INT = 0
AS

BEGIN
	
	DECLARE		 @zip_code		VARCHAR(15) 
				,@carrier_code	VARCHAR(255)
				,@freight_type	VARCHAR(30) 
				,@weight		DECIMAL(20,8)
				,@frght_tp		VARCHAR(30)
				,@frght_amt		DECIMAL(20,8)
				,@wght			DECIMAL(20,8)
				,@Weight_code	VARCHAR(255)
				,@Max_charge	DECIMAL(20,8)
				,@country_code	varchar(3),								-- v2.6
				@pack_weight	decimal(20,8), -- v2.7
				@picked_weight	decimal(20,8) -- v2.8

	-- START v3.1
	DECLARE @carton_no		INT,
			@carton_weight	DECIMAL(20,8),
			@carton_type	CHAR(10),
			@dim_weight		DECIMAL(20,8),
			@do_calc		SMALLINT 
	-- END v3.1

	DECLARE @order_value DECIMAL(20,8) -- v1.2

	DECLARE	@third_party_zip varchar(20) -- v3.6	

	DECLARE	@gs_flat_fee	decimal(20,8), -- v3.7
			@global_shipto	varchar(10), -- v3.7
			@global_zip		varchar(20) -- v3.7

	SET @country_code = ''					--v2.6

	SELECT  @zip_code		= ship_to_zip
		   ,@carrier_code	= routing 
		   ,@freight_type	= ISNULL(freight_allow_type,'')
		   ,@country_code = IsNull(ship_to_country_cd,'')				--v2.6 
	FROM	dbo.orders (NOLOCK) -- v1.1
	WHERE	order_no = @order_no AND ext = @ext

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

	-- v3.7 Start
	IF EXISTS (SELECT 1 FROM orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND ISNULL(sold_to,'') <> '')
	BEGIN
		SELECT	@global_shipto = sold_to
		FROM	orders_all (NOLOCK)
		WHERE	order_no = @order_no 
		AND		ext = @ext

		SELECT	@global_zip = postal_code,
				@gs_flat_fee = ISNULL(credit_limit,0) 
		FROM	armaster_all (NOLOCK) 
		where	customer_code = @global_shipto 
		AND		address_type = 9

		IF ISNULL(@global_zip,'') <> ''
		BEGIN
			SET @zip_code = @global_zip
			
			
			IF (@gs_flat_fee > 0)
			BEGIN
				SET @calc_tot_ord_freight = 2
				SET @frght_amt = @gs_flat_fee
			END
			

		END
	END


	-- START v3.3 - create temp table
	CREATE TABLE #cartons(
		carton_no		INT,
		weight			DECIMAL(20,8),
		freight_charge	DECIMAL(20,8))
		
	

	-- v1.0
	IF EXISTS (SELECT 1 FROM dbo.cvo_orders_all (NOLOCK) WHERE order_no = @order_no AND ext = @ext AND free_shipping = 'Y') -- v1.1
		RETURN

	-- START v3.1
	IF @calc_tot_ord_freight = 2
	BEGIN
		-- Loop through each carton for the order and calculate the weight
		SET @do_calc = 0 -- False
		SET @weight = 0
		SET @carton_no = 0
		WHILE 1=1
		BEGIN
			SELECT TOP 1
				@carton_no = carton_no,
				@carton_type = carton_type
			FROM
				dbo.tdc_carton_tx (NOLOCK)
			WHERE
				order_no = @order_no 
				AND order_ext = @ext
				AND carton_no > @carton_no
			ORDER BY
				carton_no

			IF @@ROWCOUNT = 0
				BREAK

			-- Get carton has a DIM weight
			SELECT 
				@dim_weight = ISNULL(weight,0)
			FROM 
				dbo.tdc_pkg_master (NOLOCK)
			WHERE
				pkg_code = @carton_type


			-- Get weight of stock in carton
			SELECT 
				@carton_weight = ISNULL(SUM(ca.pack_qty * i.weight_ea) ,0)
			FROM   
				dbo.tdc_carton_detail_tx ca (NOLOCK) 
			INNER JOIN 
				dbo.inv_master i (NOLOCK) 
			ON 
				ca.part_no = i.part_no 
			WHERE  
				ca.order_no = @order_no 
				AND ca.order_ext = @ext
				AND ca.carton_no = @carton_no
				
			-- If Dim weight is greater than the actual carton weight, use the Dim weight
			IF @dim_weight > @carton_weight 
			BEGIN
				SET @do_calc = 1 -- True	
				SET @carton_weight = @dim_weight
			END
	
			-- START v3.3			
			/*
			-- Add carton weight to order weight
			SET @weight = @weight + @carton_weight
			*/

			-- Store details for carton
			INSERT INTO #cartons(
				carton_no,
				weight,
				freight_charge)
			SELECT
				@carton_no,
				@carton_weight,
				0
			-- END v3.3
		END

		-- Always do the calculation now
		SET @do_calc = 1 -- True	
		
		-- Nothing to do
		IF @do_calc = 0
		BEGIN
			RETURN
		END
	END
	ELSE
	BEGIN

		--BEGIN SED009 -- Freight Processing
		--JVM 09/13/2010
		--freight recalculation according alloc qty
		IF @calc_tot_ord_freight = 0
		BEGIN
			SELECT @weight = ISNULL(SUM(ca.pack_qty * i.weight_ea) ,0)
			FROM   tdc_carton_detail_tx ca (NOLOCK) INNER JOIN inv_master i (NOLOCK) ON ca.part_no = i.part_no -- v1.1
			WHERE  ca.order_no = @order_no AND ca.order_ext = @ext
		END
		ELSE
		BEGIN
			-- v2.7
			SELECT @pack_weight = ISNULL(SUM(ca.pack_qty * i.weight_ea) ,0)
			FROM   tdc_carton_detail_tx ca (NOLOCK) INNER JOIN inv_master i (NOLOCK) ON ca.part_no = i.part_no -- v1.1
			WHERE  ca.order_no = @order_no AND ca.order_ext = @ext

			 SELECT @weight = ISNULL(SUM(sa.qty * i.weight_ea) ,0)  
			 FROM   tdc_soft_alloc_tbl sa (nolock) INNER JOIN inv_master i (nolock) ON sa.part_no = i.part_no  
			 WHERE  sa.order_no = @order_no AND sa.order_ext = @ext
		
			-- v2.8 Start
			 SELECT @picked_weight = ISNULL(SUM(ol.shipped * i.weight_ea) ,0)  
			 FROM	ord_list ol (NOLOCK)
			 INNER JOIN inv_master i (nolock) ON ol.part_no = i.part_no  
			 LEFT JOIN tdc_soft_alloc_tbl sa (nolock) ON ol.order_no = sa.order_no AND ol.order_ext = sa.order_ext AND ol.line_no = sa.line_no
			 LEFT JOIN tdc_carton_detail_tx ca (NOLOCK) ON ol.order_no = ca.order_no AND ol.order_ext = ca.order_ext AND ol.line_no = ca.line_no
			 WHERE  ol.order_no = @order_no AND ol.order_ext = @ext
			 AND sa.line_no IS NULL
			 AND ca.line_no IS NULL

			IF @picked_weight IS NULL
				SET @picked_weight = 0.0

			-- v2.8 end
			
			IF @pack_weight IS NULL
				SET @pack_weight = 0.0

			IF @weight IS NULL
				SET @weight = 0.0

			SET @weight = @weight + @pack_weight + @picked_weight -- v2.8

			-- v1.2
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
		--END   SED009 -- Freight Processing

		-- START v3.3
		INSERT INTO #cartons(
			carton_no,
			weight,
			freight_charge)
		SELECT
			1,
			@weight,
			0
		-- END v3.3
	END
	-- END v3.1

	--PRINT 'peso de las partes @weight'
	--PRINT @weight

		
	-- v2.6 Beg
	IF @country_code IN ('US','PR')
	BEGIN
		SELECT	@wght = MAX(Max_weight)
		FROM	CVO_carriers (NOLOCK) -- v1.1
		WHERE	Carrier = @carrier_code AND
				Lower_zip <= LEFT(@zip_code,5) AND -- v1.4
				Upper_zip >= LEFT(@zip_code,5) -- v1.4
	END
	ELSE
	BEGIN
		SELECT	@wght = MAX(Max_weight)
		FROM	CVO_carriers (NOLOCK) -- v1.1
		WHERE	Carrier = @carrier_code
	END
	-- v2.6 End

	SELECT @frght_tp = value_str FROM config (NOLOCK) WHERE flag = 'FRTHTYPE' -- v1.1

	SELECT @freight_type = ISNULL(@freight_type, '')

	IF @frght_tp <>  @freight_type
	BEGIN

		-- START v3.3
		-- Loop through cratons
		SET @carton_no = 0
		WHILE 1=1
		BEGIN

			SELECT TOP 1
				@carton_no = carton_no,
				@weight = weight
			FROM
				#cartons
			WHERE
				carton_no > @carton_no
			ORDER BY
				carton_no

			IF @@ROWCOUNT = 0
				BREAK

			-- v2.6 Beg
			IF @country_code IN ('US','PR')
			BEGIN
				SELECT	@wght = MIN(Max_weight)
				FROM	CVO_carriers (NOLOCK) -- v1.1
				WHERE	Carrier = @carrier_code AND
						Lower_zip <= LEFT(@zip_code,5) AND -- v1.4
						Upper_zip >= LEFT(@zip_code,5) AND -- v1.4
						Max_weight >= @weight
			--PRINT 'Min Max weight de CVO_carriers @wght'	
			--PRINT @wght --jvm
				SELECT	@Weight_code = MIN(Weight_code)
				FROM	CVO_carriers (NOLOCK) -- v1.1
				WHERE	Carrier = @carrier_code AND
						Lower_zip <= LEFT(@zip_code,5) AND -- v1.4
						Upper_zip >= LEFT(@zip_code,5) AND -- v1.4
						Max_weight = @wght
			--PRINT 'MIN weight_code de CVO_carriers @Weight_code'	
			--PRINT @Weight_code
			END
			ELSE
			BEGIN
				SELECT	@wght = MIN(Max_weight)
				FROM	CVO_carriers (NOLOCK) -- v1.1
				WHERE	Carrier = @carrier_code AND
						Max_weight >= @weight
			--PRINT 'Min Max weight de CVO_carriers @wght'	
			--PRINT @wght --jvm
				-- v3.8 Start
				SET @Weight_code = ''

				SELECT	@Weight_code = ISNULL(weight_code,'')
				FROM	gl_country (NOLOCK)
				WHERE	country_code = @country_code

				IF (@Weight_code = '')
				BEGIN
					SELECT	@Weight_code = MIN(Weight_code)
					FROM	CVO_carriers (NOLOCK) -- v1.1
					WHERE	Carrier = @carrier_code AND
							Max_weight = @wght
				END
				-- v3.8 End
			END
			--v2.6 End

			-- v1.3
			IF @carrier_code NOT LIKE 'USPS%'	
			BEGIN
				SELECT @weight = CEILING(@weight)
			END

			DELETE dbo.cvo_carrier_errors WHERE spid = @@spid AND order_no = @order_no AND order_ext = @ext

			-- v3.0 Start
	--		IF @weight > @wght
	--		BEGIN
	--			INSERT	dbo.cvo_carrier_errors
	--			SELECT	@@spid, @order_no, @ext, 'Over ' + CAST(CAST(@wght AS DECIMAL(20,4)) AS VARCHAR(20)) + ' lbs. can’t ship ' + @carrier_code, @order_value
	--			RETURN
	--		END
			-- v3.0 End		

			IF (@wght IS NULL)
			BEGIN
				INSERT	dbo.cvo_carrier_errors
				SELECT	@@spid, @order_no, @ext, 'No charges exist for this weight (' + CAST(CAST(@weight AS DECIMAL(20,4)) AS VARCHAR(20)) + 'lbs) and carrier(' + @carrier_code + ')', @order_value
				RETURN
			END

			-- START v2.9 - if weight code starts with M_ then get freight for 1lb
			IF LEFT(@Weight_code,2) = 'M_'
			BEGIN
				SELECT	@frght_amt = ISNULL(MIN(Weights.charge), 0)
				FROM	CVO_weights Weights (NOLOCK)
				WHERE	Weight_code = @Weight_code AND
						wgt = 1
			END
			ELSE
			BEGIN
				SELECT	@frght_amt = ISNULL(MIN(Weights.charge), 0)
				FROM	CVO_weights Weights (NOLOCK)
				WHERE	Weight_code = @Weight_code AND
					  wgt = CEILING(CAST(@weight AS FLOAT)) -- v3.2
				-- v3.2	wgt >= @weight
			END
			-- END v2.9
								
			--PRINT 'freight $ @frght_amt'
			--PRINT @frght_amt
			--BEGIN SED009 -- Freight Processing
			--JVM 09/13/2010
			--freight recalculation according alloc qty		

			-- Update temp table
			UPDATE
				#cartons
			SET
				freight_charge = @frght_amt
			WHERE
				carton_no = @carton_no
		END
		
		-- Get total freight amount
		SELECT
			@frght_amt = SUM(ISNULL(freight_charge,0))
		FROM
			#cartons
		-- END v3.3		

		-- v1.2
		-- v2.6 Beg
		IF @country_code IN ('US','PR')
		BEGIN
			SELECT	@Max_charge = MAX(Max_charge)
			FROM	CVO_carriers (NOLOCK)
			WHERE	Carrier = @carrier_code AND
					Lower_zip <= LEFT(@zip_code,5) AND -- v1.4
					Upper_zip >= LEFT(@zip_code,5) -- v1.4
		END
		ELSE
		BEGIN
			SELECT	@Max_charge = MAX(Max_charge)
			FROM	CVO_carriers (NOLOCK)
			WHERE	Carrier = @carrier_code
		END
		--v2.6 End

		-- v1.2
		IF @order_value > @Max_charge -- v1.1
		BEGIN
			IF @calc_tot_ord_freight = 1
			BEGIN
				INSERT	dbo.cvo_carrier_errors
				SELECT	@@spid, @order_no, @ext, 'Order Value Over $' + CAST(CAST(@Max_charge AS MONEY) AS VARCHAR(20))  + ' can’t ship ' + @carrier_code, @order_value
				
			END
		END
		
		-- START v3.4
		-- Add residential charge if applicable
		SET @frght_amt = @frght_amt + ISNULL(dbo.f_calculate_residential_charge (@order_no, @ext),0)
		-- END v3.4

		-- START v3.2
		IF @calc_tot_ord_freight = 2
		BEGIN
			-- v3.7 Start
			IF (@gs_flat_fee > 0)
				SET @frght_amt = @gs_flat_fee
			-- v3.7 End

			IF @do_calc = 1
			BEGIN
				UPDATE 
					dbo.orders WITH (ROWLOCK)
				SET    
					freight	= ISNULL(@frght_amt,0.00),
					tot_ord_freight	= ISNULL(@frght_amt,0.00)
				WHERE  
					order_no = @order_no 
					AND ext = @ext
			END
		END
		ELSE
		BEGIN
			IF @calc_tot_ord_freight = 0
				BEGIN
					UPDATE dbo.orders WITH (ROWLOCK)
					SET    freight	= @frght_amt
					WHERE  order_no = @order_no AND ext = @ext
				END
			ELSE
				BEGIN				
	--				IF @weight = 0 --no alloc qty
	--					SET @frght_amt = 0.00
						
					UPDATE dbo.orders WITH (ROWLOCK)
					SET    tot_ord_freight	= ISNULL(@frght_amt,0.00)
					WHERE  order_no = @order_no AND ext = @ext
				END
			--END   SED009 -- Freight Processing
		END
		-- END v3.2
	END
END
GO
GRANT EXECUTE ON  [dbo].[CVO_GetFreight_recalculate_sp] TO [public]
GO
