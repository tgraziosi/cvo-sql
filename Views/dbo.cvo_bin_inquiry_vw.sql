SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- select * from cvo_bin_inquiry_vw where location = '001'

CREATE VIEW [dbo].[cvo_bin_inquiry_vw]
AS
    SELECT  bm.usage_type_code ,
            bm.group_code ,
            b.location ,
            b.bin_no ,
            b.part_no ,
            i.upc_code ,
            i.description ,
            i.type_code ,
            b.lot_ser ,
            b.qty ,
            b.date_tran ,
            b.date_expires ,
            il.std_cost ,
            il.std_ovhd_dolrs ,
            il.std_util_dolrs ,
            ROUND(( ( il.std_cost + il.std_ovhd_dolrs + il.std_util_dolrs )
                    * b.qty ), 2) AS ext_cost ,
			CASE WHEN ISNULL(pb.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            ISNULL(pb.[primary], 'N') primary_bin ,
            bm.last_modified_date ,
            bm.modified_by
    FROM    lot_bin_stock b ( NOLOCK )
            INNER JOIN inv_master i ( NOLOCK ) ON b.part_no = i.part_no
            INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no
                                                 AND il.location = b.location
            LEFT OUTER JOIN tdc_bin_part_qty pb ON b.bin_no = pb.bin_no
                                                   AND pb.location = b.location
                                                   AND pb.part_no = b.part_no
            LEFT OUTER JOIN tdc_bin_master (NOLOCK) bm ON bm.bin_no = b.bin_no
                                                          AND bm.location = b.location
    WHERE   1 = 1
    UNION
    SELECT	DISTINCT
            m.usage_type_code ,
            m.group_code ,
            m.location ,
            m.bin_no ,
            s.part_no ,
            i.upc_code ,
            i.description ,
            i.type_code ,
            '' lot_ser ,
            0 qty ,
            GETDATE() date_tran ,
            GETDATE() date_expires ,
            il.std_cost ,
            il.std_ovhd_dolrs ,
            il.std_util_dolrs ,
            0 AS ext_cost ,
			CASE WHEN ISNULL(s.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            s.[primary] ,
            m.last_modified_date ,
            m.modified_by
    FROM    tdc_bin_part_qty s ( NOLOCK )
            INNER JOIN tdc_bin_master m ( NOLOCK ) ON s.location = m.location
                                                      AND s.bin_no = m.bin_no
            INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = s.part_no
            INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no
                                                 AND il.location = s.location
            LEFT JOIN lot_bin_stock l ( NOLOCK ) ON s.location = l.location
                                                    AND s.part_no = l.part_no
                                                    AND s.bin_no = l.bin_no
    WHERE   l.location IS NULL
            AND l.part_no IS NULL
            AND l.bin_no IS NULL;
    






GO
GRANT SELECT ON  [dbo].[cvo_bin_inquiry_vw] TO [public]
GO
