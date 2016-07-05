SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_pom_status_by_style_sp]
AS
BEGIN

-- exec cvo_pom_status_by_style_sp

SELECT distinct pom.[collection]
		,pom.style
		,case when pom.style_pom_status = 'all' then 'All' else pom.color_desc end as color_desc
		,pom.tl
		,pom_date = CONVERT(varchar(10),pom.pom_date,101)
		,pom.asofdate
FROM dbo.cvo_pom_tl_status pom
LEFT OUTER JOIN
(SELECT DISTINCT i.category collection, ia.field_2 style, ISNULL(ia.field_32,'') attrib
FROM inv_master i 
JOIN dbo.inv_master_add ia ON ia.part_no = i.part_no 
WHERE ISNULL(i.void,'N') = 'N' ) a
ON a.collection = pom.collection AND a.style = pom.style
WHERE pom.Active = 1 
-- AND (tl IN (@tl))
AND a.attrib NOT IN ('retail')
AND pom.pom_date >= DATEADD(YEAR, -2, pom.asofdate)

END

GO
GRANT EXECUTE ON  [dbo].[cvo_pom_status_by_style_sp] TO [public]
GO
