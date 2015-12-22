SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.3 CT 09/05/2013 - Issue #1260 - Reset variables to stop missing queue trans picking up info from previous line

CREATE PROCEDURE [dbo].[CVO_disassembled_inv_adjust_sp]
	    @order_no	INT
       ,@order_ext	INT          
AS


BEGIN
	--DECLARE @order_no		INT		   ,@order_ext		INT  
	--SET @order_no = 293
	--SET @order_ext = 0	        
	DECLARE @location		VARCHAR (10)
		   ,@line_no		INT
		   ,@part_no		VARCHAR (30)
		   ,@part_no_to_dis VARCHAR (30) -- frame to disassemble
		   ,@part_no_description VARCHAR (255)
		   ,@qty            DECIMAL(20,2)
		   ,@bin_from       VARCHAR (12)
		   ,@left_bin_from  VARCHAR (12) -- v1.1
		   ,@right_bin_from VARCHAR (12) -- v1.1
		   ,@bin_to         VARCHAR (12)
		   --,@temple_		VARCHAR (30)
		   ,@temple_P		VARCHAR (30)
		   ,@temple_L_base	VARCHAR (30)
		   ,@temple_R_base	VARCHAR (30)
		   ,@screw_base		VARCHAR (30)
		   ,@nosepad_base	VARCHAR (30)
		   ,@front_base     VARCHAR (30)
		   ,@temple_L_new	VARCHAR (30)
		   ,@temple_R_new	VARCHAR (30)		
		   ,@screw_new		VARCHAR (30)
		   ,@nosepad_new	VARCHAR (30)
		   ,@front_new      VARCHAR (30)
		   ,@res_type		VARCHAR (30)
		   ,@temp_part_no	VARCHAR (40)
		   ,@tran_id		INT -- v1.1
		   ,@left_tran_id	INT -- v1.1
		   ,@right_tran_id	INT -- v1.1

	DECLARE @def_frame         VARCHAR (20),
		    @def_part         VARCHAR (20),
	        @def_temple_R      VARCHAR (20),
	        @def_temple_L      VARCHAR (20),
	        @def_screws        VARCHAR (20),
	        @def_nosepad       VARCHAR (20),
	        @def_temple_P      VARCHAR (20),
	        @def_front		   VARCHAR (20)	
		   
	DECLARE @lbl_manually_allocate VARCHAR(100),
	        @lbl_inventory_out     VARCHAR(100),
	        @lbl_inventory_out_plus     VARCHAR(100),
	        @lbl_inventory_place   VARCHAR(100),
	        @lbl_inventory_place_plus   VARCHAR(400),
	        @lbl_inventory_back	   VARCHAR(100),
	        @lbl_replace		   VARCHAR(100),
	        @lbl_with			   VARCHAR(100),
	        @lbl_and               VARCHAR(100),
			@lbl_pick			   VARCHAR(100), -- v1.1
			@lbl_pack			   VARCHAR(100), -- v1.1
			@lbl_final			   VARCHAR(100) -- v1.1
	        
	DECLARE @LP_D1_ORIG_FRAME			VARCHAR(40),
			@LP_D1_ORDER_LINE_NO		VARCHAR(40),
			@LP_D1_ORDER_LINE_QTY		VARCHAR(40),
			@LP_D1_ORIG_FRAME_BIN_FROM	VARCHAR(40),
			@LP_D1_ORIG_FRAME_BIN_TO	VARCHAR(40),
			@LP_D2_FRAME_TO_CUSTOMIZE	VARCHAR(40),--new
			@LP_D2_FRAME_TO_DISASSEMBLE	VARCHAR(40),--new			
			@LP_D2_PART_TO_REPLACE		VARCHAR(40),
			@LP_D2_REPLACEMENT_PART		VARCHAR(40),
			@LP_D3_INSTR				VARCHAR(40),
			@LP_D3_Q_ID					VARCHAR(40) -- v1.1

	DECLARE @LBL_LP_D1_ORIG_FRAME			VARCHAR(40),
			@LBL_LP_D1_ORDER_LINE_NO		VARCHAR(40),
			@LBL_LP_D1_ORDER_LINE_QTY		VARCHAR(40),
			@LBL_LP_D1_ORIG_FRAME_BIN_FROM	VARCHAR(40),
			@LBL_LP_D1_ORIG_FRAME_BIN_TO	VARCHAR(40),
			@LBL_LP_D2_FRAME_TO_CUSTOMIZE	VARCHAR(40),--new
			@LBL_LP_D2_FRAME_TO_DISASSEMBLE	VARCHAR(40),--new									
			@LBL_LP_D2_PART_TO_REPLACE		VARCHAR(40),
			@LBL_LP_D2_REPLACEMENT_PART		VARCHAR(40)

	SET @bin_to = 'CUSTOM'
				        
	--Set Category name
	SET @def_frame    = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRAME')
	SET @def_part     = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_PART')
	SET @def_temple_R = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_TEMPLE_R')
	SET @def_temple_L = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_TEMPLE_L')
	SET @def_screws   = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_SCREW')
	SET @def_nosepad  = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_NOSEPAD')
	SET @def_temple_P = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_TEMPLE_P')
	SET @def_front    = [dbo].[CVO_get_ResType_PartType_fn] ('DEF_RES_TYPE_FRONT')
	
	--Set label text
	SET @lbl_manually_allocate = 'Manually allocate this order from bin ' + @bin_to
	SET @lbl_inventory_out     = 'Perform an Inventory Adjustment to take out of inventory '
	SET @lbl_inventory_place   = 'Perform an Inventory Adjustment to place '
	SET @lbl_inventory_back    = ' back into inventory'
	SET @lbl_replace           = 'Replace Part: '
	SET @lbl_with              = ' With Part: '
	SET @lbl_and               = ' and '	
