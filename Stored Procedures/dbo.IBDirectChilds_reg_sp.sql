SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[IBDirectChilds_reg_sp]
AS
	BEGIN TRAN Refresh_IBDirectChilds

	CREATE TABLE #IBDirectChilds_tmp (
	child_outline_num varchar (120) NULL ,
	region_outline_num varchar(120) NOT NULL)
	
	TRUNCATE TABLE IBDirectChilds
	INSERT INTO IBDirectChilds (	
					parent_org_id,
					parent_outline_num, 
					child_org_id, 
					child_outline_num, 
					child_region_flag,
					region_id,
					region_outline_num
				)
	SELECT 	parent.organization_id parent_org_id,
		parent.outline_num parent_outline_num,
		childs.organization_id child_org_id,
		childs.outline_num child_outline_num,
       	childs.region_flag child_region_flag,
		'',
		''
 	FROM Organization childs
	INNER JOIN  Organization  as parent
		ON childs.outline_num  like parent.outline_num + '.%'
	WHERE parent.organization_id <> childs.organization_id 
	AND CHARINDEX ( '.',
			SUBSTRING(	childs.outline_num, 
					CHARINDEX (	parent.outline_num+'.',childs.outline_num  )+len(parent.outline_num+'.') , 
							len(childs.outline_num) 
				  )  
			) = 0  
	 AND CHARINDEX ( '.',childs.outline_num  )<> 0 

	INSERT #IBDirectChilds_tmp 
	(child_outline_num, region_outline_num) 
	SELECT child_outline_num, MAX(b.outline_num) region
	FROM IBDirectChilds a, Organization_all b
	WHERE a.child_outline_num LIKE b.outline_num + '.%'
	AND b.region_flag = 1 
	AND a.child_org_id <> b.organization_id
	GROUP BY child_outline_num

	UPDATE IBDirectChilds
	SET region_outline_num = b.region_outline_num, region_id = c.organization_id
	FROM IBDirectChilds a, #IBDirectChilds_tmp b, Organization_all c
	WHERE a.child_outline_num = b.child_outline_num
	AND b.region_outline_num = c.outline_num

	UPDATE IBDirectChilds
	SET region_id = b.organization_id, region_outline_num = b.outline_num
	FROM IBDirectChilds a, Organization_all b
	WHERE a.region_outline_num = ''
	AND a.region_id = ''
	AND b.outline_num = '1'	
	
	DROP TABLE #IBDirectChilds_tmp

	COMMIT TRAN IBDirectChilds

GO
GRANT EXECUTE ON  [dbo].[IBDirectChilds_reg_sp] TO [public]
GO
