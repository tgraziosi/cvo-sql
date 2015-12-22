SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[inv_fields] AS 
SELECT part_no, field_1  field FROM inv_master_add (NOLOCK) WHERE field_1  IS NOT NULL
UNION 
SELECT part_no, field_2  field FROM inv_master_add (NOLOCK) WHERE field_2  IS NOT NULL
UNION 
SELECT part_no, field_3  field FROM inv_master_add (NOLOCK) WHERE field_3  IS NOT NULL
UNION 
SELECT part_no, field_4  field FROM inv_master_add (NOLOCK) WHERE field_4  IS NOT NULL
UNION 
SELECT part_no, field_5  field FROM inv_master_add (NOLOCK) WHERE field_5  IS NOT NULL
UNION 
SELECT part_no, field_6  field FROM inv_master_add (NOLOCK) WHERE field_6  IS NOT NULL
UNION 
SELECT part_no, field_7  field FROM inv_master_add (NOLOCK) WHERE field_7  IS NOT NULL
UNION 
SELECT part_no, field_8  field FROM inv_master_add (NOLOCK) WHERE field_8  IS NOT NULL
UNION 
SELECT part_no, field_9  field FROM inv_master_add (NOLOCK) WHERE field_9  IS NOT NULL
UNION 
SELECT part_no, field_10 field FROM inv_master_add (NOLOCK) WHERE field_10 IS NOT NULL
UNION 
SELECT part_no, field_10 field FROM inv_master_add (NOLOCK) WHERE field_11 IS NOT NULL
UNION 
SELECT part_no, field_10 field FROM inv_master_add (NOLOCK) WHERE field_12 IS NOT NULL
UNION 
SELECT part_no, field_10 field FROM inv_master_add (NOLOCK) WHERE field_13 IS NOT NULL

GO
GRANT REFERENCES ON  [dbo].[inv_fields] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_fields] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_fields] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_fields] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_fields] TO [public]
GO
