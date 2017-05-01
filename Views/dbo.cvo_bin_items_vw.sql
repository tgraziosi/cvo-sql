SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_bin_items_vw]
AS
-- select * from cvo_bin_items_vw where brand = 'jc'
SELECT
    biv.group_code,
    biv.location,
    iv.brand,
    iv.type,
    iv.part_no,
    biv.bin_no,
    biv.qty,
	iv.release_date,
    iv.pom_date,
	ISNULL(sbm.units_sold_6m,0) units_sold_6m,
    biv.Is_Assigned,
    biv.maximum_level
FROM
    dbo.CVO_items_vw AS iv
    LEFT OUTER JOIN dbo.cvo_bin_inquiry_vw AS biv
        ON iv.part_no = biv.part_no
	LEFT OUTER JOIN
    (SELECT location, part_no, SUM(qsales) units_sold_6m
	FROM cvo_sbm_details sbm WHERE yyyymmdd > DATEADD(m,-6,GETDATE()) 
	GROUP BY location, sbm.part_no
	) sbm ON sbm.part_no = biv.part_no AND sbm.location = biv.location
;


GO
GRANT SELECT ON  [dbo].[cvo_bin_items_vw] TO [public]
GO
