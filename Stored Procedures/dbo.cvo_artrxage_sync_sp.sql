SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_artrxage_sync_sp]
-- 072518 - keep cvo_artrxage up to date.  
-- A Trigger does most of it.  This will clean up the rest.
AS
BEGIN

    SET NOCOUNT ON;

    IF OBJECT_ID('dbo.cvo_artrxage') IS NULL
    BEGIN

        CREATE TABLE dbo.cvo_artrxage
        (
            doc_ctrl_num VARCHAR(16),
            order_ctrl_num VARCHAR(16),
            customer_code VARCHAR(10),
            doc_date_int INT,
            doc_date VARCHAR(10),
            parent VARCHAR(10)
        );

        GRANT INSERT, UPDATE, DELETE, SELECT ON dbo.cvo_artrxage TO PUBLIC;
    END;

    -- Populate Table First Time
    CREATE TABLE #bg_data
    (
        doc_ctrl_num VARCHAR(16),
        order_ctrl_num VARCHAR(16),
        customer_code VARCHAR(10),
        doc_date_int INT,
        doc_date VARCHAR(10),
        parent VARCHAR(10)
    );


    EXEC dbo.cvo_bg_get_document_data_sp;

    CREATE CLUSTERED INDEX idx_bg_data ON #bg_data (doc_ctrl_num);

    UPDATE ar
    SET ar.order_ctrl_num = b.order_ctrl_num,
        ar.customer_code = b.customer_code,
        ar.doc_date_int = b.doc_date_int,
        ar.doc_date = b.doc_date,
        ar.parent = b.parent
    -- SELECT * 
    FROM dbo.cvo_artrxage ar
        JOIN #bg_data b
            ON b.doc_ctrl_num = ar.doc_ctrl_num
    WHERE b.order_ctrl_num <> ar.order_ctrl_num
          OR b.customer_code <> ar.customer_code
          OR b.doc_date <> ar.doc_date
          OR b.doc_date_int <> ar.doc_date_int
          OR b.parent <> ar.parent;

    DELETE ar
    -- SELECT * 
    FROM cvo_artrxage ar
    WHERE NOT EXISTS
    (
    SELECT 1 FROM #bg_data AS bd WHERE bd.doc_ctrl_num = ar.doc_ctrl_num
    );

    INSERT dbo.cvo_artrxage
    SELECT doc_ctrl_num,
           order_ctrl_num,
           customer_code,
           doc_date_int,
           doc_date,
           parent
    FROM #bg_data b
    WHERE NOT EXISTS
    (
    SELECT 1 FROM dbo.cvo_artrxage a WHERE a.doc_ctrl_num = b.doc_ctrl_num
    );


    DROP TABLE #bg_data;

END;




GO
GRANT EXECUTE ON  [dbo].[cvo_artrxage_sync_sp] TO [public]
GO
