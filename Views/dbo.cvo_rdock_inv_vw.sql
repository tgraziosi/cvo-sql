SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_rdock_inv_vw]
AS
-- 03/30/2017 - create view and add release date
    SELECT  b.location ,
            b.bin_no ,
            b.part_no ,
            b.description ,
            b.qty ,
            b.date_tran,
			ia.field_26 release_date,
			i.type_code
    FROM    cvo_bin_inquiry_vw b
	JOIN inv_master_add ia ON ia.part_no = b.part_no
	JOIN dbo.inv_master AS i ON i.part_no = b.part_no
    WHERE   group_code IN ('RDOCK', 'CROSSDOCK') -- 12/2/2017 - FOR elm rECEIPT BIN PER km REQUEST
    UNION ALL
/* add qc qty's not yet released - 102114 - tag */
    SELECT  ' QC' AS location ,
            q.bin_no ,
            q.part_no ,
            i.description ,
            SUM(qc_qty - reject_qty) qty ,
            MIN(date_entered) date_entered,
			MIN(ia.field_26) release_date,
			i.type_code
    FROM    qc_results q
            INNER JOIN inv_master i ON i.part_no = q.part_no
			JOIN inv_master_add ia ON ia.part_no = i.part_no
    WHERE   q.status = 'n'
            AND q.tran_code = 'r'
    GROUP BY q.bin_no ,
            q.part_no ,
            i.description,
			i.type_code
			;

GO
GRANT SELECT ON  [dbo].[cvo_rdock_inv_vw] TO [public]
GO
