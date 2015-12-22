SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE Proc [dbo].[ep_coa_post_process] As
BEGIN

	--Move the deleted records to a history table
    insert into epcoa_history
     	select * from epcoa where deleted_dt is not null

	delete epcoa
	where deleted_dt is not null

	--Reset all epcoa send_inactive_flg
	update epcoa
	set send_inactive_flg = 0
	from ep_temp_glchart g 
	where 	g.account_code = epcoa.account_code and
		epcoa.send_inactive_flg = 1 

	update epcoa
	set send_inactive_flg = 1
	from ep_temp_glchart g 
	where 	g.account_code = epcoa.account_code and
		(epcoa.inactive_dt is not null and
		epcoa.inactive_dt > getdate()) and
		( epcoa.active_dt < getdate() or
		  epcoa.active_dt is null )

END





GO
GRANT EXECUTE ON  [dbo].[ep_coa_post_process] TO [public]
GO
