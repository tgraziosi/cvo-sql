SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from cvo_whse_planning_vw where isnull(location,'001') = '001' and  isnull(rel_date,'8/29/2017') = '8/29/2017'
-- select * From cvo_whse_planning_vw where location = '001' and type_code in ('frame','sun') and bin_no like 'f01%'

CREATE VIEW [dbo].[cvo_whse_planning_vw]
AS
    SELECT  
			i.part_no ,
            b.bin_no ,
			i.category Brand,
			ia.field_2 model,
            i.description ,
            i.type_code ,
            b.qty ,
			CASE WHEN ISNULL(pb.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            ISNULL(pb.[primary], 'N') primary_bin ,
			bm.status,
			bm.maximum_level, -- 1/18/2017 - per KM request
			tbr.replenish_min_lvl,
			tbr.replenish_max_lvl,
			tbr.replenish_qty,
			ia.field_26 rel_date,
			ia.field_28 pom_date,
			bm.usage_type_code ,
            bm.group_code ,
            b.location ,
			i.upc_code,
			aisle = LEFT(b.bin_no,3),
			section = SUBSTRING(b.bin_no,4,1),
			block = SUBSTRING(b.bin_no,6,2),
			slot = RIGHT(b.bin_no,2)
    FROM    inv_master i ( NOLOCK ) 
			INNER JOIN inv_master_add ia (nolock) ON ia.part_no = i.part_no
		    INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no AND location = '001'
			LEFT OUTER JOIN lot_bin_stock b ( NOLOCK ) ON b.part_no = i.part_no AND b.location = il.location
			LEFT OUTER JOIN tdc_bin_master (NOLOCK) bm ON bm.bin_no = b.bin_no
                                                          AND bm.location = b.location
			LEFT OUTER JOIN tdc_bin_part_qty pb ON pb.location = il.location
                                                   AND pb.part_no = i.part_no
												   AND pb.bin_no = b.bin_no
			LEFT OUTER JOIN dbo.tdc_bin_replenishment AS tbr ON tbr.location = il.location
													AND tbr.part_no = i.part_no
													AND tbr.bin_no = b.bin_no
            

    WHERE   1 = 1
		AND i.void = 'n'
    UNION -- assigned bins with no inventory
    SELECT	DISTINCT
			i.part_no ,
            bm.bin_no ,
			i.category Brand,
			ia.field_2 model,
            i.description ,
            i.type_code ,
            ISNULL(l.qty,0) qty ,
			CASE WHEN ISNULL(s.bin_no,'N') = 'N' THEN 'No' ELSE 'Yes' END AS Is_Assigned,
            ISNULL(s.[primary], 'N') primary_bin ,
			bm.status,
			bm.maximum_level, -- 1/18/2017 - per KM request
			tbr.replenish_min_lvl,
			tbr.replenish_max_lvl,
			tbr.replenish_qty,
			ia.field_26 rel_date,
			ia.field_28 pom_date,
			bm.usage_type_code ,
            bm.group_code ,
            bm.location ,
			i.upc_code,	
			aisle = LEFT(bm.bin_no,3),
			section = SUBSTRING(bm.bin_no,4,1),
			block = SUBSTRING(bm.bin_no,6,2),
			slot = RIGHT(bm.bin_no,2)


    FROM    tdc_bin_part_qty s ( NOLOCK )
            INNER JOIN tdc_bin_master bm ( NOLOCK ) ON s.location = bm.location
                                                      AND s.bin_no = bm.bin_no
            INNER JOIN inv_master i ( NOLOCK ) ON i.part_no = s.part_no
			INNER JOIN inv_master_add ia (nolock) ON ia.part_no = i.part_no
            INNER JOIN inv_list il ( NOLOCK ) ON il.part_no = i.part_no
                                                 AND il.location = s.location
            LEFT JOIN lot_bin_stock l ( NOLOCK ) ON s.location = l.location
                                                    AND s.part_no = l.part_no
                                                    AND s.bin_no = l.bin_no
			LEFT OUTER JOIN dbo.tdc_bin_replenishment AS tbr ON tbr.location = il.location
													AND tbr.part_no = i.part_no
													AND tbr.bin_no = l.bin_no
    WHERE   l.location IS NULL
            AND l.part_no IS NULL
            AND l.bin_no IS NULL
	UNION -- empty bins not assigned to parts
    SELECT	DISTINCT

			'' part_no ,
            bm.bin_no ,
			'' Brand,
			'' model,
            bm.description ,
            '' type_code ,
             0 qty ,
			'Empty' AS  Is_Assigned,
            'N' primary_bin ,
			bm.status,
			bm.maximum_level, -- 1/18/2017 - per KM request
			0 replenish_min_lvl,
			0 replenish_max_lvl,
			0 replenish_qty,
			NULL rel_date,
			NULL pom_date,
			bm.usage_type_code ,
            bm.group_code ,
            bm.location ,
			'' upc_code,
			aisle = LEFT(bm.bin_no,3),
			section = SUBSTRING(bm.bin_no,4,1),
			block = SUBSTRING(bm.bin_no,6,2),
			slot = RIGHT(bm.bin_no,2)

    FROM    tdc_bin_master bm (NOLOCK)
			WHERE 
			NOT EXISTS (SELECT 1 FROM tdc_bin_part_qty s ( NOLOCK ) WHERE s.location = bm.location AND s.bin_no = bm.bin_no)
			AND NOT EXISTS (SELECT 1 FROM lot_bin_stock l (NOLOCK ) WHERE l.location = bm.location AND l.bin_no = bm.bin_no)

			
			;
    















GO
