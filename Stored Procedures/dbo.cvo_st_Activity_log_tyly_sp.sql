SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_st_Activity_log_tyly_sp]
	@startdate DATETIME,
    @enddate DATETIME,
    @Territory VARCHAR(1000) = NULL,
    @qualorder INT = 1, -- 1= qual, 0 = unqual, -1 = all
    @detail INT = 0     -- 0 = no, any other value = yes
AS
BEGIN

	SET NOCOUNT ON;
	
-- exec cvo_st_activity_log_tyly_sp '1/1/2018','1/31/2018', null, -1

	DECLARE @sdately DATETIME, @edately DATETIME,
			@sdatelm DATETIME, @edatelm datetime

	SELECT @sdately = DATEADD(YEAR,-1,@startdate), @edately = DATEADD(YEAR,-1,@enddate),
		   @sdatelm = DATEADD(month,-1,@startdate), @edatelm = DATEADD(month,-1,@enddate)

    CREATE TABLE #t
    (
        cust_code VARCHAR(10) null,
        ship_to VARCHAR(10) null,
        ship_To_door VARCHAR(10),
        ship_to_name VARCHAR(40),
        salesperson VARCHAR(10),
        salesperson_name VARCHAR(60),
        Territory VARCHAR(10),
        region VARCHAR(3),
        total_amt_order DECIMAL(38, 8),
        total_discount DECIMAL(38, 8),
        total_tax DECIMAL(38, 8),
        freight DECIMAL(38, 8),
        qty_ordered DECIMAL(38, 8),
        qty_shipped DECIMAL(38, 8),
        total_invoice DECIMAL(38, 8),
        FramesOrdered DECIMAL(38, 8),
        FramesShipped DECIMAL(38, 8),
        FramesRMA INT,
        net_rx DECIMAL(38, 8),
        net_sales DECIMAL(38, 8),
		yy VARCHAR(2) null
    );

	CREATE NONCLUSTERED INDEX idx_t_yy ON #t (yy asc);
	
	CREATE NONCLUSTERED INDEX idx_t_cust ON #t (cust_code ASC, ship_to asc);


    INSERT INTO #t
	(
	    cust_code,
	    ship_to,
	    ship_To_door,
	    ship_to_name,
	    salesperson,
	    salesperson_name,
	    Territory,
	    region,
	    total_amt_order,
	    total_discount,
	    total_tax,
	    freight,
	    qty_ordered,
	    qty_shipped,
	    total_invoice,
	    FramesOrdered,
	    FramesShipped,
	    FramesRMA,
	    net_rx,
	    net_sales
	)
    EXEC dbo.cvo_ST_Activity_log_sp @startdate = @startdate, @enddate = @enddate
			, @Territory = @Territory, @qualorder = @qualorder, @detail = @detail
	UPDATE #t SET yy = 'TY' WHERE yy IS NULL;

	IF MONTH(@startdate) > 1 
    BEGIN
    
	    CREATE TABLE #pm
    (
        cust_code VARCHAR(10) null,
        ship_to VARCHAR(10) null,
        ship_To_door VARCHAR(10),
        ship_to_name VARCHAR(40),
        salesperson VARCHAR(10),
        salesperson_name VARCHAR(60),
        Territory VARCHAR(10),
        region VARCHAR(3),
        total_amt_order DECIMAL(38, 8),
        total_discount DECIMAL(38, 8),
        total_tax DECIMAL(38, 8),
        freight DECIMAL(38, 8),
        qty_ordered DECIMAL(38, 8),
        qty_shipped DECIMAL(38, 8),
        total_invoice DECIMAL(38, 8),
        FramesOrdered DECIMAL(38, 8),
        FramesShipped DECIMAL(38, 8),
        FramesRMA INT,
        net_rx DECIMAL(38, 8),
        net_sales DECIMAL(38, 8)
    );
	-- get last month's activity too to check for customers to remove from valid UC list
	    INSERT INTO #pm
	(
	    cust_code,
	    ship_to,
	    ship_To_door,
	    ship_to_name,
	    salesperson,
	    salesperson_name,
	    Territory,
	    region,
	    total_amt_order,
	    total_discount,
	    total_tax,
	    freight,
	    qty_ordered,
	    qty_shipped,
	    total_invoice,
	    FramesOrdered,
	    FramesShipped,
	    FramesRMA,
	    net_rx,
	    net_sales
	)
    EXEC dbo.cvo_ST_Activity_log_sp @startdate = @sdatelm 
			, @enddate = @edatelm
			, @Territory = @Territory, @qualorder = 1 , @detail = @detail -- look at qualified orders only for the lookback


	CREATE NONCLUSTERED INDEX idx_pm_cust ON #pm (cust_code ASC, ship_to asc);

	UPDATE ty SET ship_to_door = 'PM' 
	FROM #t ty
	WHERE EXISTS (SELECT 1 FROM #pm pm WHERE pm.cust_code = ty.cust_code AND pm.ship_to = ty.ship_to)
	;

	END;

	-- get LY data

		INSERT INTO #t
	(
	    cust_code,
	    ship_to,
	    ship_To_door,
	    ship_to_name,
	    salesperson,
	    salesperson_name,
	    Territory,
	    region,
	    total_amt_order,
	    total_discount,
	    total_tax,
	    freight,
	    qty_ordered,
	    qty_shipped,
	    total_invoice,
	    FramesOrdered,
	    FramesShipped,
	    FramesRMA,
	    net_rx,
	    net_sales
	)
    EXEC dbo.cvo_ST_Activity_log_sp @startdate = @sdately, @enddate = @edately
			, @Territory = @Territory, @qualorder = @qualorder, @detail = @detail

	UPDATE #t SET yy = 'LY' WHERE yy IS NULL;

	-- final select

	SELECT t.cust_code,
           t.ship_to,
           t.ship_To_door,
           t.ship_to_name,
           t.salesperson,
           t.salesperson_name,
           t.Territory,
           t.region,
           t.total_amt_order,
           t.total_discount,
           t.total_tax,
           t.freight,
           t.qty_ordered,
           t.qty_shipped,
           t.total_invoice,
           t.FramesOrdered,
           t.FramesShipped,
           t.FramesRMA,
           t.net_rx,
           t.net_sales,
           t.yy FROM #t AS t

END;

GRANT EXECUTE ON dbo.cvo_st_Activity_log_tyly_sp TO PUBLIC;



GO
GRANT EXECUTE ON  [dbo].[cvo_st_Activity_log_tyly_sp] TO [public]
GO
