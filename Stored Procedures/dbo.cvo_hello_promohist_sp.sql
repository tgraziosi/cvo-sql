SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_promohist_sp]
    @customer VARCHAR(10) = NULL, @ship_to VARCHAR(10) = NULL
AS

-- exec cvo_hello_promohist_sp '052388'

BEGIN

    DECLARE
        @st DATETIME, @end DATETIME
    ;

    SELECT @end = EndDate
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'rolling 12 ty'
    ;
    SELECT @st = DATEADD(YEAR, -3, @end)
    ;

	SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

    SELECT
        sbm.customer, ship_to, sbm.promo_id+','+sbm.promo_level program, MIN(yyyymmdd) Ship_Date, SUM(qsales) Sales_qty
    FROM
        armaster ar (NOLOCK)
        LEFT OUTER JOIN cvo_sbm_details sbm (NOLOCK)
            ON ar.customer_code = sbm.customer
               AND ar.ship_to_code = sbm.ship_to
        LEFT OUTER JOIN inv_master i (NOLOCK)
            ON i.part_no = sbm.part_no
               AND i.type_code IN ( 'frame', 'sun' )

    WHERE
        sbm.customer = ISNULL(@customer, '')
        AND sbm.ship_to = ISNULL(@ship_to, '')
		and sbm.promo_id <> ''
		AND 'RB'<> RIGHT(sbm.user_category,2) -- 2/13/18        
		AND sbm.yyyymmdd BETWEEN @st AND @end
    GROUP BY sbm.promo_id + ',' + sbm.promo_level, sbm.customer, sbm.ship_to
    ;

    ;

END
;

GRANT EXECUTE
ON dbo.cvo_hello_promohist_sp
TO  PUBLIC
;






GO
GRANT EXECUTE ON  [dbo].[cvo_hello_promohist_sp] TO [public]
GO