-- tag 12/4/2012 - update verbiage
--	SET @lbl_pick			   = 'Print Pick Ticket and scan frame for pick using printed pick ticket'
	SET @lbl_pick			   = 'Scan frame for pick using printed pick ticket' -- tag 12/4/2012
	SET @lbl_pack			   = 'Pack and ship as usual'
--	SET @lbl_final			   = 'After picking completed frames, process queue transactions for putting away the replaced parts'
-- tag 12/4/2012
	SET @lbl_final			   = 'After picking completed frames, use the printed putaway ticket to put away the leftover parts'
	

	--Set label name
	SET @LP_D1_ORIG_FRAME			= 'LP_D1_FRAME_'
	SET @LP_D1_ORDER_LINE_NO		= 'LP_D1_LINE_NO_'
	SET @LP_D1_ORDER_LINE_QTY		= 'LP_D1_LINE_QTY_'
	SET @LP_D1_ORIG_FRAME_BIN_FROM	= 'LP_D1_BIN_FROM_'
	SET @LP_D1_ORIG_FRAME_BIN_TO	= 'LP_D1_BIN_TO_'
	SET @LP_D2_FRAME_TO_CUSTOMIZE	= 'LP_D2_FRAME_TO_CUSTOMIZE_'--new
	SET @LP_D2_FRAME_TO_DISASSEMBLE	= 'LP_D2_FRAME_TO_DISASSEMBLE_'--new			
	SET @LP_D2_PART_TO_REPLACE		= 'LP_D2_PART_TO_REPLACE_'
	SET @LP_D2_REPLACEMENT_PART		= 'LP_D2_REPLACEMENT_PART_'
	SET @LP_D3_INSTR				= 'LP_D3_INSTR_'
	SET @LP_D3_Q_ID					= 'LP_D3_Q_ID_'
		   		   
	--Set label text
	SET @LBL_LP_D1_ORIG_FRAME			= ''--'Frame: '
	SET @LBL_LP_D1_ORDER_LINE_NO		= ''--'Line No: '
	SET @LBL_LP_D1_ORDER_LINE_QTY		= ''--'Qty: '
	SET @LBL_LP_D1_ORIG_FRAME_BIN_FROM	= ''--'Bin From: '
	SET @LBL_LP_D1_ORIG_FRAME_BIN_TO	= ''--'Bin To: '
	SET @LBL_LP_D2_FRAME_TO_CUSTOMIZE	= ''--new
	SET @LBL_LP_D2_FRAME_TO_DISASSEMBLE	= ''--new									
	SET @LBL_LP_D2_PART_TO_REPLACE		= ''--'Part to Replace: '
	SET @LBL_LP_D2_REPLACEMENT_PART		= ''--'Replacement Part No: '
	
			   		   
	IF (OBJECT_ID('tempdb..#build_plan')) IS NOT NULL 
		DROP TABLE #build_plan		
		
	CREATE TABLE #build_plan 
	(asm_no		VARCHAR (30)
	,part_no	VARCHAR (30)
	,res_type	VARCHAR (30)
	,part_type	VARCHAR (30) NULL)
			
	IF (OBJECT_ID('tempdb..#sub_parts')) IS NOT NULL 
		DROP TABLE #sub_parts	
				
	CREATE TABLE #sub_parts 
	(line_no	INT
	,part_no	VARCHAR (30)
	,res_type	VARCHAR (30)
	,part_type	VARCHAR (30) NULL)
	
	IF (OBJECT_ID('tempdb..#PrintData_INSTR')) IS NOT NULL 
		DROP TABLE #PrintData_INSTR	
	
	CREATE TABLE #PrintData_INSTR
	(data_field VARCHAR (300) 
	,data_value VARCHAR (300) NULL)
	
	DECLARE @D1Index INT, @D1IndexStr VARCHAR(2),
	        @D2Index INT, @D2IndexStr VARCHAR(2),
	        @D3Index INT, @D3IndexStr VARCHAR(2),
	        @totalD2Lines INT, 
	        @totalD3Lines INT,
	        @totalDetailPage INT
	
	SET @D1Index = 1
	SET @D1IndexStr = CAST(@D1Index AS VARCHAR(2))
	SET @D2Index = 1
	SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))
	SET @D3Index = 1
	SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))	
	SET @lbl_inventory_place_plus = ''
	SET @lbl_inventory_out_plus = ''
	SET @totalD2Lines  = 5
	SET @totalD3Lines  = 12
	SET @totalDetailPage = 2
	
	
	DECLARE values_cur CURSOR FOR  	
							 SELECT   ol.order_no, ol.order_ext, location, ol.line_no, ol.part_no
							 FROM     CVO_ord_list cvo, ord_list ol
							 WHERE    cvo.order_no		= ol.order_no	AND
									  cvo.order_ext		= ol.order_ext	AND
									  cvo.line_no		= ol.line_no	AND 
									  cvo.order_no		= @order_no		AND 
									  cvo.order_ext		= @order_ext	AND 
									  cvo.is_customized = 'S'
									  									  									  	
	OPEN values_cur

		FETCH NEXT FROM values_cur 
		INTO @order_no, @order_ext, @location, @line_no, @part_no

		WHILE @@FETCH_STATUS = 0
		BEGIN

			-- v1.2 Start
			IF OBJECT_ID('tempdb..#line_exclusions') IS NOT NULL
			BEGIN
				IF EXISTS (SELECT 1 FROM #line_exclusions WHERE order_no = @order_no AND order_ext = @order_ext AND line_no = @line_no)
				BEGIN

					FETCH NEXT FROM values_cur 
					INTO @order_no, @order_ext, @location, @line_no, @part_no

					CONTINUE

				END
			END
			-- v1.2 End

			--Part_no build plan
			DELETE FROM #build_plan
			
			INSERT INTO #build_plan (asm_no, part_no, res_type, part_type) 
			SELECT wp.asm_no, wp.part_no, imas.type_code, iadd.category_3
			FROM   what_part  wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
			WHERE  wp.part_no = imas.part_no AND
				   wp.part_no = iadd.part_no AND 				   
				   wp.asm_no  = @part_no				   
				   
			SELECT @qty = ordered,
			       @part_no_description = ISNULL(description,'')
			FROM   ord_list (NOLOCK)
			WHERE  order_no  = @order_no  AND
			       order_ext = @order_ext AND
			       line_no   = @line_no
			
			--alloc qty to 100% then avail qty = 0
			--disassemble frame for more qty and then wont be avail bin no to B2B
			SET @bin_from    = 'no available bin'
			SET	@tran_id = 0 -- v1.2
			       
--			SELECT @bin_from = bin_from
--			FROM   CVO_disassembled_frame_B2B_history_tbl (NOLOCK)
--			WHERE  order_no = @order_no    AND
--			       order_ext = @order_ext AND
--			       location = @location  AND
--			       line_no  = @line_no AND
--			       part_no = @part_no			
			SELECT @bin_from = bin_no,
				   @tran_id = tran_id
			FROM   tdc_pick_queue (NOLOCK)
			WHERE  trans_type_no = @order_no    AND
			       trans_type_ext = @order_ext AND
			       location = @location  AND
			       line_no  = @line_no AND
			       part_no = @part_no AND
				   trans = 'MGTB2B'			
			       			
			--SELECT * FROM #build_plan
			
			DELETE FROM #sub_parts
			
			INSERT INTO #sub_parts (line_no, part_no, res_type, part_type)
			SELECT		olk.line_no, olk.part_no, imas.type_code, iadd.category_3
			FROM		cvo_ord_list_kit cvo (NOLOCK), ord_list_kit olk (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
			WHERE		cvo.order_no	= olk.order_no	AND
						cvo.order_ext	= olk.order_ext AND
						cvo.location	= olk.location	AND
						cvo.line_no		= olk.line_no	AND
						cvo.part_no		= olk.part_no	AND	
						cvo.part_no		= imas.part_no	AND							  
						cvo.part_no		= iadd.part_no	AND							  						
						cvo.order_no	= @order_no		AND
						cvo.order_ext	= @order_ext	AND 
						cvo.location	= @location		AND 
						cvo.line_no		= @line_no		AND 
						cvo.replaced	= 'S'  												  

			--SELECT * FROM #sub_parts						
			
			--get core components
			SELECT @temple_L_base = ISNULL(part_no,'') FROM #build_plan WHERE part_type = @def_temple_L
			SELECT @temple_R_base = ISNULL(part_no,'') FROM #build_plan WHERE part_type = @def_temple_R
			SELECT @screw_base	  = ISNULL(part_no,'') FROM #build_plan WHERE part_type = @def_screws
			SELECT @nosepad_base  = ISNULL(part_no,'') FROM #build_plan WHERE part_type = @def_nosepad
			SELECT @front_base    = ISNULL(part_no,'') FROM #build_plan WHERE part_type = @def_front
			
			--get replaced componentes
			SELECT @temple_P      = ISNULL(part_no,'') FROM #sub_parts WHERE part_type  = @def_temple_P
			SELECT @screw_new     = ISNULL(part_no,'') FROM #sub_parts WHERE part_type  = @def_screws
			SELECT @nosepad_new   = ISNULL(part_no,'') FROM #sub_parts WHERE part_type  = @def_nosepad
			SELECT @front_new     = ISNULL(part_no,'') FROM #sub_parts WHERE part_type = @def_front

			IF EXISTS(SELECT * FROM #sub_parts WHERE res_type = @def_part)
			BEGIN
				SELECT @temple_L_new  = ISNULL(part_no,'') FROM #sub_parts WHERE part_type  = @def_temple_L
				SELECT @temple_R_new  = ISNULL(part_no,'') FROM #sub_parts WHERE part_type  = @def_temple_R
			END

			-- START v1.3
			SET @left_tran_id = NULL
			SET @left_bin_from = NULL
			SET @right_tran_id = NULL
			SET @right_bin_from = NULL
			-- END v1.3


			SELECT @left_tran_id = tran_id,
				   @left_bin_from = bin_no
			FROM   tdc_pick_queue (NOLOCK)
			WHERE  trans_type_no = @order_no    AND
			       trans_type_ext = @order_ext AND
			       location = @location  AND
			       line_no  = @line_no AND
			       part_no = @temple_L_new AND
				   trans = 'MGTB2B'			

			SELECT @right_tran_id = tran_id,
				   @right_bin_from = bin_no
			FROM   tdc_pick_queue (NOLOCK)
			WHERE  trans_type_no = @order_no    AND
			       trans_type_ext = @order_ext AND
			       location = @location  AND
			       line_no  = @line_no AND
			       part_no = @temple_R_new AND
				   trans = 'MGTB2B'			


			/******************************************************************** HEADER ********************************************************************/
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME + @D1IndexStr, @LBL_LP_D1_ORIG_FRAME + @part_no)
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORDER_LINE_NO + @D1IndexStr, @LBL_LP_D1_ORDER_LINE_NO + CAST(@line_no AS VARCHAR(40)))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORDER_LINE_QTY + @D1IndexStr, @LBL_LP_D1_ORDER_LINE_QTY + CAST(@qty AS VARCHAR(40)))
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME_BIN_FROM + @D1IndexStr, @LBL_LP_D1_ORIG_FRAME_BIN_FROM + @bin_from)
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME_BIN_TO + @D1IndexStr, @LBL_LP_D1_ORIG_FRAME_BIN_TO + @bin_to)


			/********************************************************************  BODY ********************************************************************/
			-- v1.1
			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_Q_ID + @D3IndexStr + '_' + @D1IndexStr + '_1',	LTRIM(RTRIM(STR(@tran_id))))
			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr + '_1', 'Pull ' + @part_no + ' from Bin No: ' + @bin_from + ' and place in Custom Bin: ' +	@bin_to)				

			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_Q_ID + @D3IndexStr + '_' + @D1IndexStr + '_2',	LTRIM(RTRIM(STR(@left_tran_id))))
			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr + '_2', 'Pull ' + @temple_L_new + ' from Bin No: ' + @left_bin_from + ' and place in Custom Bin: ' +	@bin_to)

			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_Q_ID + @D3IndexStr + '_' + @D1IndexStr + '_3',	LTRIM(RTRIM(STR(@right_tran_id))))
			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr + '_3', 'Pull ' + @temple_R_new + ' from Bin No: ' + @right_bin_from + ' and place in Custom Bin: ' +	@bin_to)					

