SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_bo_call_list_refresh_sp]
AS
BEGIN

    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;


    IF (OBJECT_ID('tempdb..#rxbo')) IS NOT NULL
        DROP TABLE #rxbo;

    CREATE TABLE #rxbo
    (
        brand VARCHAR(10),
        style VARCHAR(40),
        part_no VARCHAR(30),
        type_code VARCHAR(10),
        pom_date DATETIME,
        ss INT,
        order_no INT,
        ext INT,
        user_category VARCHAR(10),
        date_entered DATETIME,
        location VARCHAR(10),
        open_qty DECIMAL(21, 8),
        qty_to_alloc INT,
        reserveqty INT,
        reserve_bin VARCHAR(12),
        quarantine INT,
        nextpoduedate VARCHAR(12),
        DDTONEXTPO INT,
        note VARCHAR(255),
        phone VARCHAR(20),
        attention VARCHAR(40),
        ship_to_name VARCHAR(40),
        cust_code VARCHAR(10),
        ship_to VARCHAR(10),
        description VARCHAR(255),
        bo_days INT,
        DaysOverDue VARCHAR(7),
        comment VARCHAR(255)
    );

    INSERT INTO #rxbo
    EXEC cvo_bo_to_alloc_rx;

	-- DROP TABLE cvo_bo_call_list_Tbl

    IF OBJECT_ID('dbo.cvo_bo_call_list_tbl') IS NULL
    BEGIN
        CREATE TABLE dbo.cvo_bo_call_list_tbl
        (
            cust_code VARCHAR(10),
            ship_to VARCHAR(10),
            ship_to_name VARCHAR(40),
            phone VARCHAR(20),
            attention VARCHAR(40),
			contact_status SMALLINT ,
			contact_time DATETIME NULL,
			ship_to_zip VARCHAR(15),
			id INT IDENTITY(1,1)
        );
    END;
    TRUNCATE TABLE dbo.cvo_bo_call_list_tbl;

	INSERT INTO dbo.cvo_bo_call_list_tbl
	(
	    cust_code,
	    ship_to,
	    ship_to_name,
	    phone,
	    attention,
	    contact_status,
	    contact_time,
		ship_to_zip
	)

    SELECT DISTINCT 
		   r.cust_code,
           r.ship_to,
           r.ship_to_name,
           r.phone,
           r.attention,
		   0 AS contact_status,
		   GETDATE() AS contact_time,
		   o.ship_to_zip
    FROM #rxbo AS r
	JOIN orders o (nolock) ON o.order_no = r.order_no AND o.ext = r.ext
    WHERE (r.DDTONEXTPO >= 10)
          AND r.location = '001'
          AND r.qty_to_alloc < 0
	ORDER BY o.ship_to_zip; -- to sort  by zip so we don't call CA first :)


    DROP TABLE #rxbo;

END;


GRANT EXECUTE ON dbo.cvo_bo_call_list_refresh_sp TO PUBLIC;




GO
GRANT EXECUTE ON  [dbo].[cvo_bo_call_list_refresh_sp] TO [public]
GO
