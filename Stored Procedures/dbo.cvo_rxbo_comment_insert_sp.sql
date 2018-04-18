SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		tgraziosi
-- Create date: 4/9/2018
-- Description:	Insert into rx bo Comments 
-- exec cvo_rxbo_comment_insert_sp '9999991','0','THIS IS A TEST FROM ELIZABETH'
-- =============================================
CREATE PROCEDURE [dbo].[cvo_rxbo_comment_insert_sp]
    @order_no INT,
    @ext INT,
	@Comment VARCHAR(80) = NULL -- pass the username here
AS
BEGIN

    SET NOCOUNT ON;

	-- DROP TABLE dbo.cvo_rxbo_comment_tbl

	IF (OBJECT_ID('dbo.cvo_rxbo_comment_tbl') IS NULL)
    BEGIN
	CREATE TABLE dbo.cvo_rxbo_comment_tbl
	(order_no INT,
	 ext INT,
	 call_date DATETIME,
	 call_user VARCHAR(80)
	)
    ;
	CREATE CLUSTERED INDEX pk_cvo_rxbo_comment ON dbo.cvo_rxbo_comment_tbl (order_no, ext)
	;
	END;

    IF EXISTS
    (
    SELECT order_no
    FROM dbo.cvo_rxbo_comment_tbl AS rct
    WHERE order_no = @order_no
          AND ext = @ext
    )
        DELETE FROM cvo_rxbo_comment_tbl
        WHERE order_no = @order_no
              AND ext = @ext;

    INSERT INTO cvo_rxbo_comment_tbl
    VALUES
    (@order_no, @ext, GETDATE(), @Comment);

END;





GO
GRANT EXECUTE ON  [dbo].[cvo_rxbo_comment_insert_sp] TO [public]
GO
