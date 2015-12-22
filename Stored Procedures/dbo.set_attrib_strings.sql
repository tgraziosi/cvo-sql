SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[set_attrib_strings]
as

declare @attrib1 varchar(255), @attrib2 varchar(255)

select @attrib1 = value_str from config where flag = 'INV_ATTRIB1'
select @attrib2 = value_str from config where flag = 'INV_ATTRIB2'
 
-- Attribute 1 select * from CVO_Control..smcom  select * from smmenus_vw
	update CVO_Control..Strings set StringText = 'Maintain ' + @attrib1
	 where StringId = (select Caption from CVO_Control..DesktopLayout 
			    where ClassId = (select ClassID from CVO_Control..smcom 
			 		      where App_ID = 18000 and Form_ID = 16996))

	update smmenus_vw set form_desc = ('Maintain ' + @attrib1)
	where form_id = 16996

-- Attribute 2
	update CVO_Control..Strings set StringText = 'Maintain ' + @attrib2
	 where StringId = (select Caption from CVO_Control..DesktopLayout 
			    where ClassId = (select ClassID from CVO_Control..smcom 
			 		      where App_ID = 18000 and Form_ID = 16997))

	update smmenus_vw set form_desc = ( 'Maintain ' + @attrib2  )
	where form_id = 16997

-- Attribute 1 Range
	update CVO_Control..Strings set StringText = 'Maintain ' + @attrib1 + ' Ranges'
	 where StringId = (select Caption from CVO_Control..DesktopLayout 
			    where ClassId = (select ClassID from CVO_Control..smcom 
			 		      where App_ID = 18000 and Form_ID = 16994))

	update smmenus_vw set form_desc = ( 'Maintain ' + @attrib1 + ' Ranges')
	where form_id = 16994

-- Attribute 2 Range
	update CVO_Control..Strings set StringText = 'Maintain ' + @attrib2 + ' Ranges'
	 where StringId = (select Caption from CVO_Control..DesktopLayout 
			    where ClassId = (select ClassID from CVO_Control..smcom 
			 		      where App_ID = 18000 and Form_ID = 16995))
 

	update smmenus_vw set form_desc = ( 'Maintain ' + @attrib2 + ' Ranges')
	where form_id = 16995

-- Category 1
        select @attrib1 = isnull((select min(field_text) from inv_master_add_fields
          where field_name = 'category_1_t'),'')

        if @attrib1 != ''
        begin
	  update s set StringText = 'Maintain ' + @attrib1
          from CVO_Control..Strings s, CVO_Control..DesktopLayout d
          where s.StringId = d.Caption and d.ClassId in
            (select ClassID from CVO_Control..smcom where App_ID = 18000 and Form_ID = 16722)

	  update smmenus_vw set form_desc = 'Advanced Inv Search: ' + ('Maintain ' + @attrib1)
  	  where form_id = 16722
	end

-- Category 2
        select @attrib1 = isnull((select min(field_text) from inv_master_add_fields
          where field_name = 'category_2_t'),'')

        if @attrib1 != ''
        begin
	  update s set StringText = 'Maintain ' + @attrib1
          from CVO_Control..Strings s, CVO_Control..DesktopLayout d
          where s.StringId = d.Caption and d.ClassId in
            (select ClassID from CVO_Control..smcom where App_ID = 18000 and Form_ID = 16724)

	  update smmenus_vw set form_desc = 'Advanced Inv Search: ' +  ('Maintain ' + @attrib1)
  	  where form_id = 16724
	end
   
-- Category 3
        select @attrib1 = isnull((select min(field_text) from inv_master_add_fields
          where field_name = 'category_3_t'),'')

        if @attrib1 != ''
        begin
	  update s set StringText = 'Maintain ' + @attrib1
          from CVO_Control..Strings s, CVO_Control..DesktopLayout d
          where s.StringId = d.Caption and d.ClassId in
            (select ClassID from CVO_Control..smcom where App_ID = 18000 and Form_ID = 16726)

	  update smmenus_vw set form_desc = 'Advanced Inv Search: ' +  ('Maintain ' + @attrib1)
  	  where form_id = 16726
	end

-- Category 4
        select @attrib1 = isnull((select min(field_text) from inv_master_add_fields
          where field_name = 'category_4_t'),'')

        if @attrib1 != ''
        begin
	  update s set StringText = 'Maintain ' + @attrib1
          from CVO_Control..Strings s, CVO_Control..DesktopLayout d
          where s.StringId = d.Caption and d.ClassId in
            (select ClassID from CVO_Control..smcom where App_ID = 18000 and Form_ID = 16728)

	  update smmenus_vw set form_desc = 'Advanced Inv Search: ' +  ('Maintain ' + @attrib1)
  	  where form_id = 16728
	end

-- Category 5
        select @attrib1 = isnull((select min(field_text) from inv_master_add_fields
          where field_name = 'category_5_t'),'')

        if @attrib1 != ''
        begin
	  update s set StringText = 'Maintain ' + @attrib1
          from CVO_Control..Strings s, CVO_Control..DesktopLayout d
          where s.StringId = d.Caption and d.ClassId in
            (select ClassID from CVO_Control..smcom where App_ID = 18000 and Form_ID = 16730)

	  update smmenus_vw set form_desc = 'Advanced Inv Search: ' +  ('Maintain ' + @attrib1)
  	  where form_id = 16730
	end
GO
GRANT EXECUTE ON  [dbo].[set_attrib_strings] TO [public]
GO
