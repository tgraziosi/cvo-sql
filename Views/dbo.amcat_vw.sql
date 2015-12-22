SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[amcat_vw] 

AS 

SELECT c.timestamp timestamp,
 c.category_code,
 c.category_description,
 p.posting_code,
 p.posting_code_description 
FROM amcat c,
 ampsthdr p 
WHERE c.posting_code = p.posting_code 


GO
GRANT REFERENCES ON  [dbo].[amcat_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[amcat_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[amcat_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[amcat_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[amcat_vw] TO [public]
GO
