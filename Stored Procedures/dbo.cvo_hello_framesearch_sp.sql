SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_framesearch_sp]
    @terr VARCHAR(10) = NULL,
    @sku VARCHAR(40) = NULL,
    @customer VARCHAR(10) = NULL,
    @ship_to VARCHAR(10) = NULL,
	@days INT = 60
AS

-- exec cvo_hello_backorders_sp '028590'
-- exec cvo_hello_framesearch_sp '20206', 'asm',null,null,365

-- SELECT * FROM dbo.cvo_hs_inventory_8 AS hi WHERE model = 'vince'

BEGIN

    SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

	-- allow mastersku or model to be passed in as well.  Figure out a list of skus to search for

	
	IF (SELECT OBJECT_ID('tempdb..#sku')) IS NOT NULL BEGIN DROP TABLE #sku  END
	CREATE TABLE #sku (part_no VARCHAR(40))

	INSERT #sku (part_no)
		SELECT DISTINCT hi.sku 
		FROM dbo.cvo_hs_inventory_8 AS hi WHERE @sku = hi.mastersku OR @sku = hi.Model OR @sku = hi.sku

	IF @@ROWCOUNT = 0
	begin
    SELECT @sku = '%'+@sku+'%';
		INSERT #sku (part_no)
		SELECT DISTINCT hi.sku 
		FROM dbo.cvo_hs_inventory_8 AS hi WHERE hi.mastersku LIKE @sku  OR hi.model LIKE @sku OR hi.sku like @sku
	END
    
		
	IF (SELECT OBJECT_ID('tempdb..#terr')) IS NOT NULL BEGIN DROP TABLE #terr  END
	CREATE TABLE #terr (territory VARCHAR(12))

	INSERT #terr (territory)
		SELECT DISTINCT t.territory_code
		FROM dbo.cvo_sc_addr_vw AS t WHERE @terr = t.territory_code OR @terr = t.region


    SELECT
        i.category Brand, Ia.field_2 Style, ia.field_3 ColorName, CAST(CAST(ia.field_17 AS INTEGER) AS VARCHAR(2)) eye_size, 
		i.category +' '+ ia.field_2 +' '+ ia.field_3 +' '+ CAST(cast(ia.field_17 AS integer) AS VARCHAR(2)) SKU, i.part_no, ol.shipped, date_shipped, DATEDIFF(day,o.date_shipped, GETDATE()) days_ago, o.ship_to_name, ship_to_city, phone, o.attention, o.cust_code, o.ship_to, t.territory
    FROM
		#sku AS s
		JOIN inv_master i (NOLOCK)
           ON i.part_no = s.part_no
		JOIN inv_master_add ia (NOLOCK)
			ON ia.part_no = s.part_no

        JOIN ord_list ol (NOLOCK) ON ol.part_no = s.part_no
		JOIN orders o (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
		JOIN #terr t ON t.territory = o.ship_to_region

    WHERE
        1 = 1
        -- AND i.type_code IN ('frame','sun')
		-- AND i.part_no = ISNULL(@sku, '')
        AND ol.shipped <> 0
        AND o.date_shipped >= DATEADD(day, -@days, GETDATE())
        AND o.status = 'T'
        -- AND o.type = 'i'
        AND o.user_category LIKE 'ST%'
        AND RIGHT(o.user_category, 2) <> 'RB'
        -- AND o.ship_to_region = ISNULL(@terr, '')
		AND o.cust_code+o.ship_to <> ISNULL(@customer,'')+ISNULL(@ship_to,'')

    ;


END
;

GRANT EXECUTE
ON dbo.cvo_hello_framesearch_sp
TO  PUBLIC
;

--select * FROM cvo_sbm_details sbm
--JOIN armaster ar ON ar.customer_code = sbm.customer AND ar.ship_to_code = sbm.ship_to
--WHERE yyyymmdd >= DATEADD(MONTH,-1,GETDATE())
--AND ar.territory_code = '20206'
--AND sbm.user_category = 'st'
--ORDER BY sbm.part_no





GO
GRANT EXECUTE ON  [dbo].[cvo_hello_framesearch_sp] TO [public]
GO
