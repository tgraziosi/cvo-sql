SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_cc_sp]
AS
BEGIN

    SELECT b.group_code,
           CASE
               WHEN count_qty IS NULL THEN
                   'PENDING COUNT'
               ELSE
                   'COMPLETED COUNT'
           END AS count_status,
           COUNT(tpcc.part_no) num_counts
    FROM dbo.tdc_phy_cyc_count AS tpcc
        JOIN tdc_bin_master b
            ON b.bin_no = tpcc.bin_no
               AND b.location = tpcc.location
    GROUP BY CASE
                 WHEN count_qty IS NULL THEN
                     'PENDING COUNT'
                 ELSE
                     'COMPLETED COUNT'
             END,
             b.group_code;

END;

GRANT EXECUTE ON cvo_dc_dash_cc_sp TO public
GO
