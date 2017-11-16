SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_sgl_putaway_log_sp]
    (
        @sdate DATETIME = NULL ,
        @edate DATETIME = NULL
    )
AS

    -- exec cvo_sgl_putaway_log_sp 

    SET NOCOUNT ON;
    BEGIN


        IF @sdate IS NULL
            SELECT @sdate = DATEADD(WEEK, -1, GETDATE());
        IF @edate IS NULL
            SELECT @edate = GETDATE();

        SELECT   'Putaways' activity,
				 DATEADD(DAY, DATEDIFF(DAY, 0, tv.tran_date), 0) tran_date ,
                 tv.userid ,
                 COUNT(DISTINCT part_no) num_skus ,
                 SUM(CAST(qty AS DECIMAL(20, 8))) qty
        FROM     dbo.cvo_tdcdet_vw AS tv

        WHERE    tv.to_bin_group = 'pickarea'
                 AND tv.tran_date
                 BETWEEN @sdate AND @edate
                 AND bin_no = 'rr putaway'
                 AND tv.location = '001'
                 AND tv.to_bin_no NOT LIKE 'h08%'
                 AND 10 > CAST(qty AS DECIMAL(20, 8))
        GROUP BY DATEADD(DAY, DATEDIFF(DAY, 0, tv.tran_date), 0) ,
                 tv.userid

        UNION ALL


        SELECT   'Scans' activity,
				 DATEADD(DAY, DATEDIFF(DAY, 0, bc.bcode_date), 0) tran_date ,
                 bcode_user ,
                 COUNT(DISTINCT sku) num_skus ,
                 SUM(isPrinted) qty
        FROM     dbo.cvo_bcode_log AS bc
        WHERE    bc.bcode_date
                 BETWEEN @sdate AND @edate
                 AND isVoided = 0
                 AND bc.bin LIKE 'f0%'
        GROUP BY DATEADD(DAY, DATEDIFF(DAY, 0, bc.bcode_date), 0) ,
                 bc.bcode_user;


    END;


    GRANT EXECUTE
        ON cvo_sgl_putaway_log_sp
        TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_sgl_putaway_log_sp] TO [public]
GO
