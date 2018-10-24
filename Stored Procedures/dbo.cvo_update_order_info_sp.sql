SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_order_info_sp]	@order_no				int,
											@order_ext				int,
											@freight_allow_type		varchar(10),
											@attention				varchar(40),
											@phone					varchar(20),
											@cust_po				varchar(20),
											@user_category			varchar(10),				
											@so_priority_code		char(1),
											@routing				varchar(20),
											@terms_code				varchar(10),
											@sold_to				varchar(10),	
											@sch_ship_date			datetime,
											@note					varchar(255),
											@special_instr			varchar(255),
											@delivery_date			datetime, -- v1.4
											@free_shipping			varchar(10) -- v1.5

AS
BEGIN
	-- Directives
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF
	
	-- Declarations
	DECLARE	@ret					int,
			@has_update				int,
			@message				varchar(255),
			@o_freight_allow_type	varchar(10),
			@o_attention			varchar(40),
			@o_phone				varchar(20),
			@o_cust_po				varchar(20),
			@o_user_category		varchar(10),				
			@o_so_priority_code		char(1),
			@o_routing				varchar(20),
			@o_terms_code			varchar(10),
			@o_sold_to				varchar(10),	
			@o_sch_ship_date		datetime,
			@o_req_ship_date		datetime, -- v1.4
			@o_note					varchar(255),
			@o_special_instr		varchar(255),
			@o_free_shipping		varchar(30), -- v1.5
			@status					char(1),
			@SQL					varchar(5000)

	-- Initialize
	SET	@ret = 0
	SET @message = ''
	SET @has_update = 0
			
	-- Validation
	-- Get the original values from the order
	SELECT	@o_freight_allow_type = ISNULL(freight_allow_type,''),
			@o_attention = ISNULL(attention,''),
			@o_phone = ISNULL(phone,''),
			@o_cust_po = ISNULL(cust_po,''),
			@o_user_category = ISNULL(user_category,''),			
			@o_so_priority_code = ISNULL(so_priority_code,''),
			@o_routing = ISNULL(routing,''),
			@o_terms_code = ISNULL(terms,''),
			@o_sold_to = ISNULL(sold_to,''),
			@o_sch_ship_date = sch_ship_date,
			@o_note	= ISNULL(note,''),
			@o_special_instr = ISNULL(special_instr,''),
			@status = status,
			@o_req_ship_date = req_ship_date -- v1.4
	FROM	orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext

	-- v1.5 Start
	SELECT	@o_free_shipping = ISNULL(free_shipping,'N')
	FROM	cvo_orders_all (NOLOCK)
	WHERE	order_no = @order_no
	AND		ext = @order_ext
	-- v1.5 End

	-- Check if the order has been packed and if so has it been freighted or masterpacked
	-- Fail validation only if relevant fields have been changed
	IF (@o_freight_allow_type <> @freight_allow_type OR @o_routing <> @routing OR @o_sold_to <> @sold_to OR @o_free_shipping <> @free_shipping) -- v1.5
	BEGIN
		IF EXISTS (SELECT 1 FROM tdc_carton_tx (NOLOCK) WHERE order_no = @order_no AND order_ext = @order_ext
					AND	order_type = 'S' AND status NOT IN ('O','C'))
		BEGIN
			SET @ret = -1
			SET @message = 'Order information cannot be changed (freight type, carrier, global ship to, free shipping). Carton has been freighted/staged.' -- v1.5
			SELECT	@ret, @message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM tdc_master_pack_ctn_tbl a JOIN tdc_carton_tx b ON a.carton_no = b.carton_no
					WHERE b.order_no = @order_no AND b.order_ext = @order_ext)
		BEGIN
			SET @ret = -1
			SET @message = 'Order information cannot be changed (freight type, carrier, global ship to, free shipping). Carton has been masterpacked.' -- v1.5
			SELECT	@ret, @message
			RETURN
		END
	END

	-- Check if the order has been ship confirmed (status = R)
	-- Fail validation only if relevant fields have been changed
	IF (@o_attention <> @attention OR @o_phone <> @phone OR @o_cust_po <> @cust_po OR @o_user_category <> @user_category
			OR @o_so_priority_code <> @so_priority_code OR @o_terms_code <> @terms_code OR @o_sch_ship_date <> @sch_ship_date)
	BEGIN
		IF (@status >= 'R') 
		BEGIN
			SET @ret = -1
			SET @message = 'Order information cannot be changed (contact, phone#, cust po, user category, SO priority, terms, sch ship date). ' + char(10) + char(13) + 
							'Order has been ship confirmed.'
			SELECT	@ret, @message
			RETURN
		END
	END


	-- Validation passed
	-- Update the order
	-- Build the sql string to execute so we only update the fields that have changed
	SET @SQL = "UPDATE orders_all SET "
	IF (@o_freight_allow_type <> @freight_allow_type)
	BEGIN
		SET @SQL = @SQL + "freight_allow_type = '" + @freight_allow_type + "',"
		SET @has_update = 1
	END
	IF (@o_routing <> @routing)
	BEGIN
		SET @SQL = @SQL + "routing = '" + @routing + "',"
		SET @has_update = 1
	END
	IF (@o_sold_to <> @sold_to)
	BEGIN
		SET @SQL = @SQL + "sold_to = '" + @sold_to + "',"
		SET @has_update = 1
	END
	IF (@o_attention <> @attention)
	BEGIN
		SET @SQL = @SQL + "attention = '" + REPLACE(@attention,"'","''") + "'," -- v1.2
		SET @has_update = 1
	END
	IF (@o_phone <> @phone)
	BEGIN
		SET @SQL = @SQL + "phone = '" + @phone + "',"
		SET @has_update = 1
	END
	IF (@o_cust_po <> @cust_po)
	BEGIN
		SET @SQL = @SQL + "cust_po = '" + REPLACE(@cust_po,"'","''") + "'," -- v1.2
		SET @has_update = 1
	END
	IF (@o_user_category <> @user_category)
	BEGIN
		SET @SQL = @SQL + "user_category = '" + @user_category + "',"
		SET @has_update = 1
	END
	IF (@o_so_priority_code <> @so_priority_code)
	BEGIN
		SET @SQL = @SQL + "so_priority_code = '" + @so_priority_code + "',"
		SET @has_update = 1
	END
	-- START v1.1
	/*
	IF (@o_routing <> @routing)
	BEGIN
		SET @SQL = @SQL + "routing = '" + @routing + "',"
		SET @has_update = 1
	END
	*/
	-- END v1.1
	IF (@o_terms_code <> @terms_code)
	BEGIN
		SET @SQL = @SQL + "terms = '" + @terms_code + "',"
		SET @has_update = 1
	END
	-- START v1.1
	/*
	IF (@o_sold_to <> @sold_to)
	BEGIN
		SET @SQL = @SQL + "sold_to = '" + @sold_to + "',"
		SET @has_update = 1
	END
	*/
	-- END v1.1
	IF (@o_sch_ship_date <> @sch_ship_date)
	BEGIN
		SET @SQL = @SQL + "sch_ship_date = '" + CONVERT(varchar(10),@sch_ship_date,120) + "',"
		SET @has_update = 1
	END
	-- v1.4 Start
	IF (@o_req_ship_date <> @delivery_date)
	BEGIN
		SET @SQL = @SQL + "req_ship_date = '" + CONVERT(varchar(10),@delivery_date,120) + "',"
		SET @has_update = 1
	END
	-- v1.4 End
	IF (@o_note <> @note)
	BEGIN
		SET @SQL = @SQL + "note = '" + @note + "',"
		SET @has_update = 1
	END
	IF (@o_special_instr <> @special_instr)
	BEGIN
		SET @SQL = @SQL + "special_instr = '" + @special_instr + "',"
		SET @has_update = 1
	END

	-- Has anything been updated
	IF (@has_update = 1)
	BEGIN
		-- Need to remove the final comma
		SET @SQL = LEFT(@SQL,(LEN(@SQL)-1))

		SET @SQL = @SQL + " WHERE order_no = " + CAST(@order_no AS varchar(10)) + " AND ext = " + CAST(@order_ext AS varchar(5))

