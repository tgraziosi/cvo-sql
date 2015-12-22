SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_packverify_get_carton_info_sp]
		@carton_no int
AS

DECLARE @order_no  int,
	@order_ext int,
	@error_msg varchar(255),
	@language  varchar(10)

SELECT @language = ISNULL((SELECT Language FROM tdc_sec (nolock) WHERE userid = (SELECT who FROM #temp_who)), 'us_english')

------------------------------------------------------------------
-- 		Firstly, validate carton_no			--
------------------------------------------------------------------
-- Get order_no and order_ext
SELECT @order_no  = order_no,
       @order_ext = order_ext
  FROM tdc_carton_detail_tx (NOLOCK)
 WHERE carton_no = @carton_no
   AND qty_to_pack > 0

IF ISNULL(@order_no, 0) = 0
BEGIN
	-- 'Invalid Carton Number.'
	SELECT @error_msg = err_msg FROM tdc_lookup_error (nolock) WHERE module = 'SPR' AND trans = 'tdc_packverify_get_carton_info_sp' AND err_no = -101 AND language = @language 
	RAISERROR (@error_msg, 16, 1)
	RETURN
END
 
IF EXISTS (SELECT *
	     FROM tdc_main (NOLOCK)
	    WHERE consolidation_no = (SELECT consolidation_no 
		        	        FROM tdc_cons_ords
				       WHERE order_no  = @order_no
	                                 AND order_ext = @order_ext)
	      AND virtual_freight = 'Y')
AND NOT EXISTS(SELECT * FROM tdc_carton_tx (NOLOCK)
		WHERE carton_no = @carton_no
		  AND status IN('S', 'X')) 
BEGIN
	SELECT CAST(@order_no AS varchar(10)) + ' - ' + CAST(@order_ext AS varchar(4))  AS order_plus_ext,
       	       NULL AS ship_to_name, 	NULL AS ship_to_add_1, 	  NULL AS ship_to_add_2,
       	       NULL AS ship_to_add_3,	NULL AS ship_to_add_4,    NULL AS weight, 	  NULL AS carton_code,
       	       NULL AS pack_type,	NULL AS so_priority_text, NULL AS so_priority_code,
       	       NULL AS carrier_code,	NULL AS sch_ship_date,    NULL AS charge_code, 
       	       NULL AS back_ord_flag,   NULL AS note,		  NULL AS stage_no,
       	       'Virtual Freight'	AS status                     

	--RAISERROR ('Invalid carton: carton marked for virtual freighting.', 16, 1)
	--RETURN
END
 
------------------------------------------------------------------
-- 	Secondly, fill the temp table for Pack Ver grid		--
------------------------------------------------------------------
TRUNCATE TABLE #pack_verify_items
-- Cum Packed is the Cumulative number of this item packed for this order.
-- Item may be packed within a different carton for the same order.

INSERT INTO #pack_verify_items (line_no, part_no, [description], ordered, pre_packed, cum_packed, to_pack, cur_packed, status)
SELECT DISTINCT
       b.display_line, 
       a.part_no, 
       b.[description], 
       b.ordered, 
       pre_packed = ISNULL((SELECT SUM (qty_to_pack)
		              FROM tdc_carton_detail_tx c (NOLOCK)
                             WHERE order_no  = @order_no	
		               AND order_ext = @order_ext
			       AND c.part_no = a.part_no
                               AND c.line_no = a.line_no), 0),
       cum_packed = ISNULL((SELECT SUM (pack_qty)
		              FROM tdc_carton_detail_tx c (NOLOCK)
                             WHERE order_no  = @order_no	
		               AND order_ext = @order_ext
			       AND c.part_no = a.part_no
                               AND c.line_no = a.line_no), 0),
       to_pack    = ISNULL((SELECT SUM (qty_to_pack)
		              FROM tdc_carton_detail_tx c (NOLOCK)
                             WHERE carton_no = @carton_no
			       AND c.part_no = a.part_no
                               AND c.line_no = a.line_no), 0)
		    - 
		   ISNULL((SELECT SUM (pack_qty)
		              FROM tdc_carton_detail_tx c (NOLOCK)
                             WHERE carton_no = @carton_no
			       AND c.part_no = a.part_no
                               AND c.line_no = a.line_no), 0), 
       pack_qty   = (SELECT SUM(c.pack_qty) 
		       FROM tdc_carton_detail_tx c
		      WHERE c.order_no  = b.order_no
                        AND c.order_ext = b.order_ext
 		        AND c.part_no = a.part_no
                        AND c.line_no   = b.line_no
                        AND c.carton_no = @carton_no), 
       status      = CASE a.status 
			WHEN 'P' THEN 'Pre-Packed'
			WHEN 'Q' THEN 'Pack-Ready'
			WHEN 'O' THEN 'Open'
			WHEN 'C' THEN 'Closed'
			WHEN 'S' THEN 'Staged'
		        WHEN 'F' THEN 'Freighted'
			WHEN 'X' THEN 'Shipped'
				 ELSE 'Bad Status'
	       	     END									
  FROM tdc_carton_detail_tx a (NOLOCK), ord_list b (NOLOCK)
 WHERE a.order_no  = b.order_no
   AND a.order_ext = b.order_ext
   AND a.line_no   = b.line_no
   AND a.carton_no = @carton_no

------------------------------------------------------------------
-- 		Thirdly, get the carton header info		--
------------------------------------------------------------------
SELECT CAST(@order_no AS varchar(10)) + ' - ' + CAST(@order_ext AS varchar(4))  AS order_plus_ext,
       o.ship_to_name, 
       o.ship_to_add_1, 
       o.ship_to_add_2, 
       o.ship_to_add_3,
       o.ship_to_add_4, 
       c.weight, 
       c.carton_type   								AS carton_code,
       c.carton_class								AS pack_type,
       CASE c.status 
		WHEN 'P' THEN 'Pre-Packed'
		WHEN 'Q' THEN 'Pack-Ready'
		WHEN 'O' THEN 'Open'
		WHEN 'C' THEN 'Closed'
		WHEN 'S' THEN 'Staged'
		WHEN 'X' THEN 'Shipped'
		WHEN 'F' THEN 'Freighted'
			 ELSE 'Bad Status'
       END									AS status, 
       c.carrier_code,
       CONVERT(varchar(10), o.sch_ship_date, 110) 				AS sch_ship_date, 
       c.charge_code, 
       o.back_ord_flag, 
       o.note,
       (SELECT stage_no
          FROM tdc_stage_carton (NOLOCK)
         WHERE carton_no = @carton_no)						AS stage_no,
       (SELECT priority_code 
          FROM order_priority (NOLOCK) 
         WHERE order_priority_id = o.so_priority_code) 			        AS so_priority_text,
       so_priority_code                        
  FROM tdc_carton_tx c (NOLOCK), orders o (NOLOCK)
 WHERE o.order_no  = c.order_no
   AND o.ext       = c.order_ext
   AND c.carton_no = @carton_no

RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_packverify_get_carton_info_sp] TO [public]
GO