--			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr + '_2', 'Pull ' + @temple_L_base + ' - ' + @part_no_description + ' from bin ' + @bin_from)						

			SET @D3Index = @D3Index + 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))							
			
			--if replace is a frame
			IF EXISTS(SELECT * FROM #sub_parts WHERE res_type = @def_frame)
			BEGIN
				/*SELECT wp.asm_no, wp.part_no, imas.type_code, iadd.category_3
				FROM   what_part  wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
				WHERE  wp.part_no = imas.part_no AND
					   wp.part_no = iadd.part_no AND 				   
					   wp.asm_no  = (SELECT part_no FROM #sub_parts WHERE res_type = @frame)*/
				SELECT @temple_L_new = 'Frame has not build plan L'
				SELECT @temple_R_new = 'Frame has not build plan R'
									   
				SELECT @temple_L_new = ISNULL(wp.part_no,@temple_L_new)
				FROM   what_part  wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
				WHERE  wp.part_no      = imas.part_no	AND
					   wp.part_no      = iadd.part_no	AND 
					   iadd.category_3 = @def_temple_L  AND
					   wp.asm_no       = (SELECT part_no FROM #sub_parts WHERE res_type = @def_frame)					   
					   
				SELECT @temple_R_new = ISNULL(wp.part_no,@temple_R_new)
				FROM   what_part  wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
				WHERE  wp.part_no      = imas.part_no	AND
					   wp.part_no      = iadd.part_no	AND 
					   iadd.category_3 = @def_temple_R  AND
					   wp.asm_no       = (SELECT part_no FROM #sub_parts WHERE res_type = @def_frame)	
					   
				SELECT @part_no_to_dis = ISNULL(part_no, 'frame to disassemble')
				FROM   #sub_parts 
				WHERE  res_type = @def_frame				   

				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_CUSTOMIZE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_CUSTOMIZE  + @part_no)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_DISASSEMBLE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_DISASSEMBLE + @part_no_to_dis)

				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_L_base + @lbl_with  + @temple_L_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))		

				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_R_base + @lbl_with  + @temple_R_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))		
				
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_L_base
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_L_new
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_R_base
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_R_new

				DECLARE glass_build_plan_cur CURSOR FOR 
				SELECT wp.part_no
				FROM   what_part  wp (NOLOCK), inv_master imas (NOLOCK), inv_master_add iadd (NOLOCK)
				WHERE  wp.part_no		= imas.part_no	    AND
					   wp.part_no		= iadd.part_no	    AND 				   
					   iadd.category_3	<> @def_temple_L	AND
					   iadd.category_3	<> @def_temple_R	AND
					   wp.asm_no		= (SELECT part_no FROM #sub_parts WHERE res_type = @def_frame)

				OPEN glass_build_plan_cur

				FETCH NEXT FROM glass_build_plan_cur 
				INTO @temp_part_no

				WHILE @@FETCH_STATUS = 0
				BEGIN				  
				--piezas q le sobran al frame del tab de kit
				   --INSERT INTO #PrintData_INSTR(data_field, data_value) VALUES (@LP_D3_INSTR, @lbl_inventory_place + @temp_part_no + @lbl_inventory_back)
				   SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and tab de kit   -- ' + @temp_part_no
				   FETCH NEXT FROM glass_build_plan_cur 
				   INTO @temp_part_no
				END

				CLOSE glass_build_plan_cur
				DEALLOCATE glass_build_plan_cur
			END	
			ELSE
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_CUSTOMIZE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_CUSTOMIZE  + ' ')
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_DISASSEMBLE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_DISASSEMBLE + ' ')
			END	
																 
			--@def_temple_P
			IF EXISTS(SELECT * FROM #sub_parts WHERE part_type = @def_temple_P) 
			BEGIN	
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE  + @temple_L_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_P)
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))
								
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE  + @temple_R_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_P)										
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))				
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_L_base + @lbl_with  + @temple_P)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_R_base + @lbl_with  + @temple_P)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			

				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_L_base 
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_P	
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_R_base
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_P																	
			END 
					
			--@temple_L + @temple_R
			IF (SELECT COUNT(*) FROM #sub_parts WHERE part_type IN (@def_temple_L, @def_temple_R)) = 2
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE  + @temple_L_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_L_new)
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))								
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE  + @temple_R_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_R_new)										
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))								
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_L_base + @lbl_with  + @temple_L_new)
				SET @D3Index   = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))		
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_R_base + @lbl_with  + @temple_R_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))					
				
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_L_base 
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_L_new	
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_R_base
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_R_new													
			END
			ELSE 
			BEGIN 					
				IF (SELECT COUNT(*) FROM #sub_parts WHERE part_type IN (@def_temple_L)) = 1
				BEGIN
					-- @temple_L 
					INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr , @LBL_LP_D2_PART_TO_REPLACE  + @temple_L_base)
					INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_L_new)
					SET @D2Index    = @D2Index + 1
					SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))						
					
					INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_L_base + @lbl_with  + @temple_L_new)
					SET @D3Index    = @D3Index + 1
					SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			
					
					SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_L_base 
					SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_L_new					
				END						
				ELSE
				BEGIN
					--@temple_R
					IF (SELECT COUNT(*) FROM #sub_parts WHERE part_type IN (@def_temple_R)) = 1
					BEGIN
						INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE  + @temple_R_base)
						INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @temple_R_new)									
						SET @D2Index    = @D2Index + 1
						SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))		
						
						INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @temple_R_base + @lbl_with  + @temple_R_new)
						SET @D3Index    = @D3Index + 1
						SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			
						
						SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @temple_R_base
						SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @temple_R_new	
					END						
				END
			END
			
			--screw
			IF EXISTS(SELECT * FROM #sub_parts WHERE part_type = @def_screws) 
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE + @screw_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @screw_new)						
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr,@lbl_replace + @screw_base + @lbl_with  + @screw_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			
				
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @screw_base 
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' + @screw_new  
			END								

			--@def_nosepad
			IF EXISTS(SELECT * FROM #sub_parts WHERE part_type = @def_nosepad) 
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_PART_TO_REPLACE + @nosepad_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @nosepad_new)			
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))				
				
				INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @nosepad_base + @lbl_with  + @nosepad_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))		
				
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @nosepad_base 
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' +  @nosepad_new   
			END

			--@def_front
			IF EXISTS(SELECT * FROM #sub_parts WHERE part_type = @def_front) 
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr , @LBL_LP_D2_PART_TO_REPLACE  + @front_base)
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, @LBL_LP_D2_REPLACEMENT_PART + @front_new)
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))	
				
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_replace + @front_base + @lbl_with  + @front_new)
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))		
				
				SET @lbl_inventory_place_plus = @lbl_inventory_place_plus + ' and ' + @front_base 
				SET @lbl_inventory_out_plus   = @lbl_inventory_out_plus   + ' and ' +  @front_new        
			END			
			
			--into inventory
