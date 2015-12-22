SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE	[dbo].[ep_get_coa_seg_guids] @sCOASegGuid varchar(100) OUTPUT,
	 @sRefSegGuid varchar(100) OUTPUT, @sCompanySegGuid varchar(100) OUTPUT AS
Begin
	select @sCOASegGuid = min(seg_guid)
	from CVO_Control..epsegmentguid
	where seg_name = 'coa segment guid'

	select @sRefSegGuid = min(seg_guid)
	from CVO_Control..epsegmentguid
	where seg_name = 'reference segment guid'

	select @sCompanySegGuid = min(seg_guid)
	from CVO_Control..epsegmentguid
	where seg_name = 'company segment guid'

	select 	coa_seg_guid = @sCOASegGuid,
		ref_seg_guid = @sRefSegGuid,
		company_seg_guid = @sCompanySegGuid
END 

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ep_get_coa_seg_guids] TO [public]
GO
