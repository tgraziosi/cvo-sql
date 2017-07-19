SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_framesearch_sp]
    @terr VARCHAR(10) = NULL,
    @sku VARCHAR(40) = NULL,
    @customer VARCHAR(10) = NULL,
    @ship_to VARCHAR(10) = NULL
AS

-- exec cvo_hello_backorders_sp '028590'
-- exec cvo_hello_framesearch_sp '20206', 'ASELEGBRO5216', '039226',''

BEGIN

    SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

    SELECT
        i.part_no, ol.shipped, date_shipped, o.ship_to_name, ship_to_city, phone, o.attention, o.cust_code, o.ship_to
    FROM
        orders o (NOLOCK)
        JOIN ord_list ol (NOLOCK)
            ON ol.order_no = o.order_no
               AND ol.order_ext = o.ext
        JOIN inv_master i (NOLOCK)
            ON i.part_no = ol.part_no
    WHERE
        1 = 1
        -- AND i.type_code IN ('frame','sun')
		AND i.part_no = ISNULL(@sku, '')
        AND ol.shipped <> 0
        AND o.date_shipped >= DATEADD(MONTH, -1, GETDATE())
        AND o.status = 'T'
        -- AND o.type = 'i'
        AND o.user_category LIKE 'ST%'
        AND RIGHT(o.user_category, 2) <> 'RB'
        AND o.ship_to_region = ISNULL(@terr, '')
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
