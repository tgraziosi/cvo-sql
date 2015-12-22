SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

create proc [dbo].[insert_sec_proc] 
	@desc varchar(30), 	@adm_ky varchar(10), 	@level int, 
	@ilevel int,		@rpt_flag int, 		@rpt_path varchar(100)
as

/*
Here is a script to use this procedure to create a security entry into the Backoffice system

declare 
	@desc varchar(30), 	@adm_ky varchar(10), 	@level int, 
	@ilevel int,		@rpt_flag int, 		@rpt_path varchar(100)


select 	
	@desc     = 'KIT UPDATE WIN', 		-- This is the task shown in the System Manager/Utilities/User Security
	@adm_ky   = 'KBN_UPDT', 		-- This is the code shown in Distribution/Application/Security (ie go into a Distribution window to get to here)
	@level    = 3, 				-- leave this alone: values are 1-3 and determine what kind of Backoffice was loaded
	@ilevel   = 40,				-- the security level for the task - no info on what this should be
	@rpt_flag = 0, 				-- leave these alone
	@rpt_path = NULL  			-- leave these alone

exec  insert_sec_proc  @desc , @adm_ky , @level , @ilevel ,@rpt_flag , @rpt_path 




*/



SET NOCOUNT ON

declare @form_id int,  @comp_id int, @curr_form_id int, @continue int

SELECT @comp_id = company_id from glco

if isnull(@comp_id, 0 ) <= 0 
begin
  select 'Unable to find company id from glco table.  No security created.'
  return
end

set @curr_form_id = 0

if exists (select 1 from smmenus_vw where app_id = 18000 and form_desc = @desc)
begin
  select 'record exists in smmenus_vw for this description.'
  select @curr_form_id = isnull ((select form_id from smmenus_vw where app_id = 18000 and form_desc = @desc), 0)
end


if @curr_form_id = 0 
begin
	-- determin base form_id number determined by app id and what has already been created (if any) in smmenus_vw	
	-- note we always use the midway point between first/last form_id allowed for the given level so that we dont accidently 
	-- use a form_id that might be used in a patch.
	select @continue = 0
	
	if @level = 1 
		select @form_id = 16850
	else
		if @level = 2
			select @form_id = 17850
		else
			select @form_id = 18500
	
	while (@continue = 0 AND ((@form_id between 16850 and 16950) OR (@form_id between 17850 and 17950) OR (@form_id between 18500 and 18997)))
	begin
		if @level = 1 
			select @form_id = isnull( ( select max(form_id) from smmenus_vw where app_id = 18000 AND form_id between 16850 and 16950 AND form_id > @form_id)  , @form_id ) 
		else
			if @level = 2
				select @form_id = isnull( ( select max(form_id) from smmenus_vw where app_id = 18000 AND form_id between 17850 and 17950 AND form_id > @form_id)  , @form_id)  
			else
				select @form_id = isnull( ( select max(form_id) from smmenus_vw where app_id = 18000 AND form_id between 18500 and 18997 AND form_id > @form_id)  , @form_id) 
					
		-- set up next form id number
		select @form_id = @form_id + 2
	
		if isnull(@form_id, 0 ) <= 0 
		begin
		  	continue
		end
	
		-- additional check to make sure the entry has not been used
		if ( exists (select 1 from smmenus_vw where app_id = 18000 AND form_id = @form_id)) 
		begin
			continue
		end
		
		if (exists (select 1 from smperm_vw where user_id = 1 AND app_id = 18000 AND form_id = @form_id))
		begin
			continue
		end
	
		if exists (select 1 from sec_module where prod_id = @level and form_id = @form_id)
		begin
			continue
		end

		select @continue = 1
	end
end 
else
begin


	if exists (select 1 from sec_module where kys = @adm_ky)
	begin
		if exists (select 1 from sec_module where kys = @adm_ky and form_id = @curr_form_id)
		begin
		  select 'a record exists in sec_module for this adm key anf form id.'
		  end 
		else
		begin
		  select 'a record exists in sec_module for this adm key but with a different form_id'
		  return
		end 
	end
	
	if (exists (select 1 from smperm_vw where user_id = 1 AND app_id = 18000 AND form_id = @curr_form_id))
	begin
	  select 'record exists in smperm_vw for user sa for app id = 18000 and new form id = '+ convert(varchar(20), @form_id) +'.  No security created.'
	  return
	end
	
	select @form_id = @curr_form_id
end
Begin Tran

	-- insert into smmenus_vw table (this is part of what you see in the Maintain Security window)
	if NOT exists (select 1 from smmenus_vw where app_id = 18000 and form_desc = @desc and form_id = @form_id)
	begin
		insert smmenus_vw (app_id, form_id, object_type, form_subid, form_desc)
		select 18000, @form_id, 1, 0,  @desc 

		if @@error <> 0 
		begin 
			select 'there was an error inserting into smmenus_vw!'
			goto error_label
		end
	end

	-- insert into sec_module (this is what you see in the Security module in Distribution)
	if NOT exists (select 1 from sec_module where kys = @adm_ky and form_id = @form_id)
	begin
		insert sec_module(kys, name, ilevel, prod_id, rpt_flag, rpt_path, rpt_type, form_id)
		select @adm_ky, @desc, @ilevel, @level, @rpt_flag, NULL, 0, @form_id
	
		if @@error <> 0 
		begin 
			select 'there was an error inserting into sec_module!'
			goto error_label
		end	
	end
	

	-- insert into smperm_vw (this is the security entry for the user 'sa' - full rights)
	if NOT exists (select 1 from CVO_Control..smuserperm where company_id = @comp_id and app_id = 18000 and form_id = @form_id)
	begin
		insert CVO_Control..smuserperm(user_id, company_id, app_id, form_id, object_type, read_perm, write, user_copy)
		select 1,   @comp_id, 18000, @form_id, 1, 0,4,0

		if @@error <> 0 
		begin 
			select 'there was an error inserting into smperm_vw!'
			goto error_label
		end
	end

commit tran
return

error_label:

Rollback tran
return

GO
GRANT EXECUTE ON  [dbo].[insert_sec_proc] TO [public]
GO
