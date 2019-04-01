SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_putaway_sp] @asofdate DATETIME = NULL
AS
BEGIN
    -- EXEC dbo.cvo_dc_dash_putaway_sp '03/28/2019'

    SET NOCOUNT ON;
    IF @asofdate IS NULL
        SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    -- get the outstanding putaways from tdc_put_queue
    SELECT 'PENDING' who_processed,
           ISNULL(b.group_code, 'UnDirected') Group_code,
           '' username,
           COUNT(put.tran_id) num_puts,
           @asofdate tran_date
    FROM tdc_put_queue put (NOLOCK)
        LEFT OUTER JOIN tdc_bin_master b (NOLOCK)
            ON b.bin_no = put.next_op
               AND b.location = put.location
    WHERE put.trans = 'poptwy'
    GROUP BY ISNULL(b.group_code, 'UnDirected')

    -- get the completed putaways since the as of date
    UNION ALL
    
    SELECT REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
           b.group_code,
           ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')) Username,
           COUNT(tran_date) num_trans,
           DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0) tran_date
    FROM tdc_log (NOLOCK) wms
        JOIN tdc_bin_master b
            ON b.bin_no = wms.bin_no
               AND b.location = wms.location
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(wms.UserID, 'cvoptical\', '')
    WHERE tran_date > @asofdate
          AND trans IN ( 'POPTWY' )
    GROUP BY REPLACE(wms.UserID, 'cvoptical\', ''),
             ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')),
             DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0),
             b.group_code;
END;


GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_putaway_sp] TO [public]
GO
