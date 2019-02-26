SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_hello_bestsellers_sp]
    @customer VARCHAR(10) = NULL, @ship_to VARCHAR(10) = NULL
AS

-- exec cvo_hello_bestsellers_sp '045183'

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
    WHERE Period = 'Last 60 days'
    ;
	SELECT @sdatetyytd = begindate
	FROM dbo.cvo_date_range_vw AS drv
	where period = 'Year To Date'
	;


    SELECT TOP (5)
		sd.customer,
		sd.ship_to,
        i.Collection,
        i.model,
        
        SUM(   CASE
                   WHEN yyyymmdd >= @sdatety THEN
                       qnet
                   ELSE
                       0
               END
           ) TY,
          MAX(yyyymmdd) last_ship_date
    FROM
        dbo.cvo_sbm_details AS sd (nolock)
        JOIN dbo.cvo_inv_master_r2_vw AS  i (nolock)
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
    GROUP BY sd.customer, sd.ship_to, i.Collection, i.model
    HAVING SUM(   CASE
                       WHEN yyyymmdd >= @sdatety THEN
                           anet
                       ELSE
                           0
                   END
               ) > 0
               
    ORDER BY TY desc
    
    ;

END
;

GRANT EXECUTE
ON dbo.cvo_hello_bestsellers_sp
TO  PUBLIC
;





GO
GRANT EXECUTE ON  [dbo].[cvo_hello_bestsellers_sp] TO [public]
GO
