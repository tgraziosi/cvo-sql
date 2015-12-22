SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[inv_scale_vw2] as
  SELECT 	inv_attrib2_scale.attrib2_scale_name 	as scale_code,
		inv_attrib2_scale.sequence 			as sequence,   
         	inv_attrib2.attrib2 				as scale,   
         	inv_attrib2.name 					as scale_name,   
         	inv_attrib2.description  			as description
    FROM 	inv_attrib2_scale,   
         	inv_attrib2  
   WHERE ( inv_attrib2_scale.attrib2 = inv_attrib2.attrib2 ) 
GO
GRANT REFERENCES ON  [dbo].[inv_scale_vw2] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_scale_vw2] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_scale_vw2] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_scale_vw2] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_scale_vw2] TO [public]
GO
