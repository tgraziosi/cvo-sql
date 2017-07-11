SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from cvo_whse_planning_vw where isnull(location,'001') = '001' and  isnull(rel_date,'8/29/2017') = '8/29/2017'
-- select * From cvo_whse_planning_vw where location = '001' and type_code in ('frame','sun') and bin_no like 'f01%'

CREATE VIEW [dbo].[cvo_whse_planning_vw]
AS
    SELECT  bm.usage_type_code ,
            bm.group_code ,
            b.location ,
            b.bin_no ,
			i.category Brand,
			ia.field_2 model,
            i.part_no ,
            i.upc_code ,
            i.description ,
            i.type_code ,
            b.lot_ser ,
            b.qty ,
			CASE WHEN ISNULL(pb.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            ISNULL(pb.[primary], 'N') primary_bin ,
			bm.maximum_level, -- 1/18/2017 - per KM request
			bm.status,
			ia.field_26 rel_date,
			ia.field_28 pom_date
    FROM    inv_master i ( NOLOCK ) 
			INNER JOIN inv_master_add ia (nolock) ON ia.part_no = i.part_no
		    INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no AND location = '001'
			LEFT OUTER JOIN lot_bin_stock b ( NOLOCK ) ON b.part_no = i.part_no AND b.location = il.location
			LEFT OUTER JOIN tdc_bin_part_qty pb ON pb.location = il.location
                                                   AND pb.part_no = i.part_no
												   AND pb.bin_no = b.bin_no
            
            LEFT OUTER JOIN tdc_bin_master (NOLOCK) bm ON bm.bin_no = b.bin_no
                                                          AND bm.location = b.location
    WHERE   1 = 1
		AND i.void = 'n'
    UNION -- assigned bins with no inventory
    SELECT	DISTINCT
            m.usage_type_code ,
            m.group_code ,
            m.location ,
            m.bin_no ,
			i.category brand,
			ia.field_2 model,
            s.part_no ,
            i.upc_code ,
            i.description ,
            i.type_code ,
            '' lot_ser ,
            0 qty ,
			CASE WHEN ISNULL(s.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            s.[primary] ,
			m.maximum_level,
			m.status,
			ia.field_26 rel_date,
			ia.field_28 pom_date
    FROM    tdc_bin_part_qty s ( NOLOCK )
            INNER JOIN tdc_bin_master m ( NOLOCK ) ON s.location = m.location
                                                      AND s.bin_no = m.bin_no
            INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = s.part_no
			INNER JOIN inv_master_add ia (nolock) ON ia.part_no = i.part_no
            INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no
                                                 AND il.location = s.location
            LEFT JOIN lot_bin_stock l ( NOLOCK ) ON s.location = l.location
                                                    AND s.part_no = l.part_no
                                                    AND s.bin_no = l.bin_no
    WHERE   l.location IS NULL
            AND l.part_no IS NULL
            AND l.bin_no IS NULL
	UNION -- empty bins not assigned to parts
    SELECT	DISTINCT
            m.usage_type_code ,
            m.group_code ,
            m.location ,
            m.bin_no ,
			'' brand,
			'' model,
            '' part_no ,
            '' upc_code ,
            '' description ,
            '' type_code ,
            '' lot_ser ,
            0 qty ,
			'Empty' AS Is_Assigned,
            'N' [primary] ,
			m.maximum_level,
			m.status,
			NULL AS rel_date,
			NULL AS pom_date
    FROM    tdc_bin_master m (NOLOCK)
			WHERE 
			NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty s ( NOLOCK ) WHERE s.location = m.location AND s.bin_no = m.bin_no)
			AND NOT EXISTS (SELECT 1 FROM lot_bin_stock l (NOLOCK ) WHERE l.location = m.location AND l.bin_no = m.bin_no)

			
			;
    










GO
