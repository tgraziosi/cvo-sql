SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_cc_sp]
AS
BEGIN

    DECLARE @asofdate DATETIME
    SELECT @asofdate = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0)

    ; WITH cc AS 
    (SELECT tpcc.team_id,
            userid,
            b.group_code,
           
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
    GROUP BY tpcc.team_id,
             USERID,
             CASE
                 WHEN count_qty IS NULL THEN
                     'PENDING COUNT'
                 ELSE
                     'COMPLETED COUNT'
             END,
             b.group_code

    UNION ALL
    SELECT team_id,
           userid,
           b.group_code,
           'POSTED COUNT' COUNT_STATUS,
           COUNT(TPCC.part_no) NUM_COUNTS
           FROM tdc_cyc_count_log tpcc
                   JOIN tdc_bin_master b
            ON b.bin_no = tpcc.bin_no
               AND b.location = tpcc.location
           WHERE cycle_date > @asofdate
           GROUP BY tpcc.team_id,
                    tpcc.userid,
                    b.group_code
        ) 
        SELECT cc.team_id,
               ISNULL(ccu.fname + ' ' + ccu.lname, REPLACE(cc.UserID, 'cvoptical\', '')) username,
               cc.group_code,
               cc.count_status,
               cc.num_counts
               FROM cc
        JOIN dbo.cvo_cmi_users AS ccu ON ccu.user_login = cc.userid
END;

GRANT EXECUTE ON cvo_dc_dash_cc_sp TO public

GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_cc_sp] TO [public]
GO
