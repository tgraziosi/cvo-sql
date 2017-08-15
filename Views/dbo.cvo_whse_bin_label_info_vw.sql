SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_whse_bin_label_info_vw]
AS 

SELECT
    wpv.group_code,
    wpv.location,
    Brand,
    type_code,
    CASE
        WHEN ISNULL(part_no, '') = '' THEN
            ''
        ELSE
            'SKU: ' + UPPER(part_no)
    END AS part_no,
    CASE WHEN ISNULL(bin_no,'') = '' THEN
			''
	ELSE UPPER(bin_no)
	END AS bin_no,
    wpv.upc_code,
    CASE
        WHEN wpv.rel_date IS NULL THEN
            ''
        ELSE
            'REL: ' + RIGHT(CONVERT(VARCHAR(8), rel_date, 5), 5)
    END release_date,
    CASE
        WHEN wpv.pom_date IS NOT NULL THEN
            'POM: ' + RIGHT(CONVERT(VARCHAR(8), pom_date, 5), 5)
        ELSE
            ''
    END pom_date,
    wpv.Is_Assigned,
	part_no sku
FROM dbo.cvo_whse_planning_vw AS wpv
WHERE 1=1
--    AND (wpv.bin_no LIKE 'f08%')
--    AND location = '001'
--    AND wpv.group_code = 'PICKAREA'
--	--AND wpv.Is_Assigned IN ('empty')

--	AND type_code IN ('frame','sun')
--	AND UPPER(bin_no) IN ('f04f-02-23','f05f-03-09') 

--	AND wpv.rel_date = '8/29/2017'
--	AND brand IN('DH','JMC')
--	AND wpv.Is_Assigned = 'YES'
;



GO
GRANT SELECT ON  [dbo].[cvo_whse_bin_label_info_vw] TO [public]
GO
