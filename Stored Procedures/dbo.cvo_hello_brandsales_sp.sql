SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_brandsales_sp]
    @customer VARCHAR(10) = NULL, @ship_to VARCHAR(10) = NULL
AS

-- exec cvo_hello_brandsales_sp '013748'

BEGIN

    SET NOCOUNT ON
    ;
    SET ANSI_WARNINGS OFF
    ;

    DECLARE
        @sdatety DATETIME, @edatety DATETIME
    ;

    SELECT
        @sdatety = BeginDate, @edatety = EndDate
		-- select * 
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'rolling 12 ty'
    ;

    SELECT
        i.category,
        SUM(   CASE
                   WHEN yyyymmdd >= @sdatety THEN
                       anet
                   ELSE
                       0
               END
           ) TY,
        SUM(   CASE
                   WHEN yyyymmdd < @sdatety THEN
                       anet
                   ELSE
                       0
               END
           ) LY
    FROM
        dbo.cvo_sbm_details AS sd
        JOIN inv_master i
            ON i.part_no = sd.part_no
    WHERE
        (
            yyyymmdd
        BETWEEN @sdatety AND @edatety
            OR yyyymmdd
        BETWEEN DATEADD(YEAR, -1, @sdatety) AND DATEADD(YEAR, -1, @edatety)
        )
        AND customer = ISNULL(@customer, '')
        AND sd.ship_to = ISNULL(@ship_to, sd.ship_to)
    GROUP BY i.category
    ;

END
;

GRANT EXECUTE
ON dbo.cvo_hello_brandsales_sp
TO  PUBLIC
;


GO
GRANT EXECUTE ON  [dbo].[cvo_hello_brandsales_sp] TO [public]
GO
