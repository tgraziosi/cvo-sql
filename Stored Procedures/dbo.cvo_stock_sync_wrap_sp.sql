SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[cvo_stock_sync_wrap_sp] AS
begin
SET NOCOUNT ON
SET ANSI_WARNINGS OFF

DECLARE @location VARCHAR(10) ,
    @upd_option INT;

SET @location = '';
SET @upd_option = 0;
 -- report only


CREATE TABLE #inv_compare
    (
      id INT ,
      location VARCHAR(10) ,
      part_no VARCHAR(30) ,
      inv_stock DECIMAL(20, 8) ,
      lb_stock DECIMAL(20, 8) ,
      diff_stock DECIMAL(20, 8) ,
      no_loc SMALLINT ,
      issue_qty DECIMAL(20, 8) ,
      act_issue_qty DECIMAL(20, 8) ,
      sales_qty DECIMAL(20, 8) ,
      act_sales_qty DECIMAL(20, 8) ,
      xfer_qty DECIMAL(20, 8) ,
      act_xfer_qty DECIMAL(20, 8) ,
      rec_qty DECIMAL(20, 8) ,
      act_rec_qty DECIMAL(20, 8)
    );


SELECT  @location = MIN(location)
FROM    dbo.locations_all AS la
WHERE   location > @location
        AND la.void = 'N';

WHILE @location IS NOT NULL
    BEGIN
        --SELECT  ' Checking location: ' ,
        --        @location;
        INSERT  INTO #inv_compare
                ( id ,
                  location ,
                  part_no ,
                  inv_stock ,
                  lb_stock ,
                  diff_stock ,
                  no_loc ,
                  issue_qty ,
                  act_issue_qty ,
                  sales_qty ,
                  act_sales_qty ,
                  xfer_qty ,
                  act_xfer_qty ,
                  rec_qty ,
                  act_rec_qty
	            )
                EXEC dbo.cvo_stock_sync_sp @upd_option, @location;
        SELECT  @location = MIN(location)
        FROM    dbo.locations_all AS la
        WHERE   location > @location
                AND la.void = 'N';
    END;

SELECT  ic.id ,
        ic.location ,
        ic.part_no ,
        ic.inv_stock ,
        ic.lb_stock ,
        ic.diff_stock ,
        ic.no_loc ,
        ic.issue_qty ,
        ic.act_issue_qty ,
        ic.sales_qty ,
        ic.act_sales_qty ,
        ic.xfer_qty ,
        ic.act_xfer_qty ,
        ic.rec_qty ,
        ic.act_rec_qty
FROM    #inv_compare AS ic;


-- now update any locations with differences


SET @location = '';
SET @upd_option = 1; -- update
	
SELECT  TOP (1) @location = MIN(location)
FROM    #inv_compare AS ic
WHERE   location > @location;

WHILE @location IS NOT NULL
    BEGIN
        --SELECT  ' Updating location: ' ,
        --        @location;

        EXEC dbo.cvo_stock_sync_sp @upd_option, @location;
        
		SELECT  TOP (1) @location = MIN(location)
        FROM    #inv_compare AS ic
        WHERE   location > @location;
    END;

END
GO
GRANT EXECUTE ON  [dbo].[cvo_stock_sync_wrap_sp] TO [public]
GO
