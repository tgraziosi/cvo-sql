SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE procedure [dbo].[ep_eProcurement_init] as 
BEGIN	
	Declare @account_code varchar(32), @inactive_date int, 
		@active_date int, @str_inactive_date varchar(120), @str_active_date varchar(20),
		@plinv_key int, @segment_guid varchar(50), @type_guid varchar(50)

	--Clean up all initialize tables
	delete from epapvend
	delete from epinvdtl
	delete from epinvhdr

	--Initialize epapvend table start
	--insert values from apvend view,
	--default the guid using the NEWID() function,
	--default the modified date to the current system date,
	--convert the status 5 = active, 6 = inactive to 1 and 0 respectively
	insert epapvend 
	select NEWID(), apvend.vendor_code, GETDATE(),
	status = CASE apvend.status_type
		WHEN 5 THEN 1
		WHEN 6 THEN 0
		ELSE 0
	            END
	from apvend
	--Initialize epapvend table end

	--Initialize epcoa table start
	--call ep_eProcurement_init store procedure to initialize epcoa table
	exec ep_coa_init
	--Initialize epcoa table End
END

GO
GRANT EXECUTE ON  [dbo].[ep_eProcurement_init] TO [public]
GO
