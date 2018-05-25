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
        @sdatety DATETIME, @edatety DATETIME, @sdatetyytd DATETIME
    ;

    SELECT
        @sdatety = BeginDate, @edatety = EndDate
		-- select * 
    FROM dbo.cvo_date_range_vw AS drv
    WHERE Period = 'rolling 12 ty'
    ;
	SELECT @sdatetyytd = begindate
	FROM dbo.cvo_date_range_vw AS drv
	where period = 'Year To Date'
	;


    SELECT
		sd.customer,
		sd.ship_to,
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
           ) LY,
		SUM(   CASE
                   WHEN yyyymmdd > @sdatetyytd THEN
                       anet
                   ELSE
                       0
               END
           ) TYYTD
    FROM
        dbo.cvo_sbm_details AS sd (nolock)
        JOIN inv_master i (nolock)
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
    GROUP BY sd.customer, sd.ship_to, i.category
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