--		SELECT @SQL

		EXEC (@SQL)

		IF (@@ERROR <> 0)
		BEGIN
			SET @ret = -1
			SET @message = 'An error has occurred updating the order information, update failed'
			SELECT	@ret, @message
			RETURN
		END
	END

	-- v1.5 Start
	IF (@o_free_shipping <> @free_shipping)
	BEGIN
		UPDATE	cvo_orders_all
		SET		free_shipping = @free_shipping
		WHERE	order_no = @order_no
		AND		ext = @order_ext

		EXEC CVO_GetFreight_recalculate_sp @order_no, @order_ext, 0
			
		EXEC dbo.fs_updordtots @order_no, @order_ext		

	END
	-- v1.5 End

	-- START v1.3
	IF @o_routing <> @routing
	BEGIN
		UPDATE
			dbo.tdc_carton_tx 
		SET 
			carrier_code = @routing
		WHERE 
			order_no = @order_no 
			AND order_ext = @order_ext
			AND	order_type = 'S' 
			AND [status] IN ('O','C')
	END
	-- END v1.3

	-- Deal with the line notes
	IF EXISTS (SELECT 1 FROM #cvo_order_update_temp)
	BEGIN
		-- Mark any lines that have changed
		UPDATE	a
		SET		changed = 1
		FROM	#cvo_order_update_temp a
		JOIN	ord_list (NOLOCK) b
		ON		a.order_no = b.order_no
		AND		a.order_ext = b.order_ext
		AND		a.line_no = b.line_no
		WHERE	ISNULL(a.notes,'') <> ISNULL(b.note,'')

		IF EXISTS (SELECT 1 FROM #cvo_order_update_temp WHERE changed = 1)
		BEGIN
			UPDATE	a
			SET		note = ISNULL(b.notes,'')
			FROM	ord_list (NOLOCK) a
			JOIN	#cvo_order_update_temp b
			ON		a.order_no = b.order_no
			AND		a.order_ext = b.order_ext
			AND		a.line_no = b.line_no
			WHERE	b.changed = 1

			IF (@@ERROR <> 0)
			BEGIN
				SET @ret = -1
				SET @message = 'An error has occurred updating the order detail information, update failed'
				SELECT	@ret, @message
				RETURN
			END
		END
	END

	IF OBJECT_ID('tempdb..#cvo_order_update_temp') IS NOT NULL
		DROP TABLE #cvo_order_update_temp

	-- return 
	SELECT	@ret, @message
	RETURN
 
END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_order_info_sp] TO [public]
GO
