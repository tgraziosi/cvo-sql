SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_setup_outsourcing_sp]	@SetOn		char(1),
											@part_no	varchar(30),
											@user		varchar(50),											
											@raw_vendor	varchar(10) = NULL,
											@raw_cost	decimal(20,8) = NULL,
											@make_cost	decimal(20,8) = NULL
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@result			int,
			@ret_message	varchar(100),
			@test_part_no	varchar(30),
			@test_part_no2	varchar(30),
			@void			char(1),
			@make_vendor	varchar(10),
			@upc_num		varchar(12),
			@description	varchar(255),
			@new_description varchar(255),
			@identity		int,
			@raw_curr		varchar(8), -- v1.3
			@make_curr		varchar(8) -- v1.3

	-- PROCESSING
	
	-- Outsourcing switched off
	IF (@SetOn = 'N')
	BEGIN
		-- Validate the MAKE part
		SET @test_part_no = @part_no + '-MAKE'
		IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as stock exists for the MAKE part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM pur_list (NOLOCK) WHERE part_no = @test_part_no AND status = 'O' AND void = 'N')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open purchase orders for the MAKE part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM xfer_list (NOLOCK) WHERE part_no = @test_part_no AND status < 'S')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open transfers for the MAKE part!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- Validate the RAW part
		SET @test_part_no = @part_no + '-RAW'
		IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as stock exists for the RAW part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM pur_list (NOLOCK) WHERE part_no = @test_part_no AND status = 'O' AND void = 'N')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open purchase orders for the RAW part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM xfer_list (NOLOCK) WHERE part_no = @test_part_no AND status < 'S')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open transfers for the RAW part!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- Validate the FG part
		SET @test_part_no = @part_no + '-FG'
		IF EXISTS (SELECT 1 FROM lot_bin_stock (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as stock exists for the FG part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM pur_list (NOLOCK) WHERE part_no = @test_part_no AND status = 'O' AND void = 'N')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open purchase orders for the FG part!'
			SELECT	@result, @ret_message
			RETURN
		END
		IF EXISTS (SELECT 1 FROM xfer_list (NOLOCK) WHERE part_no = @test_part_no AND status < 'S')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Cannot remove the outsource option as there are open transfers for the FG part!'
			SELECT	@result, @ret_message
			RETURN
		END

		BEGIN TRAN
		
		-- Remove the Item Agents
		SET @test_part_no = @part_no + '-MAKE'
		IF EXISTS(SELECT 1 FROM agents (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			DELETE	agents
			WHERE	part_no = @test_part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error removing agents for MAKE process!'
				SELECT	@result, @ret_message
				RETURN
			END
		END		

		-- Set MAKE & RAW as void
		SET @test_part_no = @part_no + '-MAKE'
		UPDATE	inv_master
		SET		void = 'V',
				void_who = 'Outsourcing',
				void_date = GETDATE()
		WHERE	part_no = @test_part_no

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error voiding MAKE part!'
			SELECT	@result, @ret_message
			RETURN
		END

		SET @test_part_no = @part_no + '-RAW'
		UPDATE	inv_master
		SET		void = 'V',
				void_who = 'Outsourcing',
				void_date = GETDATE()
		WHERE	part_no = @test_part_no

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error voiding RAW part!'
			SELECT	@result, @ret_message
			RETURN
		END

		SET @test_part_no = @part_no + '-FG'
		UPDATE	inv_master
		SET		void = 'V',
				void_who = 'Outsourcing',
				void_date = GETDATE()
		WHERE	part_no = @test_part_no

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error voiding FG part!'
			SELECT	@result, @ret_message
			RETURN
		END

		COMMIT TRAN

		SET @result = 0
		SET	@ret_message = ''
		SELECT @result, @ret_message
		RETURN
	END

	-- Outsourcing switched On
	IF (@SetOn = 'Y')
	BEGIN

		SELECT	@make_vendor = ISNULL(vendor,''),
				@void = void,
				@description = description
		FROM	inv_master (NOLOCK)
		WHERE	part_no = @part_no

		-- Validate vendor
		IF (@make_vendor = '')
		BEGIN
			SET @result = -1
			SET @ret_message = 'Vendor not set!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- v1.3 Start
		SELECT	@raw_curr = nat_cur_code
		FROM	adm_vend (NOLOCK)
		WHERE	vendor_code = @raw_vendor

		SELECT	@make_curr = nat_cur_code
		FROM	adm_vend (NOLOCK)
		WHERE	vendor_code = @make_vendor
		-- v1.3 End

		-- Validate that a primary bin exists for the finished goods
--		IF NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = '001' AND part_no = @part_no AND [primary] = 'Y')
--		BEGIN
--			SET @result = -1
--			SET @ret_message = 'Primary bin not set for this part!'
--			SELECT	@result, @ret_message
--			RETURN
--		END

		BEGIN TRAN

		-- Check Locations and create
		IF NOT EXISTS (SELECT 1 FROM locations_all (NOLOCK) WHERE location = @make_vendor)
		BEGIN
			INSERT	locations_all (location, name, note, void, void_who, addr1, addr2, addr3, addr4, addr5, addr_sort1, addr_sort2, addr_sort3, phone, 
										contact_name, consign_customer_code, consign_vendor_code, aracct_code, zone_code, location_type, apacct_code, 
										dflt_recv_bin, country_code, harbour, bundesland, department, organization_id, city, state, zip) 
			SELECT	vendor_code, vendor_name, 'Create by outsourcing', 'N', '', addr1, addr2, addr3, addr4, addr5, addr_sort1, addr_sort2, addr_sort3, contact_phone,
					contact_name, '', '', 'OTHER', '', 0, 'OTHER', '', country_code, '', '', '', 'CVO', city, state, postal_code
			FROM	apvend (NOLOCK)
			WHERE	vendor_code = @make_vendor

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating location for MAKE vendor!'
				SELECT	@result, @ret_message
				RETURN
			END
		END

		-- Create bin at vendor location
		IF NOT EXISTS(SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @make_vendor AND bin_no = 'OUTBIN')
		BEGIN
			INSERT tdc_bin_master (location, bin_no, company_no, warehouse_no, description, usage_type_code, size_group_code, cost_group_code, group_code,
							group_code_id, seq_no, sort_method, relative_point_x, relative_point_y, relative_point_z, status, reference, last_modified_date,
							modified_by, bm_udef_a, bm_udef_b, bm_udef_c, bm_udef_d, bm_udef_e, maximum_level)
			VALUES (@make_vendor, 'OUTBIN', '', '', 'OUTSOURCE BIN', 'OPEN', 'STD', 'STD', 'PICKAREA', '', 0, 'A', 0, 0, 0, 'A', '', GETDATE(), 'Outsourcing',
					'', '', '', '', '', 0)
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = @make_vendor AND bin_no = 'OUTBIN' AND status <> 'A')
			BEGIN
				UPDATE	tdc_bin_master
				SET		status = 'A'
				WHERE	location = @make_vendor
				AND		bin_no = 'OUTBIN'
			END
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error creating OUTBIN for MAKE vendor location!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- Create bin at 001 location for WIP
		IF NOT EXISTS(SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = '001' AND bin_no = 'FRAMEWIP')
		BEGIN
			INSERT tdc_bin_master (location, bin_no, company_no, warehouse_no, description, usage_type_code, size_group_code, cost_group_code, group_code,
							group_code_id, seq_no, sort_method, relative_point_x, relative_point_y, relative_point_z, status, reference, last_modified_date,
							modified_by, bm_udef_a, bm_udef_b, bm_udef_c, bm_udef_d, bm_udef_e, maximum_level)
			VALUES ('001', 'FRAMEWIP', '', '', 'OUTSOURCE BIN', 'OPEN', 'STD', 'STD', 'PICKAREA', '', 0, 'A', 0, 0, 0, 'A', '', GETDATE(), 'Outsourcing',
					'', '', '', '', '', 0)
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT 1 FROM tdc_bin_master (NOLOCK) WHERE location = '001' AND bin_no = 'FRAMEWIP' AND status <> 'A')
			BEGIN
				UPDATE	tdc_bin_master
				SET		status = 'A'
				WHERE	location = '001'
				AND		bin_no = 'FRAMEWIP'
			END
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error creating FRAMEWIP for 001 location!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- Set primary bins
		SET @test_part_no = @part_no + '-MAKE'
		IF NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = @make_vendor AND part_no = @test_part_no AND [primary] = 'Y')
		BEGIN
			INSERT	tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
			VALUES (@make_vendor, @test_part_no, 'OUTBIN', 999, 'Y', 0)
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error setting primary bin for MAKE part at vendor location!'
			SELECT	@result, @ret_message
			RETURN
		END

		SET @test_part_no = @part_no + '-RAW'
		IF NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = @make_vendor AND part_no = @test_part_no AND [primary] = 'Y')
		BEGIN
			INSERT	tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
			VALUES (@make_vendor, @test_part_no, 'OUTBIN', 999, 'Y', 0)
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error setting primary bin for RAW part at vendor location!'
			SELECT	@result, @ret_message
			RETURN
		END

		SET @test_part_no = @part_no + '-RAW'
		IF NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = '001' AND part_no = @test_part_no AND [primary] = 'Y')
		BEGIN
			INSERT	tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
			VALUES ('001', @test_part_no, 'FRAMEWIP', 999, 'Y', 0)
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error setting primary bin for RAW part at 001 location!'
			SELECT	@result, @ret_message
			RETURN
		END

		SET @test_part_no = @part_no + '-FG'
		IF NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty (NOLOCK) WHERE location = '001' AND part_no = @test_part_no AND [primary] = 'Y')
		BEGIN
			INSERT	tdc_bin_part_qty (location, part_no, bin_no, qty, [primary], seq_no)
			VALUES ('001', @test_part_no, 'FRAMEWIP', 999, 'Y', 0)
		END

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error setting primary bin for FG part at 001 location!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- Check for inventory location on complete frame for make vendor
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @part_no AND location = @make_vendor)
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	@make_vendor, @part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', 0, 0, 0, 0, 0, acct_code, 
					0, 0, 0, 0, 0, 0, GETDATE(), 'M', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for MAKE location!'
				SELECT	@result, @ret_message
				RETURN
			END
		END

		-- Check for RAW part
		SET @test_part_no = @part_no + '-RAW'
		IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			-- v1.4 IF (@void = 'V')
			IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no AND void = 'V') -- v1.4
			BEGIN
				UPDATE	inv_master
				SET		void = 'N',
						void_who = NULL,
						void_date = NULL,
						vendor = @raw_vendor -- v1.4
				WHERE	part_no = @test_part_no

				-- v1.4 Start
				UPDATE	inv_list
				SET		std_cost = @raw_cost
				WHERE	location = @make_vendor
				AND		part_no = @test_part_no

				UPDATE	inv_list
				SET		std_cost = @raw_cost
				WHERE	location = '001'
				AND		part_no = @test_part_no

				IF NOT EXISTS (SELECT 1 FROM vendor_sku WHERE vendor_no = @raw_vendor AND sku_no = @test_part_no)
				BEGIN
					EXEC cvo_CreateVendorQuote_sp @item_no = @test_part_no, @currency = @raw_curr, @cost = @raw_cost, @suppress = 1 
				END
				ELSE
				BEGIN
					UPDATE	vendor_sku
					SET		last_price = @raw_cost
					WHERE	vendor_no = @raw_vendor
					AND		sku_no = @test_part_no
				END
				-- v1.4 End

			END
		END
		ELSE
		BEGIN
			-- Create new inventory item

			SET @upc_num = NULL
			EXEC dbo.f_generate_upc_12_sp @upc_num OUTPUT
			IF (ISNULL(@upc_num,'') = '')
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating UPC for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT INTO inv_master_add (part_no, category_3, field_18, field_22, field_26, field_27, field_30, field_18_a, field_18_b, field_18_c, field_18_d, field_18_e ) 
			VALUES (@test_part_no, '', 'N', 'N', CONVERT(datetime,CONVERT(varchar(10), GETDATE(),121)), 'N', 'N', 'N', 'N', 'N', 'N', 'N')

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory additional info for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	inv_master (part_no, upc_code, description, vendor, category, type_code, status, cubic_feet, weight_ea, labor, uom, account, comm_type, void, 
								entered_who, entered_date, std_cost, utility_cost, qc_flag, lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
								buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
								min_profit_perc, height, width, length, eprocurement_flag, non_sellable_flag, so_qty_increment) 
			SELECT	@test_part_no, @upc_num, description + ' - RAW', @raw_vendor, category, 'OTHER', 'P', cubic_feet, weight_ea, labor, uom, account, comm_type, 'N',
					@user, GETDATE(), std_cost, utility_cost, 'N', lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
					buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
					min_profit_perc, height, width, length, eprocurement_flag, non_sellable_flag, so_qty_increment
			FROM	inv_master (NOLOCK)
			WHERE	part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory part RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

			SET @new_description = @description + ' - RAW'
			EXEC dbo.scm_pb_set_dw_uom_id_code_sp 'I',@test_part_no,'EA',@upc_num,NULL,NULL,NULL,NULL,@new_description,NULL,NULL

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating uom code part RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price (part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind)
			SELECT	@test_part_no, 0, '', 1, 'N', 0, NULL, NULL, NULL, 1

			SELECT @identity = @@IDENTITY

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price_det (inv_price_id, p_level, price, qty)
			SELECT	@identity, 1, 0, 0

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing detail for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

		END

		-- Check for inventory location on the RAW frame for make vendor
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @test_part_no AND location = @make_vendor)
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	@make_vendor, @test_part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', @raw_cost, 0, 0, 0, 0, acct_code, -- v1.1
					0, 0, 0, 0, 0, 0, GETDATE(), 'P', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END
		END

		-- Check for inventory location on the RAW frame for 001
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @test_part_no AND location = '001')
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	location, @test_part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', @raw_cost, 0, 0, 0, 0, acct_code, -- v1.0
					0, 0, 0, 0, 0, 0, GETDATE(), 'P', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for RAW part!'
				SELECT	@result, @ret_message
				RETURN
			END

		END

		EXEC cvo_CreateVendorQuote_sp @item_no = @test_part_no, @currency = @raw_curr, @cost = @raw_cost, @suppress = 1 -- v1.3

		-- Check for MAKE part
		SET @test_part_no = @part_no + '-MAKE'
		IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			-- v1.4 IF (@void = 'V')
			IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no AND void = 'V') -- v1.4
			BEGIN
				UPDATE	inv_master
				SET		void = 'N',
						void_who = NULL,
						void_date = NULL
				WHERE	part_no = @test_part_no
			END
		END
		ELSE
		BEGIN
			-- Create new inventory item

			SET @upc_num = NULL
			EXEC dbo.f_generate_upc_12_sp @upc_num OUTPUT
			IF (ISNULL(@upc_num,'') = '')
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating UPC for MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT INTO inv_master_add (part_no, category_3, field_18, field_22, field_27, field_30, field_18_a, field_18_b, field_18_c, field_18_d, field_18_e ) 
			VALUES (@test_part_no, '', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N')

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory additional info for MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	inv_master (part_no, upc_code, description, vendor, category, type_code, status, cubic_feet, weight_ea, labor, uom, account, comm_type, void, 
								entered_who, entered_date, std_cost, utility_cost, qc_flag, lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
								buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
								min_profit_perc, height, width, length, eprocurement_flag, non_sellable_flag, so_qty_increment) 
			SELECT	@test_part_no, @upc_num, description + ' - MAKE', @make_vendor, category, 'OUT', 'Q', cubic_feet, weight_ea, labor, uom, account, comm_type, 'N',
					@user, GETDATE(), std_cost, utility_cost, 'N', lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
					buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
					min_profit_perc, height, width, length, eprocurement_flag, non_sellable_flag, so_qty_increment
			FROM	inv_master (NOLOCK)
			WHERE	part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory part MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			SET @new_description = @description + ' - MAKE'
			EXEC dbo.scm_pb_set_dw_uom_id_code_sp 'I',@test_part_no,'EA',@upc_num,NULL,NULL,NULL,NULL,@new_description,NULL,NULL

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating uom code part MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price (part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind)
			SELECT	@test_part_no, 0, '', 1, 'N', 0, NULL, NULL, NULL, 1

			SELECT @identity = @@IDENTITY

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing for MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price_det (inv_price_id, p_level, price, qty)
			SELECT	@identity, 1, 0, 0

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing detail for MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

			EXEC cvo_CreateVendorQuote_sp @item_no = @test_part_no, @currency = @make_curr, @cost = @make_cost, @suppress = 1 -- v1.3

		END

		-- Check for inventory location on the MAKE frame for make vendor
		SET @test_part_no = @part_no + '-MAKE'
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @test_part_no AND location = @make_vendor)
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	@make_vendor, @test_part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', @make_cost, 0, 0, 0, 0, acct_code, -- v1.1
					0, 0, 0, 0, 0, 0, GETDATE(), 'Q', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for MAKE part!'
				SELECT	@result, @ret_message
				RETURN
			END

		END			 

		-- Check for FG part
		SET @test_part_no = @part_no + '-FG'
		IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			-- v1.4 IF (@void = 'V')
			IF EXISTS (SELECT 1 FROM inv_master (NOLOCK) WHERE part_no = @test_part_no AND void = 'V') -- v1.4
			BEGIN
				UPDATE	inv_master
				SET		void = 'N',
						void_who = NULL,
						void_date = NULL
				WHERE	part_no = @test_part_no

				-- v1.4 Start
				IF NOT EXISTS (SELECT 1 FROM vendor_sku WHERE vendor_no = @make_vendor AND sku_no = @test_part_no)
				BEGIN
					EXEC cvo_CreateVendorQuote_sp @item_no = @test_part_no, @currency = @raw_curr, @cost = @make_cost, @suppress = 1 
				END
				ELSE
				BEGIN
					UPDATE	vendor_sku
					SET		last_price = @make_cost
					WHERE	vendor_no = @make_vendor
					AND		sku_no = @test_part_no
				END	
				-- v1.4 End			

			END
		END
		ELSE
		BEGIN
			-- Create new inventory item

			SET @upc_num = NULL
			EXEC dbo.f_generate_upc_12_sp @upc_num OUTPUT
			IF (ISNULL(@upc_num,'') = '')
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating UPC for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT INTO inv_master_add (part_no, category_3, field_18, field_22, field_27, field_30, field_18_a, field_18_b, field_18_c, field_18_d, field_18_e ) 
			VALUES (@test_part_no, '', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N', 'N')

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory additional info for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	inv_master (part_no, upc_code, description, vendor, category, type_code, status, cubic_feet, weight_ea, labor, uom, account, comm_type, void, 
								entered_who, entered_date, std_cost, utility_cost, qc_flag, lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
								buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
								min_profit_perc, height, width, length, eprocurement_flag, non_sellable_flag, so_qty_increment) 
			SELECT	@test_part_no, @upc_num, description + ' - FG', @make_vendor, category, 'OUT', 'P', cubic_feet, weight_ea, labor, uom, account, comm_type, 'N',
					@user, GETDATE(), std_cost, utility_cost, 'N', lb_tracking, rpt_uom, freight_unit, taxable, conv_factor, cycle_type, inv_cost_method, 
					buyer, allow_fractions, cfg_flag, tax_code, obsolete, serial_flag, web_saleable_flag, tolerance_cd, reg_prod, pur_prod_flag, country_code, cmdty_code, 
					min_profit_perc, height, width, length, eprocurement_flag, 'Y', so_qty_increment
			FROM	inv_master (NOLOCK)
			WHERE	part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory part FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			SET @new_description = @description + ' - FG'
			EXEC dbo.scm_pb_set_dw_uom_id_code_sp 'I',@test_part_no,'EA',@upc_num,NULL,NULL,NULL,NULL,@new_description,NULL,NULL

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating uom code part FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price (part_no, org_level, loc_org_id, catalog_id, promo_type, promo_rate, promo_date_expires, promo_date_entered, promo_start_date, active_ind)
			SELECT	@test_part_no, 0, '', 1, 'N', 0, NULL, NULL, NULL, 1

			SELECT @identity = @@IDENTITY

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			INSERT	adm_inv_price_det (inv_price_id, p_level, price, qty)
			SELECT	@identity, 1, 0, 0

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating pricing detail for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

			SET @test_part_no = @part_no + '-RAW'
			SET @test_part_no2 = @part_no + '-FG'
			INSERT	what_part (asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
								note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty ) 
			VALUES (@test_part_no2, @test_part_no, 'EA', @user, '100', 1, 'A', 'N', CONVERT(datetime,CONVERT(varchar(10), GETDATE(),121)), GETDATE(), 1, 'N', 'N', 1, '', 
					'', '', '', 0, 0, 0, 'ALL', 1 )

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating build plan for part(RAW)!'
				SELECT	@result, @ret_message
				RETURN
			END

			SET @test_part_no = @part_no + '-MAKE'
			INSERT	what_part (asm_no, part_no, uom, who_entered, seq_no, attrib, active, bench_stock, eff_date, date_entered, conv_factor, constrain, fixed, qty, alt_seq_no, 
								note2, note3, note4, plan_pcs, lag_qty, cost_pct, location, pool_qty ) 
			VALUES (@test_part_no2, @test_part_no, 'EA', @user, '101', 1, 'A', 'N', CONVERT(datetime,CONVERT(varchar(10), GETDATE(),121)), GETDATE(), 1, 'N', 'N', 1, '', 
					'', '', '', 0, 0, 0, 'ALL', 1 )

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating build plan for part(MAKE)!'
				SELECT	@result, @ret_message
				RETURN
			END

			EXEC cvo_CreateVendorQuote_sp @item_no = @test_part_no2, @currency = @make_curr, @cost = 0, @suppress = 1 -- v1.3

		END

		-- Check for inventory location on the FG frame for 001
		SET @test_part_no = @part_no + '-FG'
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @test_part_no AND location = '001')
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	'001', @test_part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', 0, 0, 0, 0, 0, acct_code, 
					0, 0, 0, 0, 0, 0, GETDATE(), 'P', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END
		END

		-- Check for inventory location on the FG frame for make vendor
		SET @test_part_no = @part_no + '-FG'
		IF NOT EXISTS(SELECT 1 FROM inv_list (NOLOCK) WHERE part_no = @test_part_no AND location = @make_vendor)
		BEGIN
			INSERT	inv_list (location, part_no, bin_no, avg_cost, in_stock, min_stock, min_order, lead_time, labor, issued_mtd, issued_ytd, 
								hold_qty, qty_year_end, qty_month_end, qty_physical, entered_who, entered_date, void, std_cost, max_stock, setup_labor, 
								freight_unit, std_labor, acct_code, std_direct_dolrs, std_ovhd_dolrs, std_util_dolrs, avg_direct_dolrs, avg_ovhd_dolrs, avg_util_dolrs, 
								cycle_date, status, eoq, dock_to_stock, order_multiple, rank_class, po_uom, so_uom ) 
			SELECT	@make_vendor, @test_part_no, 'N/A', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, @user, GETDATE(), 'N', 0, 0, 0, 0, 0, acct_code, 
					0, 0, 0, 0, 0, 0, GETDATE(), 'P', 0, 0, 0, rank_class, po_uom, so_uom
			FROM	inv_list (NOLOCK)
			WHERE	location = '001'
			AND		part_no = @part_no

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating inventory location for FG part!'
				SELECT	@result, @ret_message
				RETURN
			END

		END			 

		-- Create the agents entry
		SET @test_part_no = @part_no + '-MAKE'
		SET @test_part_no2 = @part_no + '-FG'
		IF NOT EXISTS(SELECT 1 FROM agents (NOLOCK) WHERE part_no = @test_part_no)
		BEGIN
			INSERT	agents (part_no, agent_type, seq_no, agent_verb, agent_obj)
			VALUES (@test_part_no, 'B', 10, 'OUTSOURCE', @test_part_no2)
			INSERT	agents (part_no, agent_type, seq_no, agent_verb, agent_obj)
			VALUES (@test_part_no, 'R', 10, 'PRODUCE', @test_part_no2)
			INSERT	agents (part_no, agent_type, seq_no, agent_verb, agent_obj)
			VALUES (@test_part_no, 'R', 20, 'XFER', @test_part_no2)

			IF (@@ERROR <> 0)
			BEGIN
				IF (@@TRANCOUNT > 0)
					ROLLBACK TRAN

				SET @result = -1
				SET @ret_message = 'Error creating agents for MAKE process!'
				SELECT	@result, @ret_message
				RETURN
			END
		END

		-- Update the cost of the completed frame
		UPDATE	inv_list
		SET		std_cost = (ISNULL(@raw_cost,0) + ISNULL(@make_cost,0))
		WHERE	part_no = @part_no
		AND		location IN ('001',@make_vendor) -- v1.2

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error update standard cost!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- v1.2 Start
		UPDATE	inv_list
		SET		std_cost = (ISNULL(@raw_cost,0) + ISNULL(@make_cost,0))
		WHERE	part_no = @test_part_no2
		AND		location IN ('001',@make_vendor) 

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error update FG standard cost!'
			SELECT	@result, @ret_message
			RETURN
		END

		UPDATE	inv_recv
		SET		cost = (ISNULL(@raw_cost,0) + ISNULL(@make_cost,0))
		WHERE	part_no = @part_no
		AND		location IN ('001',@make_vendor)

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error update recv standard cost!'
			SELECT	@result, @ret_message
			RETURN
		END

		UPDATE	inv_recv
		SET		cost = (ISNULL(@raw_cost,0) + ISNULL(@make_cost,0))
		WHERE	part_no = @test_part_no2
		AND		location IN ('001',@make_vendor) 

		IF (@@ERROR <> 0)
		BEGIN
			IF (@@TRANCOUNT > 0)
				ROLLBACK TRAN

			SET @result = -1
			SET @ret_message = 'Error update FG recv standard cost!'
			SELECT	@result, @ret_message
			RETURN
		END

		-- v1.2

		SET @result = 0
		SET @ret_message = ''
		SELECT	@result, @ret_message

		COMMIT TRAN

	END

END
GO
GRANT EXECUTE ON  [dbo].[cvo_setup_outsourcing_sp] TO [public]
GO
