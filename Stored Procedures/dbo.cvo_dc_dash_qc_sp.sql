SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[cvo_dc_dash_qc_sp] @asofdate DATETIME =  null
AS
BEGIN

IF @asofdate IS NULL SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)

SELECT trans,
       qc.type_code,
       COUNT(tran_no) num_tran,
       SUM(qc.quantity) sum_qty,
       COUNT(DISTINCT part_no) num_skus,
       qc.rel_date
FROM
(
    SELECT act.trans,
           act.tran_no,
           ISNULL(a.address_name, act.vendor) vendor_name,
           act.part_no,
           act.location,
           act.bin_no,
           act.quantity,
           act.today,
           CASE
               WHEN trans = 'qcrelease' THEN
                   act.tran_date
               ELSE
                   act.today
           END tran_date,
           cu.fname + ' ' + lname user_name,
           CASE WHEN ia.field_26 >= dateadd(dd, DATEDIFF(dd, 0,GETDATE()),0) THEN 'NEW' ELSE '' end rel_date,
           i.type_code
    FROM
    (
        SELECT trans,
               tdc.tran_no,
               qr.vendor_key vendor,
               tdc.part_no,
               tdc.location,
               tdc.bin_no,
               CAST(tdc.quantity AS INTEGER) quantity,
               GETDATE() today,
               tdc.tran_date,
               REPLACE(tdc.UserID, 'cvoptical\', '') userid
        FROM tdc_log tdc (NOLOCK)
            JOIN dbo.qc_results AS qr
                ON qr.tran_no = tdc.tran_no
        WHERE trans = 'qcrelease'
        UNION ALL
        SELECT 'QC' trans,
               qc_no,
               qr.vendor_key,
               qr.part_no,
               location,
               qr.bin_no,
               qr.qc_qty,
               qr.date_entered,
               GETDATE() tran_date,
               qr.who_entered
        FROM dbo.qc_results AS qr (NOLOCK)
        WHERE qr.status <> 'S'
              AND qr.qc_qty <> 0
    ) act
        JOIN inv_master_add ia
            ON ia.part_no = act.part_no
        JOIN inv_master i
            ON i.part_no = act.part_no
        LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = act.userid
        LEFT OUTER JOIN dbo.apmaster AS a
            ON a.vendor_code = act.vendor
) qc
WHERE qc.tran_date >= @asofdate
GROUP BY qc.trans,
         qc.type_code,
         qc.rel_date;

END


GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_qc_sp] TO [public]
GO
