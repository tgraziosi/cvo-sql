SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[cc_org_id_zoom_sp] 	@org_id varchar(30) = '',
															@direction tinyint = 0

AS

		SET rowcount 50
		
		BEGIN
			IF @direction = 0
				SELECT DISTINCT org_id 'Organization ID', organization_name 'Organization Name' 
				FROM iborganization_zoom_vw
				WHERE org_id >= @org_id
				ORDER BY org_id
			IF @direction = 1
				SELECT DISTINCT org_id 'Organization ID', organization_name 'Organization Name' 
				FROM iborganization_zoom_vw
				WHERE org_id <= @org_id
				ORDER BY org_id DESC
			IF @direction = 2
				SELECT DISTINCT org_id 'Organization ID', organization_name 'Organization Name' 
				FROM iborganization_zoom_vw
				WHERE org_id >= @org_id
				ORDER BY org_id ASC
		END
		

SET rowcount 0

GO
GRANT EXECUTE ON  [dbo].[cc_org_id_zoom_sp] TO [public]
GO