--			IF SUBSTRING(@lbl_inventory_place_plus,1,4) = ' and' --remove 'and' spaces
--				SET @lbl_inventory_place_plus = SUBSTRING(@lbl_inventory_place_plus,6,LEN(@lbl_inventory_place_plus)-3)
			
--			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_inventory_place + @lbl_inventory_place_plus + @lbl_inventory_back)
--			SET @D3Index    = @D3Index + 1
--			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))	

			--out of inventory 
			IF SUBSTRING(@lbl_inventory_out_plus,1,4) = ' and' --remove 'and' spaces
				SET @lbl_inventory_out_plus = SUBSTRING(@lbl_inventory_out_plus,6,LEN(@lbl_inventory_out_plus)-3)
				
--			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_inventory_out + @lbl_inventory_out_plus )													
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_pick )													
			SET @D3Index    = @D3Index + 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))															
						
			--manual allocation
--			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_manually_allocate)
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_pack)

			SET @D3Index    = @D3Index + 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			

			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, @lbl_final)

			SET @D3Index    = @D3Index + 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))			

			
			--complete EOF with blank spaces
			WHILE @D2Index < = @totalD2Lines
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr , ' ')
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, ' ')
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))						
			END
			
			--complete EOF with blank spaces
			WHILE @D3Index < = @totalD3Lines
			BEGIN
				INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, ' ')
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))						
			END

			--next frame line
			SET @D1Index    = @D1Index + 1
			SET @D1IndexStr = CAST(@D1Index AS VARCHAR(2))
			
			--reset frame to number one for the next page
			IF (@D1Index % 2) != 0
			BEGIN
				SET @D1Index = 1
				SET @D1IndexStr = CAST(@D1Index AS VARCHAR(2))			
			END

			SET @D3Index = 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))					

			SET @D2Index = 1
			SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))												
							 
			FETCH NEXT FROM values_cur 
			INTO @order_no, @order_ext, @location, @line_no, @part_no			
		END
		CLOSE values_cur
		DEALLOCATE values_cur	
		
		--complete EOF with blank spaces
		IF (@D1Index % 2) = 0
		BEGIN
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME + @D1IndexStr, ' ')
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORDER_LINE_NO + @D1IndexStr, ' ')
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORDER_LINE_QTY + @D1IndexStr, ' ')
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME_BIN_FROM + @D1IndexStr, ' ')
			INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D1_ORIG_FRAME_BIN_TO + @D1IndexStr, ' ')		

			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_CUSTOMIZE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_CUSTOMIZE  + ' ')
			INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_FRAME_TO_DISASSEMBLE + @D1IndexStr, @LBL_LP_D2_FRAME_TO_DISASSEMBLE + ' ')
		
			SET @D2Index    = 1
			SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))																
			WHILE @D2Index < = @totalD2Lines
			BEGIN
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_PART_TO_REPLACE + @D2IndexStr + '_' + @D1IndexStr , ' ')
				INSERT INTO #PrintData (data_field, data_value) VALUES (@LP_D2_REPLACEMENT_PART + @D2IndexStr + '_' + @D1IndexStr, ' ')
				SET @D2Index    = @D2Index + 1
				SET @D2IndexStr = CAST(@D2Index AS VARCHAR(2))						
			END
			
			SET @D3Index = 1
			SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))					
			WHILE @D3Index < = @totalD3Lines
			BEGIN
				INSERT INTO #PrintData(data_field, data_value) VALUES (@LP_D3_INSTR + @D3IndexStr + '_' + @D1IndexStr, ' ')
				SET @D3Index    = @D3Index + 1
				SET @D3IndexStr = CAST(@D3Index AS VARCHAR(2))						
			END				
		END		
		
		--IF OBJECT_ID('tempdb..##algo') IS NOT NULL DROP TABLE ##algo
		--SELECT * INTO ##algo FROM #PrintData					 						   	 					
END

GO
GRANT EXECUTE ON  [dbo].[CVO_disassembled_inv_adjust_sp] TO [public]
GO
