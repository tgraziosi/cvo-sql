SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[inv_scale_vw] as
  SELECT 	inv_attrib1_scale.attrib1_scale_name 	as scale_code,
		inv_attrib1_scale.sequence 			as sequence,   
         	inv_attrib1.attrib1 				as scale,   
         	inv_attrib1.name 					as scale_name,   
         	inv_attrib1.description  			as description
    FROM 	inv_attrib1_scale,   
         	inv_attrib1  
   WHERE ( inv_attrib1_scale.attrib1 = inv_attrib1.attrib1 ) 
GO
GRANT REFERENCES ON  [dbo].[inv_scale_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_scale_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_scale_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_scale_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_scale_vw] TO [public]
GO
